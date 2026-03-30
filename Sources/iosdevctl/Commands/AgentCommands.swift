import ArgumentParser
import Foundation

struct AgentCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        abstract: "Agent-optimized commands that reduce round-trips for AI workflows.",
        subcommands: [
            AgentTapText.self,
            AgentWaitFor.self,
            AgentContext.self
        ]
    )
}

// MARK: - agent tap-text

struct AgentTapText: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tap-text",
        abstract: "Tap the first element whose label or value matches text — no coordinates needed."
    )

    @Argument(help: "Text to match against element labels and values (case-insensitive).")
    var text: String

    @Option(name: .long, help: "Filter to a specific element type (e.g. Button).")
    var type: String?

    @Flag(name: .long, help: "Require exact label match (prevents 'Male' matching 'Female').")
    var exact: Bool = false

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

        let client = makeAgentClient(udid: sim.udid)

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
                message: "Could not parse accessibility tree from idb_companion."
            )
        }

        guard let element = findByText(rawTree, text: text, type: type, exact: exact) else {
            Output.error(
                code: "ELEMENT_NOT_FOUND",
                message: "No element with text '\(text)' found on screen.",
                suggestion: "Use 'iosdevctl ui tree' to see available elements.",
                exitCode: 3
            )
        }

        guard let frame = element["frame"] as? [String: Any],
              let fx = frame["x"] as? Double,
              let fy = frame["y"] as? Double,
              let fw = frame["width"] as? Double,
              let fh = frame["height"] as? Double else {
            Output.error(
                code: "ELEMENT_NO_FRAME",
                message: "Element '\(text)' has no usable frame."
            )
        }

        let cx = fx + fw / 2
        let cy = fy + fh / 2

        do {
            try client.tap(x: cx, y: cy)
        } catch {
            Output.error(
                code: "TAP_FAILED",
                message: "Tap on '\(text)' failed: \(error.localizedDescription)"
            )
        }

        let label = (element["AXLabel"] as? String) ?? text
        Output.success([
            "status": "ok",
            "message": "Tapped element.",
            "matched_label": label,
            "x": cx,
            "y": cy,
            "device": sim.name,
            "udid": sim.udid
        ] as [String: Any], pretty: pretty)
    }

    /// Find the first element whose AXLabel or AXValue contains the text,
    /// optionally filtered by element type.
    private func findByText(_ node: Any, text: String, type elementType: String?, exact: Bool = false) -> [String: Any]? {
        if let dict = node as? [String: Any] {
            let label = (dict["AXLabel"] as? String) ?? ""
            let value = (dict["AXValue"] as? String) ?? ""
            let typeStr = (dict["type"] as? String) ?? ""

            let matchesText: Bool
            if exact {
                matchesText = label.caseInsensitiveCompare(text) == .orderedSame ||
                              value.caseInsensitiveCompare(text) == .orderedSame
            } else {
                matchesText = label.localizedCaseInsensitiveContains(text) ||
                              value.localizedCaseInsensitiveContains(text)
            }
            let matchesType = elementType.map { typeStr.localizedCaseInsensitiveContains($0) } ?? true

            if matchesText && matchesType {
                return dict
            }

            if let children = dict["children"] as? [Any] {
                for child in children {
                    if let found = findByText(child, text: text, type: elementType, exact: exact) { return found }
                }
            }
        } else if let arr = node as? [Any] {
            for item in arr {
                if let found = findByText(item, text: text, type: elementType, exact: exact) { return found }
            }
        }
        return nil
    }
}

// MARK: - agent wait-for

