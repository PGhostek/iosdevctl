import ArgumentParser
import Foundation

struct UICommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ui",
        abstract: "UI interaction commands — tap, swipe, type, button, long-press.",
        subcommands: [
            UITap.self,
            UISwipe.self,
            UIType.self,
            UIButton.self,
            UILongPress.self
        ]
    )
}

// MARK: - Shared companion helper

private func makeClient(udid: String) -> IDBClient {
    do {
        return try IDBClient(udid: udid)
    } catch {
        Output.error(
            code: "COMPANION_UNAVAILABLE",
            message: "Failed to start idb_companion. Ensure idb_companion is installed.",
            suggestion: "Install with: brew install idb-companion"
        )
    }
}

// MARK: - UITap

struct UITap: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tap",
        abstract: "Tap at coordinates."
    )

    @Argument(help: "X coordinate.")
    var x: Double

    @Argument(help: "Y coordinate.")
    var y: Double

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)
        guard sim.isBooted else {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device '\(sim.name)' is not booted.",
                suggestion: "Boot it with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        let client = makeClient(udid: sim.udid)
        do {
            try client.tap(x: x, y: y)
        } catch {
            Output.error(
                code: "TAP_FAILED",
                message: "Tap failed: \(error.localizedDescription)"
            )
        }

        Output.success([
            "status": "ok",
            "message": "Tap performed.",
            "x": x,
            "y": y,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }
}

// MARK: - UISwipe

struct UISwipe: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swipe",
        abstract: "Swipe gesture from one point to another."
    )

    @Argument(help: "Start X coordinate.")
    var x1: Double

    @Argument(help: "Start Y coordinate.")
    var y1: Double

    @Argument(help: "End X coordinate.")
    var x2: Double

    @Argument(help: "End Y coordinate.")
    var y2: Double

    @Option(name: .long, help: "Swipe duration in seconds (default: 0.5).")
    var duration: Double = 0.5

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)
        guard sim.isBooted else {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device '\(sim.name)' is not booted.",
                suggestion: "Boot it with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        let client = makeClient(udid: sim.udid)
        do {
            try client.swipe(x1: x1, y1: y1, x2: x2, y2: y2, duration: duration)
        } catch {
            Output.error(
                code: "SWIPE_FAILED",
                message: "Swipe failed: \(error.localizedDescription)"
            )
        }

        Output.success([
            "status": "ok",
            "message": "Swipe performed.",
            "from": ["x": x1, "y": y1],
            "to": ["x": x2, "y": y2],
            "duration": duration,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }
}

// MARK: - UIType

struct UIType: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "type",
        abstract: "Type text into the focused text field."
    )

    @Argument(help: "Text to type.")
    var text: String

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)
        guard sim.isBooted else {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device '\(sim.name)' is not booted.",
                suggestion: "Boot it with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        let client = makeClient(udid: sim.udid)
        do {
            try client.type(text)
        } catch {
            Output.error(
                code: "TYPE_FAILED",
                message: "Type failed: \(error.localizedDescription)"
            )
        }

        Output.success([
            "status": "ok",
            "message": "Text typed.",
            "text": text,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }
}

// MARK: - UIButton

struct UIButton: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "button",
        abstract: "Press a hardware button (home, lock, siri, side, apple-pay)."
    )

    @Argument(help: "Button name: home, lock, siri, side, apple-pay.")
    var name: String

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        guard let buttonType = HIDButtonType.from(name: name) else {
            Output.error(
                code: "INVALID_BUTTON",
                message: "Unknown button '\(name)'.",
                suggestion: "Valid buttons: home, lock, siri, side, apple-pay"
            )
        }

        let sim = DeviceResolver.resolve(identifier: device)
        guard sim.isBooted else {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device '\(sim.name)' is not booted.",
                suggestion: "Boot it with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        let client = makeClient(udid: sim.udid)
        do {
            try client.pressButton(buttonType)
        } catch {
            Output.error(
                code: "BUTTON_FAILED",
                message: "Button press failed: \(error.localizedDescription)"
            )
        }

        Output.success([
            "status": "ok",
            "message": "Button pressed.",
            "button": buttonType.displayName,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }
}

// MARK: - UILongPress

struct UILongPress: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "long-press",
        abstract: "Long-press at coordinates."
    )

    @Argument(help: "X coordinate.")
    var x: Double

    @Argument(help: "Y coordinate.")
    var y: Double

    @Option(name: .long, help: "Hold duration in seconds (default: 1.0).")
    var duration: Double = 1.0

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)
        guard sim.isBooted else {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device '\(sim.name)' is not booted.",
                suggestion: "Boot it with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        let client = makeClient(udid: sim.udid)
        do {
            try client.longPress(x: x, y: y, duration: duration)
        } catch {
            Output.error(
                code: "LONG_PRESS_FAILED",
                message: "Long press failed: \(error.localizedDescription)"
            )
        }

        Output.success([
            "status": "ok",
            "message": "Long press performed.",
            "x": x,
            "y": y,
            "duration": duration,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }
}
