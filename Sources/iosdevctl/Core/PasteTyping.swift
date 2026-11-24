import Foundation

struct PasteFailure {
    let code: String
    let message: String
    let suggestion: String?
}

/// `ui type --paste` runs two steps — `simctl pbcopy` then Cmd+V via System
/// Events — and either can fail without anything visible on screen. Pure so the
/// verdict is unit-testable without a simulator or a TCC prompt.
enum PasteTyping {
    /// `keystroke` is nil when the Cmd+V step hasn't run yet.
    static func failure(pbcopy: ShellResult, keystroke: ShellResult?) -> PasteFailure? {
        if !pbcopy.succeeded {
            return PasteFailure(
                code: "TYPE_FAILED",
                message: "Failed to set simulator pasteboard: "
                    + (pbcopy.stderr.isEmpty ? "simctl pbcopy exited \(pbcopy.exitCode)." : pbcopy.stderr),
                suggestion: "Ensure the simulator is booted, or retry without --paste."
            )
        }
        guard let keystroke, !keystroke.succeeded else { return nil }

        // osascript error 1002 / "not allowed to send keystrokes" = the host
        // process (Terminal, Claude, the MCP client) lacks Accessibility in TCC.
        let err = keystroke.stderr
        if err.contains("(1002)") || err.localizedCaseInsensitiveContains("not allowed to send keystrokes") {
            return PasteFailure(
                code: "ACCESSIBILITY_DENIED",
                message: "Cmd+V was blocked: \(err)",
                suggestion: "Grant Accessibility to the app running iosdevctl (System Settings › Privacy & Security › Accessibility). "
                    + "The text is already on the simulator pasteboard; or retry without --paste."
            )
        }
        return PasteFailure(
            code: "TYPE_FAILED",
            message: "Failed to send Cmd+V to Simulator: "
                + (err.isEmpty ? "osascript exited \(keystroke.exitCode)." : err),
            suggestion: "Ensure Simulator.app is running, or retry without --paste."
        )
    }
}
