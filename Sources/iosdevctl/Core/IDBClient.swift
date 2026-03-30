import Foundation
import GRPC
import NIO

// MARK: - IDBError

enum IDBError: Error {
    case companionUnavailable
    case grpcCallFailed(String)
    case unknownButton(String)
}

// MARK: - IDBClient

/// Manages an `idb_companion` process and sends HID events via gRPC.
final class IDBClient {

    private static let companionPath = "/opt/homebrew/bin/idb_companion"
    private static let grpcPort = 10882
    private static let host = "localhost"

    private let udid: String
    private let group: EventLoopGroup
    private let channel: GRPCChannel
    private let client: Idb_CompanionServiceClient

    // MARK: Init

    /// Creates an IDBClient, starting idb_companion if needed.
    init(udid: String) throws {
        self.udid = udid
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        // Ensure companion is running for this UDID.
        try IDBClient.ensureCompanion(udid: udid)

        let channel = try GRPCChannelPool.with(
            target: .host(IDBClient.host, port: IDBClient.grpcPort),
            transportSecurity: .plaintext,
            eventLoopGroup: group
        )
        self.channel = channel
        self.client = Idb_CompanionServiceClient(channel: channel)
    }

    deinit {
        try? channel.close().wait()
        try? group.syncShutdownGracefully()
    }

    // MARK: - Companion lifecycle

    private static func isCompanionRunning() -> Bool {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(grpcPort).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        var tv = timeval(tv_sec: 0, tv_usec: 300_000)
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }

