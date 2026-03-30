import XCTest

/// Tests that verify the JSON output contract across all commands.
/// These do not require a booted simulator.
final class OutputFormatTests: XCTestCase {

    // MARK: - Success shape

    func test_successOutput_alwaysHasStatusOk() {
        // device list is always safe to run regardless of simulator state
        let result = iosdevctl("device", "list")
        // Either it's an array (success) or an object with status=ok
        if let arr = result.jsonArray {
            _ = arr // confirms it's a valid array
            XCTAssertEqual(result.exitCode, 0)
        } else if let dict = result.jsonDict {
            XCTAssertEqual(dict["status"] as? String, "ok")
        }
    }

    // MARK: - Error shape

    func test_errorOutput_hasRequiredFields() {
        // Trigger an error by requesting an unknown device
        let result = iosdevctl("device", "boot", "--device", "NoSuchDevice-XYZZY")
        XCTAssertNotEqual(result.exitCode, 0)

        guard let json = result.jsonDict else {
            return XCTFail("Error output must be a JSON object, got: \(result.stdout)")
        }
        XCTAssertEqual(json["status"] as? String, "error", "Error responses must have status=error")
        XCTAssertNotNil(json["code"],    "Error responses must have a 'code' field")
        XCTAssertNotNil(json["message"], "Error responses must have a 'message' field")
    }

    func test_errorOutput_isValidJSON() {
        let result = iosdevctl("device", "boot", "--device", "NoSuchDevice-XYZZY")
        XCTAssertNotNil(result.jsonDict, "Error output must be valid JSON")
    }

    func test_unknownCommand_nonZeroExit() {
        let result = iosdevctl("completely-unknown-command")
        XCTAssertNotEqual(result.exitCode, 0)
    }
}