struct AgentWaitFor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wait-for",
        abstract: "Block until an element matching text appears on screen (polls accessibility tree)."
    )

    @Argument(help: "Text to wait for (matches element labels and values, case-insensitive).")
    var text: String

    @Option(name: .long, help: "Maximum seconds to wait (default: 10).")
    var timeout: Double = 10.0

    @Option(name: .long, help: "Poll interval in seconds (default: 0.5).")
    var interval: Double = 0.5

    @Option(name: .long, help: "Filter to a specific element type (e.g. Button).")
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

        let client = makeAgentClient(udid: sim.udid)
        let deadline = Date().addingTimeInterval(timeout)
        let pollInterval = max(0.1, interval)

        while Date() < deadline {
            if let element = try? findElement(client: client, text: text, type: type) {
                let label = (element["AXLabel"] as? String) ?? text
                let frame = element["frame"] as? [String: Any]
                Output.success([
                    "status": "ok",
                    "found": true,
                    "matched_label": label,
                    "frame": frame as Any,
                    "device": sim.name,
                    "udid": sim.udid
                ] as [String: Any], pretty: pretty)
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }

        Output.error(
            code: "WAIT_TIMEOUT",
            message: "Element with text '\(text)' did not appear within \(timeout)s.",
            suggestion: "Increase --timeout or check the element label with: iosdevctl ui tree",
            exitCode: 1
        )
    }

    private func findElement(client: IDBClient, text: String, type elementType: String?) throws -> [String: Any]? {
        let jsonString = try client.accessibilityInfo()
        guard let data = jsonString.data(using: .utf8),
              let rawTree = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return searchNode(rawTree, text: text, type: elementType)
    }

    private func searchNode(_ node: Any, text: String, type elementType: String?) -> [String: Any]? {
        if let dict = node as? [String: Any] {
            let label = (dict["AXLabel"] as? String) ?? ""
            let value = (dict["AXValue"] as? String) ?? ""
            let typeStr = (dict["type"] as? String) ?? ""

            let matchesText = label.localizedCaseInsensitiveContains(text) ||
                              value.localizedCaseInsensitiveContains(text)
            let matchesType = elementType.map { typeStr.localizedCaseInsensitiveContains($0) } ?? true

            if matchesText && matchesType { return dict }

            if let children = dict["children"] as? [Any] {
                for child in children {
                    if let found = searchNode(child, text: text, type: elementType) { return found }
                }
            }
        } else if let arr = node as? [Any] {
            for item in arr {
                if let found = searchNode(item, text: text, type: elementType) { return found }
            }
        }
        return nil
    }
}

// MARK: - agent context

struct AgentContext: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "context",
        abstract: "Return screenshot path + accessibility tree in one call — the single best starting point for an agent."
    )

    @Option(name: .long, help: "Screenshot output path (default: /tmp/iosdevctl-context-<timestamp>.png).")
    var output: String?

    @Option(name: .long, help: "Filter tree elements by label/value text.")
    var query: String?

    @Option(name: .long, help: "Filter tree elements by type (e.g. Button).")
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

        // 1. Screenshot
        let timestamp = Int(Date().timeIntervalSince1970)
        let screenshotPath = output ?? "/tmp/iosdevctl-context-\(timestamp).png"
        let screenshotResult = xcrun(["io", sim.udid, "screenshot", screenshotPath])
        if !screenshotResult.succeeded {
            Output.error(
                code: "SCREENSHOT_FAILED",
                message: screenshotResult.stderr.isEmpty ? "Failed to take screenshot." : screenshotResult.stderr
            )
        }

        // 2. Accessibility tree
        let client = makeAgentClient(udid: sim.udid)
        let treeJSON: String
        do {
            treeJSON = try client.accessibilityInfo()
        } catch {
            Output.error(
                code: "ACCESSIBILITY_FAILED",
                message: "Failed to fetch accessibility tree: \(error.localizedDescription)"
            )
        }

        guard let treeData = treeJSON.data(using: .utf8),
              let rawTree = try? JSONSerialization.jsonObject(with: treeData) else {
            Output.error(
                code: "ACCESSIBILITY_PARSE_FAILED",
                message: "Could not parse accessibility tree from idb_companion."
            )
        }

        let elements: Any
        if query != nil || type != nil {
            elements = filterTree(rawTree, query: query, type: type)
        } else {
            elements = rawTree
        }

        Output.success([
            "status": "ok",
            "device": sim.name,
            "udid": sim.udid,
            "screenshot": screenshotPath,
            "elements": elements
        ] as [String: Any], pretty: pretty)
    }

    private func filterTree(_ node: Any, query: String?, type elementType: String?) -> [[String: Any]] {
        var results: [[String: Any]] = []

        func visit(_ obj: Any) {
            if let dict = obj as? [String: Any] {
                let label = (dict["AXLabel"] as? String) ?? ""
                let value = (dict["AXValue"] as? String) ?? ""
                let typeStr = (dict["type"] as? String) ?? ""

                let matchesQuery = query.map {
                    label.localizedCaseInsensitiveContains($0) || value.localizedCaseInsensitiveContains($0)
                } ?? true
                let matchesType = elementType.map { typeStr.localizedCaseInsensitiveContains($0) } ?? true

                if matchesQuery && matchesType { results.append(dict) }

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

// MARK: - Shared IDBClient helper (mirrors makeClient in UICommands)

private func makeAgentClient(udid: String) -> IDBClient {
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
