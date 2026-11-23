import XCTest
@testable import iosdevctl

/// `ui type --paste` = simctl pbcopy + Cmd+V via System Events. Both steps'
/// results used to be ignored, so a pbcopy failure or — the common case — a host
/// process without Accessibility permission still reported "Text pasted." and the
/// agent carried on believing the field was filled.
final class PasteTypingTests: XCTestCase {

    private func ok() -> ShellResult { ShellResult(stdout: "", stderr: "", exitCode: 0) }
    private func fail(_ stderr: String, _ code: Int32 = 1) -> ShellResult {
        ShellResult(stdout: "", stderr: stderr, exitCode: code)
    }

    func test_bothStepsSucceed_noFailure() {
        XCTAssertNil(PasteTyping.failure(pbcopy: ok(), keystroke: ok()))
    }

    func test_pbcopySucceeded_keystrokeNotYetRun_noFailure() {
        XCTAssertNil(PasteTyping.failure(pbcopy: ok(), keystroke: nil))
    }

    func test_pbcopyFails_reportsPasteboardError_withStderr() {
        let f = PasteTyping.failure(pbcopy: fail("Invalid device: ABC"), keystroke: nil)
        XCTAssertEqual(f?.code, "TYPE_FAILED")
        XCTAssertTrue(f?.message.contains("Invalid device: ABC") ?? false)
    }

    func test_pbcopyFailsSilently_stillReportsError() {
        let f = PasteTyping.failure(pbcopy: fail("", 2), keystroke: nil)
        XCTAssertEqual(f?.code, "TYPE_FAILED")
        XCTAssertFalse(f?.message.isEmpty ?? true)
    }

    func test_keystrokeDeniedByAccessibility_pointsAtPermission() {
        let denied = fail("execution error: System Events got an error: osascript is not allowed to send keystrokes. (1002)")
        let f = PasteTyping.failure(pbcopy: ok(), keystroke: denied)
        XCTAssertEqual(f?.code, "ACCESSIBILITY_DENIED")
        XCTAssertTrue(f?.suggestion?.contains("Accessibility") ?? false)
        XCTAssertTrue(f?.suggestion?.contains("pasteboard") ?? false,
                      "text IS on the sim pasteboard — say so, the agent can paste manually")
    }

    func test_keystrokeFailsOtherwise_genericError() {
        let f = PasteTyping.failure(pbcopy: ok(), keystroke: fail("Simulator got an error: Application isn't running."))
        XCTAssertEqual(f?.code, "TYPE_FAILED")
        XCTAssertTrue(f?.message.contains("Application isn't running") ?? false)
    }
}
