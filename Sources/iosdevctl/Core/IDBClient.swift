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
        // Try connecting to localhost:10882 with a TCP socket.
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(grpcPort).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        // Set non-blocking + short timeout via SO_RCVTIMEO
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
        // Check if the current companion is running for a specific UDID by
        // examining the process list for `idb_companion --udid`.
        let result = runCommand(["pgrep", "-a", "-l", "idb_companion"])
        guard result.succeeded else { return nil }
        // Look for --udid <value> in the process args
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
        // Give it time to exit
        Thread.sleep(forTimeInterval: 0.5)
    }

    private static func ensureCompanion(udid: String) throws {
        // If already running for THIS udid, we're good.
        if isCompanionRunning() {
            let running = runningCompanionUDID()
            if running == nil || running == udid {
                return
            }
            // Running for a different UDID — restart it.
            killExistingCompanion()
        }

        // Launch idb_companion in background.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: companionPath)
        process.arguments = ["--udid", udid, "--grpc-port", "\(grpcPort)"]

        // Discard companion output so it doesn't pollute our JSON stdout/stderr.
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw IDBError.companionUnavailable
        }

        // Poll for up to 5 seconds until gRPC port is open.
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

    // MARK: - HID helpers

    /// Sends a sequence of HID events via a single client-streaming RPC.
    private func sendEvents(_ events: [Idb_HIDEvent]) throws {
        let call = client.hid()
        for event in events {
            let sendResult = call.sendMessage(event)
            // Wait for each send to avoid overwhelming the channel.
            _ = try sendResult.wait()
        }
        _ = try call.sendEnd().wait()
        _ = try call.response.wait()
    }

    private func pressAction(down: Bool) -> Idb_HIDEvent.HIDPressAction {
        var action = Idb_HIDEvent.HIDPressAction()
        if down {
            action.action = .press(Idb_HIDEvent.HIDPressAction.HIDPress())
        } else {
            action.action = .lift(Idb_HIDEvent.HIDPressAction.HIDLift())
        }
        return action
    }

    private func touchEvent(x: Double, y: Double, down: Bool) -> Idb_HIDEvent {
        var point = Idb_Point()
        point.x = x
        point.y = y

        var touch = Idb_HIDEvent.HIDTouch()
        touch.action = pressAction(down: down)
        touch.point = point

        var event = Idb_HIDEvent()
        event.event = .touch(touch)
        return event
    }

    // MARK: - Public API

    /// Sends a tap (touch-down then touch-up) at the given coordinates.
    func tap(x: Double, y: Double) throws {
        let events = [
            touchEvent(x: x, y: y, down: true),
            touchEvent(x: x, y: y, down: false)
        ]
        try sendEvents(events)
    }

    /// Sends a long-press at the given coordinates for the specified duration.
    func longPress(x: Double, y: Double, duration: Double) throws {
        let down = touchEvent(x: x, y: y, down: true)
        let up = touchEvent(x: x, y: y, down: false)

        let call = client.hid()
        _ = try call.sendMessage(down).wait()

        // Hold — sleep on a background thread to avoid blocking the event loop.
        Thread.sleep(forTimeInterval: max(0.05, duration))

        _ = try call.sendMessage(up).wait()
        _ = try call.sendEnd().wait()
        _ = try call.response.wait()
    }

    /// Sends a swipe gesture interpolated across 10 intermediate points.
    func swipe(x1: Double, y1: Double, x2: Double, y2: Double, duration: Double) throws {
        let steps = 10
        let stepDelay = max(0.01, duration / Double(steps))

        var events: [Idb_HIDEvent] = []

        // Touch-down at start
        events.append(touchEvent(x: x1, y: y1, down: true))

        // Intermediate move points (lift=false, press=false doesn't quite map —
        // we represent "move" as a down event at each intermediate coordinate since
        // idb treats the stream as a continuous touch sequence).
        for i in 1..<steps {
            let t = Double(i) / Double(steps)
            let x = x1 + (x2 - x1) * t
            let y = y1 + (y2 - y1) * t
            events.append(touchEvent(x: x, y: y, down: true))
        }

        // Touch-up at end
        events.append(touchEvent(x: x2, y: y2, down: false))

        // Stream events with delay between each move to simulate gesture timing.
        let call = client.hid()
        for (index, event) in events.enumerated() {
            _ = try call.sendMessage(event).wait()
            // Delay between intermediate moves; no delay before lift at the end.
            let isLast = index == events.count - 1
            if !isLast {
                Thread.sleep(forTimeInterval: stepDelay)
            }
        }
        _ = try call.sendEnd().wait()
        _ = try call.response.wait()
    }

    /// Types a string by sending key-down / key-up pairs for each character.
    func type(_ text: String) throws {
        var events: [Idb_HIDEvent] = []
        for char in text {
            if let keycode = iOSKeycode(for: char) {
                events.append(keyEvent(keycode: keycode, down: true))
                events.append(keyEvent(keycode: keycode, down: false))
            }
        }
        guard !events.isEmpty else { return }
        try sendEvents(events)
    }

    /// Sends a hardware button press + release.
    func pressButton(_ buttonType: HIDButtonType) throws {
        let events = [
            buttonEvent(button: buttonType, down: true),
            buttonEvent(button: buttonType, down: false)
        ]
        try sendEvents(events)
    }

    // MARK: - Key / button event builders

    private func keyEvent(keycode: UInt64, down: Bool) -> Idb_HIDEvent {
        var key = Idb_HIDEvent.HIDKey()
        key.action = pressAction(down: down)
        key.keycode = keycode

        var event = Idb_HIDEvent()
        event.event = .key(key)
        return event
    }

    private func buttonEvent(button: HIDButtonType, down: Bool) -> Idb_HIDEvent {
        var btn = Idb_HIDEvent.HIDButton()
        btn.action = pressAction(down: down)
        btn.button = button

        var event = Idb_HIDEvent()
        event.event = .button(btn)
        return event
    }

    // MARK: - iOS USB HID keycode table (USB HID Usage Table page 0x07)

    /// Maps a Swift Character to its USB HID usage page 7 keycode.
    /// Covers printable ASCII. Returns nil for unsupported characters.
    private func iOSKeycode(for char: Character) -> UInt64? {
        // iOS simulator uses USB HID keyboard codes (usage page 7).
        // Reference: https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf
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
        case "\n", "\r": return 0x28 // Return
        case "\u{1B}": return 0x29   // Escape
        case "\u{08}": return 0x2A   // Backspace
        case "\t":     return 0x2B   // Tab
        case " ":      return 0x2C   // Space
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
    /// Parses a CLI button name (e.g. "home", "lock") to a HIDButtonType.
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
