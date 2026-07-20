import XCTest
@testable import iosdevctl

/// Unit tests for DeviceResolver.runtimeName(from:) — the parser that turns a
/// CoreSimulator runtime key ("com.apple.CoreSimulator.SimRuntime.iOS-17-0")
/// into the human/agent-facing string ("iOS 17.0") shown on every `device list`.
///
/// These run in-process (no simulator, no xcrun) and pin the current parsing
/// contract, including its fallback behaviour for non-standard keys.
final class RuntimeNameTests: XCTestCase {

    private func name(_ key: String) -> String {
        DeviceResolver.runtimeName(from: key)
    }

    // MARK: - Standard platform-major-minor keys

    func test_iOS_standardKey_formatsWithDottedVersion() {
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.iOS-17-0"), "iOS 17.0")
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.iOS-17-5"), "iOS 17.5")
    }

    func test_watchOS_standardKey_formats() {
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.watchOS-10-5"), "watchOS 10.5")
    }

    func test_tvOS_standardKey_formats() {
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.tvOS-17-4"), "tvOS 17.4")
    }

    func test_xrOS_standardKey_formats() {
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.xrOS-2-0"), "xrOS 2.0")
    }

    // MARK: - Prefix handling

    func test_keyWithoutSimRuntimePrefix_stillParses() {
        // A bare key with no CoreSimulator prefix is parsed on its dashes as-is.
        XCTAssertEqual(name("iOS-17-0"), "iOS 17.0")
    }

    // MARK: - Fallback behaviour for non-standard shapes

    func test_twoComponentKey_fallsBackToDashReplacement() {
        // Only major present (no minor) → dash-replacement fallback, not dotted.
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.iOS-17"), "iOS 17")
    }

    func test_singleTokenKey_returnedUnchanged() {
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.CustomRuntime"), "CustomRuntime")
    }

    func test_fourComponentKey_fallsBackToDashReplacement() {
        // e.g. a beta/patch-tagged key: no dotted collapse, every dash becomes a space.
        XCTAssertEqual(name("com.apple.CoreSimulator.SimRuntime.iOS-17-0-beta"), "iOS 17 0 beta")
    }
}
