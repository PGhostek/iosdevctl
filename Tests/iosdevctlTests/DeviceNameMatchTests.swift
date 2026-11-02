import XCTest
@testable import iosdevctl

/// `--device <name>` resolution. `listAll()` is built by iterating a Dictionary,
/// whose order Swift reseeds every process — so when two runtimes both carry an
/// available "iPhone 17", the old first-match picked a random OS per invocation.
final class DeviceNameMatchTests: XCTestCase {

    private func dev(_ udid: String, _ name: String, runtime: String,
                     state: String = "Shutdown", available: Bool = true) -> SimulatorDevice {
        SimulatorDevice(udid: udid, name: name, state: state, runtime: runtime, available: available)
    }

    private func match(_ name: String, _ devices: [SimulatorDevice]) -> String? {
        DeviceResolver.match(name: name, in: devices)?.udid
    }

    func test_sameNameOnTwoAvailableRuntimes_picksNewestRegardlessOfOrder() {
        let old = dev("OLD", "iPhone 17", runtime: "iOS 26.5")
        let new = dev("NEW", "iPhone 17", runtime: "iOS 27.0")
        XCTAssertEqual(match("iPhone 17", [old, new]), "NEW")
        XCTAssertEqual(match("iPhone 17", [new, old]), "NEW")
    }

    func test_newestRuntime_comparesVersionsNumerically() {
        let nine = dev("NINE", "iPhone X", runtime: "iOS 9.3")
        let ten = dev("TEN", "iPhone X", runtime: "iOS 10.0")
        XCTAssertEqual(match("iPhone X", [nine, ten]), "TEN")
        XCTAssertEqual(match("iPhone X", [ten, nine]), "TEN")
    }

    func test_bootedBeatsNewerRuntime() {
        let oldBooted = dev("OLD", "iPhone 17", runtime: "iOS 26.5", state: "Booted")
        let new = dev("NEW", "iPhone 17", runtime: "iOS 27.0")
        XCTAssertEqual(match("iPhone 17", [new, oldBooted]), "OLD")
    }

    func test_availableBeatsNewerUnavailable() {
        let old = dev("OLD", "iPhone 17", runtime: "iOS 26.5")
        let newGone = dev("NEW", "iPhone 17", runtime: "iOS 27.0", available: false)
        XCTAssertEqual(match("iPhone 17", [newGone, old]), "OLD")
    }

    func test_onlyUnavailable_stillReturnsNewest() {
        let a = dev("A", "iPad", runtime: "iOS 26.5", available: false)
        let b = dev("B", "iPad", runtime: "iOS 27.0", available: false)
        XCTAssertEqual(match("iPad", [a, b]), "B")
    }

    func test_caseInsensitive_andNoMatchIsNil() {
        let d = dev("D", "iPhone Air", runtime: "iOS 27.0")
        XCTAssertEqual(match("iphone air", [d]), "D")
        XCTAssertNil(match("iPhone", [d]))
    }
}
