import XCTest
@testable import iosdevctl

/// Unit tests for StatusBarArgs.build — the validator that turns
/// `status-bar override` flags into `simctl status_bar <udid> override` args.
///
/// simctl's accepted values come from `xcrun simctl help status_bar`:
///   --dataNetwork: hide, wifi, 3g, 4g, lte, lte-a, lte+, 5g, 5g+, 5g-uwb, 5g-uc
///   --batteryState: charging, charged, discharging
/// Anything else passes our validation only to fail inside simctl.
final class StatusBarArgsTests: XCTestCase {

    private func build(
        time: String? = nil,
        batteryLevel: Int? = nil,
        batteryState: String? = nil,
        network: String? = nil
    ) -> Result<[String], StatusBarArgs.Invalid> {
        StatusBarArgs.build(time: time, batteryLevel: batteryLevel, batteryState: batteryState, network: network)
    }

    private func invalid(_ result: Result<[String], StatusBarArgs.Invalid>) -> StatusBarArgs.Invalid? {
        if case .failure(let e) = result { return e }
        return nil
    }

    // MARK: - Happy path

    func test_allFlags_mapToSimctlFlagNames() {
        XCTAssertEqual(
            try build(time: "9:41", batteryLevel: 100, batteryState: "charged", network: "wifi").get(),
            ["--time", "9:41", "--batteryLevel", "100", "--batteryState", "charged", "--dataNetwork", "wifi"]
        )
    }

    // MARK: - Network values simctl actually accepts

    func test_network_documentedNone_mapsToSimctlHide() {
        // docs/commands/status-bar.md advertises `--network none`; simctl only knows 'hide'.
        XCTAssertEqual(try build(network: "none").get(), ["--dataNetwork", "hide"])
    }

    func test_network_simctlValuesPreviouslyRejected_areAccepted() {
        for value in ["hide", "5g", "5g+", "5g-uwb", "5g-uc", "lte-a", "lte+"] {
            XCTAssertEqual(try build(network: value).get(), ["--dataNetwork", value], value)
        }
    }

    func test_network_valuesSimctlRejects_failValidationUpFront() {
        for value in ["2g", "edge", "gprs", "satellite"] {
            XCTAssertNotNil(invalid(build(network: value)), "\(value) should be rejected before calling simctl")
        }
    }

    // MARK: - Case: validation was case-insensitive but passed the raw value on

    func test_mixedCaseValues_areLowercasedBeforeReachingSimctl() {
        XCTAssertEqual(
            try build(batteryState: "Charging", network: "WiFi").get(),
            ["--batteryState", "charging", "--dataNetwork", "wifi"]
        )
    }

    // MARK: - Other validation

    func test_batteryLevel_outOfRange_isRejected() {
        XCTAssertNotNil(invalid(build(batteryLevel: 101)))
        XCTAssertNotNil(invalid(build(batteryLevel: -1)))
        XCTAssertEqual(try build(batteryLevel: 0).get(), ["--batteryLevel", "0"])
    }

    func test_unknownBatteryState_isRejected() {
        XCTAssertNotNil(invalid(build(batteryState: "full")))
    }

    func test_noFlags_isRejected() {
        // simctl requires at least one override flag.
        XCTAssertNotNil(invalid(build()))
    }
}