    private static func runningCompanionUDID() -> String? {
        let result = runCommand(["pgrep", "-fl", "idb_companion"])
        guard result.succeeded else { return nil }
        let line = result.stdout
        guard line.contains("--udid") else { return nil }
        let parts = line.components(separatedBy: " ")
        for (i, part) in parts.enumerated() {
            if part == "--udid", i + 1 < parts.count {
                return parts[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private static func killExistingCompanion() {
        _ = runCommand(["pkill", "-f", "idb_companion"])
        Thread.sleep(forTimeInterval: 0.5)
    }

    private static func ensureCompanion(udid: String) throws {
        if isCompanionRunning() {
            let running = runningCompanionUDID()
            if running == udid {
                return
            }
            killExistingCompanion()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: companionPath)
        process.arguments = ["--udid", udid, "--grpc-port", "\(grpcPort)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw IDBError.companionUnavailable
        }

        let deadline = Date().addingTimeInterval(5.0)
        var ready = false
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
            if isCompanionRunning() {
                ready = true
                break
            }
        }

        guard ready else {
            process.terminate()
            throw IDBError.companionUnavailable
        }
    }

    // MARK: - Simulator focus

    /// Brings the Simulator app to the foreground so HID events are received.
    private static func activateSimulator() {
        _ = runCommand(["osascript", "-e", "tell application \"Simulator\" to activate"])
        Thread.sleep(forTimeInterval: 0.3)
    }

    // MARK: - HID event builders

    private func makePressEvent(action: Idb_HIDEvent.HIDPressAction, direction: HIDDirection) -> Idb_HIDEvent {
        var press = Idb_HIDEvent.HIDPress()
        press.action = action
        press.direction = direction

        var event = Idb_HIDEvent()
        event.event = .press(press)
        return event
    }

    private func touchAction(x: Double, y: Double) -> Idb_HIDEvent.HIDPressAction {
        var point = Idb_Point()
        point.x = x
        point.y = y

        var touch = Idb_HIDEvent.HIDTouch()
        touch.point = point

        var action = Idb_HIDEvent.HIDPressAction()
        action.action = .touch(touch)
        return action
    }

    private func keyAction(keycode: UInt64) -> Idb_HIDEvent.HIDPressAction {
        var key = Idb_HIDEvent.HIDKey()
        key.keycode = keycode

        var action = Idb_HIDEvent.HIDPressAction()
        action.action = .key(key)
        return action
    }

    private func buttonAction(_ buttonType: HIDButtonType) -> Idb_HIDEvent.HIDPressAction {
        var btn = Idb_HIDEvent.HIDButton()
        btn.button = buttonType

        var action = Idb_HIDEvent.HIDPressAction()
        action.action = .button(btn)
        return action
    }

    // MARK: - Streaming helper

    private func sendEvents(_ events: [Idb_HIDEvent]) throws {
        let call = client.hid()
        for event in events {
            _ = try call.sendMessage(event).wait()
        }
        _ = try call.sendEnd().wait()
        _ = try call.response.wait()
    }

    // MARK: - Public API

    func tap(x: Double, y: Double) throws {
        IDBClient.activateSimulator()
        let action = touchAction(x: x, y: y)
        let events = [
            makePressEvent(action: action, direction: .down),
            makePressEvent(action: action, direction: .up)
        ]
        try sendEvents(events)
    }

    func longPress(x: Double, y: Double, duration: Double) throws {
        IDBClient.activateSimulator()
        let action = touchAction(x: x, y: y)
        let down = makePressEvent(action: action, direction: .down)
        let up   = makePressEvent(action: action, direction: .up)

        let call = client.hid()
        _ = try call.sendMessage(down).wait()
        Thread.sleep(forTimeInterval: max(0.05, duration))
        _ = try call.sendMessage(up).wait()
        _ = try call.sendEnd().wait()
        _ = try call.response.wait()
    }

    func swipe(x1: Double, y1: Double, x2: Double, y2: Double, duration: Double) throws {
        IDBClient.activateSimulator()

        var start = Idb_Point(); start.x = x1; start.y = y1
        var end   = Idb_Point(); end.x = x2;   end.y = y2

        var swipe = Idb_HIDEvent.HIDSwipe()
        swipe.start = start
        swipe.end = end
        swipe.duration = max(0.1, duration)

        var event = Idb_HIDEvent()
        event.event = .swipe(swipe)

        try sendEvents([event])
    }

    func type(_ text: String) throws {
        IDBClient.activateSimulator()
        var events: [Idb_HIDEvent] = []
        for char in text {
            if let keycode = iOSKeycode(for: char) {
                let action = keyAction(keycode: keycode)
                events.append(makePressEvent(action: action, direction: .down))
                events.append(makePressEvent(action: action, direction: .up))
            }
        }
        guard !events.isEmpty else { return }
        try sendEvents(events)
    }

    func pressKey(keycode: UInt64) throws {
        IDBClient.activateSimulator()
        let action = keyAction(keycode: keycode)
        let events = [
            makePressEvent(action: action, direction: .down),
            makePressEvent(action: action, direction: .up)
        ]
        try sendEvents(events)
    }

    func pressButton(_ buttonType: HIDButtonType) throws {
        IDBClient.activateSimulator()
        let action = buttonAction(buttonType)
        let events = [
            makePressEvent(action: action, direction: .down),
            makePressEvent(action: action, direction: .up)
        ]
        try sendEvents(events)
    }

    // MARK: - Accessibility

    func accessibilityInfo(point: Idb_Point? = nil) throws -> String {
        var request = Idb_AccessibilityInfoRequest()
        request.format = .nested
        if let point {
            request.point = point
        }
        let call = client.accessibilityInfo(request)
        let response = try call.response.wait()
        return response.json
    }

    // MARK: - iOS USB HID keycode table (USB HID Usage Table page 0x07)

    private func iOSKeycode(for char: Character) -> UInt64? {
        switch char {
        case "a", "A": return 0x04
        case "b", "B": return 0x05
        case "c", "C": return 0x06
        case "d", "D": return 0x07
        case "e", "E": return 0x08
        case "f", "F": return 0x09
        case "g", "G": return 0x0A
        case "h", "H": return 0x0B
        case "i", "I": return 0x0C
        case "j", "J": return 0x0D
        case "k", "K": return 0x0E
        case "l", "L": return 0x0F
        case "m", "M": return 0x10
        case "n", "N": return 0x11
        case "o", "O": return 0x12
        case "p", "P": return 0x13
        case "q", "Q": return 0x14
        case "r", "R": return 0x15
        case "s", "S": return 0x16
        case "t", "T": return 0x17
        case "u", "U": return 0x18
        case "v", "V": return 0x19
        case "w", "W": return 0x1A
        case "x", "X": return 0x1B
        case "y", "Y": return 0x1C
        case "z", "Z": return 0x1D
        case "1", "!": return 0x1E
        case "2", "@": return 0x1F
        case "3", "#": return 0x20
        case "4", "$": return 0x21
        case "5", "%": return 0x22
        case "6", "^": return 0x23
        case "7", "&": return 0x24
        case "8", "*": return 0x25
        case "9", "(": return 0x26
        case "0", ")": return 0x27
        case "\n", "\r": return 0x28
        case "\u{1B}": return 0x29
        case "\u{08}": return 0x2A
        case "\t":     return 0x2B
        case " ":      return 0x2C
        case "-", "_": return 0x2D
        case "=", "+": return 0x2E
        case "[", "{": return 0x2F
        case "]", "}": return 0x30
        case "\\", "|": return 0x31
        case ";", ":": return 0x33
        case "'", "\"": return 0x34
        case "`", "~": return 0x35
        case ",", "<": return 0x36
        case ".", ">": return 0x37
        case "/", "?": return 0x38
        default: return nil
        }
    }
}

// MARK: - HIDButtonType from string

extension HIDButtonType {
    static func from(name: String) -> HIDButtonType? {
        switch name.lowercased() {
        case "home":           return .home
        case "lock", "power":  return .lock
        case "siri":           return .siri
        case "side":           return .sideButton
        case "apple-pay":      return .applePay
        default:               return nil
        }
    }

    var displayName: String {
        switch self {
        case .home:        return "home"
        case .lock:        return "lock"
        case .siri:        return "siri"
        case .sideButton:  return "side"
        case .applePay:    return "apple-pay"
        case .UNRECOGNIZED(let v): return "unknown(\(v))"
        }
    }
}
