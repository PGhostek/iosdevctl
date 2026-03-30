import XCTest

/// Tests for Phase 1 — device commands.
/// These do not require a booted simulator.
final class DeviceCommandsTests: XCTestCase {

    // MARK: - device list

    func test_deviceList_returnsJSONArray() {
        let result = iosdevctl("device", "list")
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertNotNil(result.jsonArray, "Expected a JSON array, got: \(result.stdout)")
    }

    func test_deviceList_eachDeviceHasRequiredFields() {
        let result = iosdevctl("device", "list")
        guard let devices = result.jsonArray else {
            return XCTFail("Output was not a JSON array")
        }
        XCTAssertFalse(devices.isEmpty, "Expected at least one simulator")
        for device in devices {
            XCTAssertNotNil(device["name"],      "Missing 'name'")
            XCTAssertNotNil(device["udid"],      "Missing 'udid'")
            XCTAssertNotNil(device["state"],     "Missing 'state'")
            XCTAssertNotNil(device["runtime"],   "Missing 'runtime'")
            XCTAssertNotNil(device["available"], "Missing 'available'")
        }
    }

    func test_deviceList_prettyFlag_producesFormattedJSON() {
        let plain  = iosdevctl("device", "list")
        let pretty = iosdevctl("device", "list", "--pretty")
        // Pretty output contains newlines; plain does not (it's a single line)
        XCTAssertTrue(pretty.stdout.contains("\n"))
        XCTAssertFalse(plain.stdout.contains("\n"))
    }

    // MARK: - device boot — unknown device

    func test_deviceBoot_unknownDevice_returnsErrorJSON() {
        let result = iosdevctl("device", "boot", "--device", "NonExistentDevice-XYZ")
        XCTAssertNotEqual(result.exitCode, 0)
        guard let json = result.jsonDict else {
            return XCTFail("Expected JSON error object, got: \(result.stdout)")
        }
        XCTAssertEqual(json["status"] as? String, "error")
        XCTAssertNotNil(json["code"])
        XCTAssertNotNil(json["message"])
    }

    // MARK: - device screenshot — no booted device

    func test_deviceScreenshot_noBootedDevice_exits4() {
        // Only run this assertion when nothing is booted
        let devices = iosdevctl("device", "list").jsonArray ?? []
        let hasBooted = devices.contains { ($0["state"] as? String) == "Booted" }
        guard !hasBooted else { return }

        let result = iosdevctl("device", "screenshot", "--output", "/tmp/test-shot.png")
        XCTAssertEqual(result.exitCode, 4)
        XCTAssertEqual(result.jsonDict?["status"] as? String, "error")
    }
}
