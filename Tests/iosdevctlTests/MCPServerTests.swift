import XCTest

/// Tests for Phase 4 — MCP server JSON-RPC protocol.
/// These do not require a booted simulator.
final class MCPServerTests: XCTestCase {

    // MARK: - initialize

    func test_initialize_returnsProtocolVersion() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"test"}}}
            """)
        XCTAssertEqual(result.exitCode, 0)
        guard let json = result.jsonDict,
              let res = json["result"] as? [String: Any] else {
            return XCTFail("Expected result object, got: \(result.stdout)")
        }
        XCTAssertEqual(res["protocolVersion"] as? String, "2024-11-05")
        XCTAssertNotNil(res["serverInfo"])
        XCTAssertNotNil(res["capabilities"])
    }

    func test_initialize_echoesRequestId() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":42,"method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"test"}}}
            """)
        guard let json = result.jsonDict else { return XCTFail("Not valid JSON") }
        XCTAssertEqual(json["id"] as? Int, 42)
    }

    // MARK: - tools/list

    func test_toolsList_returns20Tools() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
            """)
        guard let json = result.jsonDict,
              let res = json["result"] as? [String: Any],
              let tools = res["tools"] as? [[String: Any]] else {
            return XCTFail("Expected tools array, got: \(result.stdout)")
        }
        XCTAssertEqual(tools.count, 20, "Expected 20 tools (17 core + 3 agent)")
    }

    func test_toolsList_allToolsHaveRequiredFields() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
            """)
        guard let tools = (result.jsonDict?["result"] as? [String: Any])?["tools"] as? [[String: Any]] else {
            return XCTFail("Could not parse tools list")
        }
        for tool in tools {
            XCTAssertNotNil(tool["name"],        "Tool missing 'name': \(tool)")
            XCTAssertNotNil(tool["description"], "Tool missing 'description': \(tool)")
            XCTAssertNotNil(tool["inputSchema"], "Tool missing 'inputSchema': \(tool)")
        }
    }

    func test_toolsList_containsExpectedToolNames() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
            """)
        guard let tools = (result.jsonDict?["result"] as? [String: Any])?["tools"] as? [[String: Any]] else {
            return XCTFail("Could not parse tools list")
        }
        let names = Set(tools.compactMap { $0["name"] as? String })
        let expected: Set<String> = [
            "device_list", "device_boot", "device_shutdown", "device_screenshot",
            "app_list", "app_launch", "app_terminate",
            "ui_tap", "ui_swipe", "ui_type", "ui_long_press",
            "ui_tree", "ui_element_tap", "ui_button",
            "pasteboard_get", "pasteboard_set", "url_open",
            "agent_tap_text", "agent_wait_for", "agent_context"
        ]
        XCTAssertEqual(names, expected)
    }

    // MARK: - tools/call

    func test_toolsCall_deviceList_succeeds() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"device_list","arguments":{}}}
            """)
        guard let json = result.jsonDict,
              let res = json["result"] as? [String: Any] else {
            return XCTFail("Expected result object, got: \(result.stdout)")
        }
        XCTAssertEqual(res["isError"] as? Bool, false)
        let content = res["content"] as? [[String: Any]]
        XCTAssertNotNil(content?.first?["text"])
    }

    func test_toolsCall_unknownTool_returnsError() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"nonexistent_tool","arguments":{}}}
            """)
        guard let json = result.jsonDict,
              let error = json["error"] as? [String: Any] else {
            return XCTFail("Expected error object, got: \(result.stdout)")
        }
        XCTAssertEqual(error["code"] as? Int, -32602)
    }

    func test_toolsCall_unknownDeviceName_isErrorTrue() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"device_boot","arguments":{"device":"NoSuchDevice-XYZ"}}}
            """)
        guard let res = result.jsonDict?["result"] as? [String: Any] else {
            return XCTFail("Expected result object")
        }
        XCTAssertEqual(res["isError"] as? Bool, true)
    }

    // MARK: - Error handling

    func test_unknownMethod_returnsMethodNotFound() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"method":"unknown/method","params":{}}
            """)
        guard let error = result.jsonDict?["error"] as? [String: Any] else {
            return XCTFail("Expected error object")
        }
        XCTAssertEqual(error["code"] as? Int, -32601)
    }

    func test_invalidJSON_returnsParseError() {
        let result = mcpRequest("this is not json at all")
        guard let error = result.jsonDict?["error"] as? [String: Any] else {
            return XCTFail("Expected error object, got: \(result.stdout)")
        }
        XCTAssertEqual(error["code"] as? Int, -32700)
    }

    func test_missingMethodField_returnsInvalidRequest() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":1,"params":{}}
            """)
        guard let error = result.jsonDict?["error"] as? [String: Any] else {
            return XCTFail("Expected error object")
        }
        XCTAssertEqual(error["code"] as? Int, -32600)
    }

    func test_responseIsValidJSONRPC() {
        let result = mcpRequest("""
            {"jsonrpc":"2.0","id":99,"method":"tools/list","params":{}}
            """)
        guard let json = result.jsonDict else { return XCTFail("Not valid JSON") }
        XCTAssertEqual(json["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(json["id"] as? Int, 99)
    }
}
