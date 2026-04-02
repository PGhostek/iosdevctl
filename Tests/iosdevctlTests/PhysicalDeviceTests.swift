import XCTest

/// Tests for Phase 6a — physical device support.
/// Hardware-gated tests require IOSDEVCTL_PHYSICAL_UDID env var to be set.
final class PhysicalDeviceTests: XCTestCase {

    private var physicalUDID: String? {
        ProcessInfo.processInfo.environment["IOSDEVCTL_PHYSICAL_UDID"]
    }

    // MARK: - device list (no hardware required)

    func test_deviceList_hasKindField_onAllDevices() {
        let result = iosdevctl("device", "list")
        XCTAssertEqual(result.exitCode, 0)
        guard let devices = result.jsonArray else {
            return XCTFail("Expected JSON array, got: \(result.stdout)")
        }
        for device in devices {
            let kind = device["kind"] as? String
            XCTAssertTrue(kind == "simulator" || kind == "physical",
                          "Device missing valid 'kind' field: \(device)")
        }
    }

    // MARK: - Physical device tests (require IOSDEVCTL_PHYSICAL_UDID)

    func test_deviceList_includesPhysicalDevice() {
        guard let udid = physicalUDID else { return }
        let result = iosdevctl("device", "list")
        guard let devices = result.jsonArray else { return XCTFail("Expected JSON array") }
        let udids = devices.compactMap { $0["udid"] as? String }
        XCTAssertTrue(udids.contains(udid), "Physical device \(udid) not found in device list")
        let physical = devices.first { $0["udid"] as? String == udid }
        XCTAssertEqual(physical?["kind"] as? String, "physical")
        XCTAssertEqual(physical?["state"] as? String, "Connected")
    }

    func test_deviceBoot_physicalDevice_returnsNotApplicableError() {
        guard let udid = physicalUDID else { return }
        let result = iosdevctl("device", "boot", "--device", udid)
        XCTAssertNotEqual(result.exitCode, 0)
        let json = result.jsonDict ?? result.stderrJsonDict
        XCTAssertEqual(json?["code"] as? String, "NOT_APPLICABLE_FOR_PHYSICAL")
    }

    func test_deviceShutdown_physicalDevice_returnsNotApplicableError() {
        guard let udid = physicalUDID else { return }
        let result = iosdevctl("device", "shutdown", "--device", udid)
        XCTAssertNotEqual(result.exitCode, 0)
        let json = result.jsonDict ?? result.stderrJsonDict
        XCTAssertEqual(json?["code"] as? String, "NOT_APPLICABLE_FOR_PHYSICAL")
    }

    func test_deviceScreenshot_physicalDevice_savesFile() {
        guard let udid = physicalUDID else { return }
        let path = "/tmp/test-physical-screenshot-\(Int(Date().timeIntervalSince1970)).png"
        let result = iosdevctl("device", "screenshot", "--device", udid, "--output", path)
        XCTAssertEqual(result.exitCode, 0, "Screenshot failed: \(result.stderr)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), "Screenshot file not created at \(path)")
        try? FileManager.default.removeItem(atPath: path)
    }

    func test_appList_physicalDevice_returnsJSONArray() {
        guard let udid = physicalUDID else { return }
        let result = iosdevctl("app", "list", "--device", udid)
        XCTAssertEqual(result.exitCode, 0, "app list failed: \(result.stderr)")
        guard let apps = result.jsonArray else {
            return XCTFail("Expected JSON array, got: \(result.stdout)")
        }
        for app in apps {
            XCTAssertNotNil(app["bundleId"], "App missing bundleId: \(app)")
            XCTAssertNotNil(app["name"], "App missing name: \(app)")
        }
    }
}
