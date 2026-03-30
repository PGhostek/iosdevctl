import ArgumentParser
import Foundation

// MARK: - mcp serve

struct MCPCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp",
        abstract: "Start an MCP (Model Context Protocol) server over stdin/stdout.",
        subcommands: [MCPServe.self],
        defaultSubcommand: MCPServe.self
    )
}

struct MCPServe: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Run the MCP JSON-RPC server (reads from stdin, writes to stdout)."
    )

    func run() throws {
        let server = MCPServer()
        server.run()
    }
}

// MARK: - MCPServer

private final class MCPServer {

    // Each tool maps to a CLI invocation. args are the JSON params keys → values.
    struct ToolDef {
        let name: String
        let description: String
        let inputSchema: [String: Any]
        // Closure that turns decoded params into argv for iosdevctl
        let buildArgs: ([String: Any]) -> [String]
    }

    private let tools: [ToolDef] = [
        // device list
        ToolDef(
            name: "device_list",
            description: "List all available iOS simulators.",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            buildArgs: { _ in ["device", "list", "--pretty"] }
        ),
        // device boot
        ToolDef(
            name: "device_boot",
            description: "Boot a simulator by UDID or name.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["device", "boot", "--pretty"]
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // device shutdown
        ToolDef(
            name: "device_shutdown",
            description: "Shut down a booted simulator.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["device", "shutdown", "--pretty"]
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // device screenshot
        ToolDef(
            name: "device_screenshot",
            description: "Take a screenshot and save it to a file. Returns the path where the file was saved. Output path is optional — defaults to /tmp/iosdevctl-screenshot-<timestamp>.png.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "output": ["type": "string", "description": "Output file path (PNG). Optional — auto-generated in /tmp if omitted."],
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["device", "screenshot", "--pretty"]
                if let o = p["output"] as? String { args += ["--output", o] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // app list
        ToolDef(
            name: "app_list",
            description: "List installed apps on a simulator.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["app", "list", "--pretty"]
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // app launch
        ToolDef(
            name: "app_launch",
            description: "Launch an installed app by bundle ID.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "bundle_id": ["type": "string", "description": "App bundle identifier."],
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": ["bundle_id"]
            ],
            buildArgs: { p in
                var args = ["app", "launch", "--pretty"]
                if let b = p["bundle_id"] as? String { args.insert(b, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // app terminate
        ToolDef(
            name: "app_terminate",
            description: "Terminate a running app by bundle ID.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "bundle_id": ["type": "string", "description": "App bundle identifier."],
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": ["bundle_id"]
            ],
            buildArgs: { p in
                var args = ["app", "terminate", "--pretty"]
                if let b = p["bundle_id"] as? String { args.insert(b, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui tap
        ToolDef(
            name: "ui_tap",
            description: "Tap at (x, y) coordinates on the simulator screen.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "x": ["type": "number", "description": "X coordinate in points."],
                    "y": ["type": "number", "description": "Y coordinate in points."],
                    "device": ["type": "string", "description": "Device UDID or name."]
                ] as [String: Any],
                "required": ["x", "y"]
            ],
            buildArgs: { p in
                var args = ["ui", "tap", "--pretty"]
                if let x = p["x"] { args.insert("\(x)", at: 2) } else { args.insert("0", at: 2) }
                if let y = p["y"] { args.insert("\(y)", at: 3) } else { args.insert("0", at: 3) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui swipe
        ToolDef(
            name: "ui_swipe",
            description: "Swipe from (x1,y1) to (x2,y2).",
            inputSchema: [
                "type": "object",
                "properties": [
                    "x1": ["type": "number"], "y1": ["type": "number"],
                    "x2": ["type": "number"], "y2": ["type": "number"],
                    "duration": ["type": "number", "description": "Swipe duration in seconds (default 0.5)."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["x1", "y1", "x2", "y2"]
            ],
            buildArgs: { p in
                let x1 = p["x1"] ?? 0, y1 = p["y1"] ?? 0
                let x2 = p["x2"] ?? 0, y2 = p["y2"] ?? 0
                var args = ["ui", "swipe", "\(x1)", "\(y1)", "\(x2)", "\(y2)", "--pretty"]
                if let dur = p["duration"] { args += ["--duration", "\(dur)"] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui type
        ToolDef(
            name: "ui_type",
            description: "Type text into the focused field.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": ["type": "string", "description": "Text to type."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["text"]
            ],
            buildArgs: { p in
                var args = ["ui", "type", "--pretty"]
                if let t = p["text"] as? String { args.insert(t, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui long-press
        ToolDef(
            name: "ui_long_press",
            description: "Long-press at (x, y) for a given duration.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "x": ["type": "number"], "y": ["type": "number"],
                    "duration": ["type": "number", "description": "Hold duration in seconds (default 1.0)."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["x", "y"]
            ],
            buildArgs: { p in
                let x = p["x"] ?? 0, y = p["y"] ?? 0
                var args = ["ui", "long-press", "\(x)", "\(y)", "--pretty"]
                if let dur = p["duration"] { args += ["--duration", "\(dur)"] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui tree
        ToolDef(
            name: "ui_tree",
            description: "Dump the accessibility element tree. Optionally filter by label/value text or element type.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "query": ["type": "string", "description": "Filter by label or value text."],
                    "type": ["type": "string", "description": "Filter by element type (e.g. Button, TextField)."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["ui", "tree", "--pretty"]
                if let q = p["query"] as? String { args += ["--query", q] }
                if let t = p["type"] as? String { args += ["--type", t] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui element-tap
        ToolDef(
            name: "ui_element_tap",
            description: "Tap an element by its AXUniqueId accessibility identifier.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "identifier": ["type": "string", "description": "AXUniqueId of the element."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["identifier"]
            ],
            buildArgs: { p in
                var args = ["ui", "element-tap", "--pretty"]
                if let id = p["identifier"] as? String { args.insert(id, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // ui button
        ToolDef(
            name: "ui_button",
            description: "Press a hardware button: home, lock, siri, side, or apple-pay.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string", "description": "Button name: home, lock, siri, side, apple-pay."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["name"]
            ],
            buildArgs: { p in
                var args = ["ui", "button", "--pretty"]
                if let n = p["name"] as? String { args.insert(n, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // pasteboard get
        ToolDef(
            name: "pasteboard_get",
            description: "Get the simulator pasteboard contents.",
            inputSchema: [
                "type": "object",
                "properties": ["device": ["type": "string"] as [String: Any]],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["pasteboard", "get", "--pretty"]
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // pasteboard set
        ToolDef(
            name: "pasteboard_set",
            description: "Set the simulator pasteboard to a string value.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "value": ["type": "string", "description": "Text to place on the pasteboard."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["value"]
            ],
            buildArgs: { p in
                var args = ["pasteboard", "set", "--pretty"]
                if let v = p["value"] as? String { args.insert(v, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // url open
        ToolDef(
            name: "url_open",
            description: "Open a URL on the simulator (deep links, https, custom schemes).",
            inputSchema: [
                "type": "object",
                "properties": [
                    "url": ["type": "string", "description": "URL to open."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["url"]
            ],
            buildArgs: { p in
                var args = ["url", "open", "--pretty"]
                if let u = p["url"] as? String { args.insert(u, at: 2) }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // agent tap-text
        ToolDef(
            name: "agent_tap_text",
            description: "Tap the first element whose label or value matches text — no coordinates needed. Preferred over ui_tap when you can identify the element by its visible text.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": ["type": "string", "description": "Text to match against element labels/values (case-insensitive)."],
                    "type": ["type": "string", "description": "Optionally restrict to a specific element type (e.g. Button)."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["text"]
            ],
            buildArgs: { p in
                var args = ["agent", "tap-text", "--pretty"]
                if let t = p["text"] as? String { args.insert(t, at: 2) }
                if let ty = p["type"] as? String { args += ["--type", ty] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // agent wait-for
        ToolDef(
            name: "agent_wait_for",
            description: "Block until an element matching text appears on screen. Use after navigation or actions that trigger async UI changes.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "text": ["type": "string", "description": "Text to wait for (case-insensitive)."],
                    "timeout": ["type": "number", "description": "Max seconds to wait (default: 10)."],
                    "interval": ["type": "number", "description": "Poll interval in seconds (default: 0.5)."],
                    "type": ["type": "string", "description": "Optionally restrict to a specific element type."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": ["text"]
            ],
            buildArgs: { p in
                var args = ["agent", "wait-for", "--pretty"]
                if let t = p["text"] as? String { args.insert(t, at: 2) }
                if let to = p["timeout"] { args += ["--timeout", "\(to)"] }
                if let iv = p["interval"] { args += ["--interval", "\(iv)"] }
                if let ty = p["type"] as? String { args += ["--type", ty] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
        // agent context
        ToolDef(
            name: "agent_context",
            description: "Return screenshot path + full accessibility tree in one call. Best first step for an agent that needs to understand the current screen before acting.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "output": ["type": "string", "description": "Screenshot output path (default: auto-generated in /tmp)."],
                    "query": ["type": "string", "description": "Filter tree elements by label/value text."],
                    "type": ["type": "string", "description": "Filter tree elements by element type."],
                    "device": ["type": "string"]
                ] as [String: Any],
                "required": [] as [String]
            ],
            buildArgs: { p in
                var args = ["agent", "context", "--pretty"]
                if let o = p["output"] as? String { args += ["--output", o] }
                if let q = p["query"] as? String { args += ["--query", q] }
                if let t = p["type"] as? String { args += ["--type", t] }
                if let d = p["device"] as? String { args += ["--device", d] }
                return args
            }
        ),
    ]

    private var toolsByName: [String: ToolDef] = [:]

    init() {
        for t in tools { toolsByName[t.name] = t }
    }

    // MARK: - Main loop

    func run() {
        // MCP servers must use stderr for any diagnostic output —
        // stdout is reserved exclusively for JSON-RPC responses.
        while let line = readLine(strippingNewline: true) {
            guard !line.isEmpty else { continue }
            guard let data = line.data(using: .utf8),
                  let msg = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                sendParseError(id: nil)
                continue
            }
            handle(msg)
        }
    }

    // MARK: - Dispatch

    private func handle(_ msg: [String: Any]) {
        let id = msg["id"]
        guard let method = msg["method"] as? String else {
            sendError(id: id, code: -32600, message: "Invalid Request: missing method")
            return
        }

        switch method {
        case "initialize":
            sendResult(id: id, result: [
                "protocolVersion": "2024-11-05",
                "serverInfo": ["name": "iosdevctl", "version": "0.1.0"],
                "capabilities": ["tools": [:] as [String: Any]]
            ])

        case "tools/list":
            let list = tools.map { t -> [String: Any] in
                ["name": t.name, "description": t.description, "inputSchema": t.inputSchema]
            }
            sendResult(id: id, result: ["tools": list])

        case "tools/call":
            guard let params = msg["params"] as? [String: Any],
                  let toolName = params["name"] as? String else {
                sendError(id: id, code: -32602, message: "Invalid params: missing tool name")
                return
            }
            guard let tool = toolsByName[toolName] else {
                sendError(id: id, code: -32602, message: "Unknown tool: \(toolName)")
                return
            }
            let toolArgs = (params["arguments"] as? [String: Any]) ?? [:]
            let argv = tool.buildArgs(toolArgs)
            let (output, exitCode) = invokeSubprocess(argv)
            let isError = exitCode != 0
            sendResult(id: id, result: [
                "content": [["type": "text", "text": output]],
                "isError": isError
            ])

        case "notifications/initialized":
            // No response needed for notifications
            break

        default:
            sendError(id: id, code: -32601, message: "Method not found: \(method)")
        }
    }

    // MARK: - Subprocess

    private func invokeSubprocess(_ args: [String]) -> (String, Int32) {
        // Re-invoke the iosdevctl binary itself with the given args.
        let execPath = CommandLine.arguments[0]
        let process = Process()
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ("{\"status\":\"error\",\"message\":\"\(error.localizedDescription)\"}", 1)
        }

        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outData + errData, encoding: .utf8) ?? ""
        return (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus)
    }

    // MARK: - JSON-RPC response helpers

    private func sendResult(id: Any?, result: Any) {
        var response: [String: Any] = ["jsonrpc": "2.0", "result": result]
        if let id = id { response["id"] = id }
        writeResponse(response)
    }

    private func sendError(id: Any?, code: Int, message: String) {
        var response: [String: Any] = [
            "jsonrpc": "2.0",
            "error": ["code": code, "message": message]
        ]
        if let id = id { response["id"] = id }
        writeResponse(response)
    }

    private func sendParseError(id: Any?) {
        sendError(id: id, code: -32700, message: "Parse error")
    }

    private func writeResponse(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: data, encoding: .utf8) else { return }
        print(line)
        // Flush stdout — critical for MCP over stdio
        fflush(stdout)
    }
}
