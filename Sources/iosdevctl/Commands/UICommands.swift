import ArgumentParser
import Foundation

struct UICommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ui",
        abstract: "UI interaction and inspection commands.",
        subcommands: [
            UITap.self,
            UISwipe.self,
            UIType.self,
            UIButton.self,
            UILongPress.self,
            UITree.self,
            UIElementTap.self
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

// MARK: - UITree

struct UITree: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tree",
        abstract: "Dump the accessibility element tree as JSON."
    )

    @Option(name: .long, help: "Filter elements whose label or value contains this text.")
    var query: String?

    @Option(name: .long, help: "Filter elements by type (e.g. Button, TextField, StaticText).")
    var type: String?

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
        let jsonString: String
        do {
            jsonString = try client.accessibilityInfo()
        } catch {
            Output.error(
                code: "ACCESSIBILITY_FAILED",
                message: "Failed to fetch accessibility tree: \(error.localizedDescription)"
            )
        }

        // Parse the raw JSON from idb_companion.
        guard let data = jsonString.data(using: .utf8),
              let rawTree = try? JSONSerialization.jsonObject(with: data) else {
            Output.error(
                code: "ACCESSIBILITY_PARSE_FAILED",
                message: "Could not parse accessibility tree JSON from idb_companion."
            )
        }

        let filtered: Any
        if query != nil || type != nil {
            let elements = filterElements(rawTree, query: query, type: type)
            filtered = elements
        } else {
            filtered = rawTree
        }

        Output.success([
            "status": "ok",
            "device": sim.name,
            "udid": sim.udid,
            "elements": filtered
        ] as [String: Any], pretty: pretty)
    }

    /// Recursively collect elements matching the given query/type filters.
    private func filterElements(_ node: Any, query: String?, type elementType: String?) -> [[String: Any]] {
        var results: [[String: Any]] = []

        func visit(_ obj: Any) {
            if let dict = obj as? [String: Any] {
                let label = (dict["AXLabel"] as? String) ?? ""
                let value = (dict["AXValue"] as? String) ?? ""
                let typeStr = (dict["type"] as? String) ?? ""

                let matchesQuery = query.map { q in
                    label.localizedCaseInsensitiveContains(q) ||
                    value.localizedCaseInsensitiveContains(q)
                } ?? true

                let matchesType = elementType.map { t in
                    typeStr.localizedCaseInsensitiveContains(t)
                } ?? true

                if matchesQuery && matchesType {
                    results.append(dict)
                }

                if let children = dict["children"] as? [Any] {
                    for child in children { visit(child) }
                }
            } else if let arr = obj as? [Any] {
                for item in arr { visit(item) }
            }
        }

        visit(node)
        return results
    }
}

// MARK: - UIElementTap

struct UIElementTap: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "element-tap",
        abstract: "Tap an element by its accessibility identifier."
    )

    @Argument(help: "Accessibility identifier of the element to tap.")
    var identifier: String

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

        // Fetch accessibility tree.
        let jsonString: String
        do {
            jsonString = try client.accessibilityInfo()
        } catch {
            Output.error(
                code: "ACCESSIBILITY_FAILED",
                message: "Failed to fetch accessibility tree: \(error.localizedDescription)"
            )
        }

        guard let data = jsonString.data(using: .utf8),
              let rawTree = try? JSONSerialization.jsonObject(with: data) else {
            Output.error(
                code: "ACCESSIBILITY_PARSE_FAILED",
                message: "Could not parse accessibility tree JSON from idb_companion."
            )
        }

        // Find the element by identifier.
        guard let element = findElement(rawTree, identifier: identifier) else {
            Output.error(
                code: "ELEMENT_NOT_FOUND",
                message: "No element with identifier '\(identifier)' found on screen.",
                suggestion: "Use 'iosdevctl ui tree' to list available elements.",
                exitCode: 3
            )
        }

        // Extract center of the element's frame.
        guard let frame = element["frame"] as? [String: Any],
              let fx = frame["x"] as? Double,
              let fy = frame["y"] as? Double,
              let fw = frame["width"] as? Double,
              let fh = frame["height"] as? Double else {
            Output.error(
                code: "ELEMENT_NO_FRAME",
                message: "Element '\(identifier)' has no usable frame."
            )
        }

        let cx = fx + fw / 2
        let cy = fy + fh / 2

        do {
            try client.tap(x: cx, y: cy)
        } catch {
            Output.error(
                code: "TAP_FAILED",
                message: "Tap on element '\(identifier)' failed: \(error.localizedDescription)"
            )
        }

        Output.success([
            "status": "ok",
            "message": "Tapped element.",
            "identifier": identifier,
            "x": cx,
            "y": cy,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }

    /// Recursively find the first element whose AXUniqueId matches.
    private func findElement(_ node: Any, identifier: String) -> [String: Any]? {
        if let dict = node as? [String: Any] {
            let id = (dict["AXUniqueId"] as? String) ?? ""
            if id == identifier { return dict }
            if let children = dict["children"] as? [Any] {
                for child in children {
                    if let found = findElement(child, identifier: identifier) { return found }
                }
            }
        } else if let arr = node as? [Any] {
            for item in arr {
                if let found = findElement(item, identifier: identifier) { return found }
            }
        }
        return nil
    }
}
