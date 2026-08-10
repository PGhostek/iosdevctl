import XCTest
@testable import iosdevctl

/// Regression tests for `runCommand` in Core/Shell.swift.
///
/// The original implementation called `process.waitUntilExit()` and only *then*
/// read both pipes. That deadlocks as soon as the child writes more than the OS
/// pipe buffer (~64 KB): the child blocks writing into a full pipe, the parent
/// blocks waiting for the child to exit, and nobody drains. Every command in the
/// CLI funnels through here (`simctl list devices --json`, `simctl listapps`, …),
/// so a chatty simulator would hang iosdevctl indefinitely with no output.
///
/// These tests run `runCommand` off the main queue with a hard timeout, so a
/// regression shows up as a test failure instead of a hung test suite.
final class ShellTests: XCTestCase {

    /// Bytes to push through each pipe — comfortably above the 64 KB buffer.
    private static let payloadSize = 262_144

    /// Runs `runCommand` on a background queue and fails (rather than hangs)
    /// if it does not return within `seconds`.
    private func runWithTimeout(
        _ args: [String],
        seconds: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ShellResult? {
        let done = expectation(description: "runCommand(\(args)) returned")
        let box = ResultBox()

        DispatchQueue.global(qos: .userInitiated).async {
            let result = runCommand(args)
            box.set(result)
            done.fulfill()
        }

        guard XCTWaiter.wait(for: [done], timeout: seconds) == .completed else {
            XCTFail(
                "runCommand deadlocked (>\(Int(seconds))s) — pipes must be drained before waitUntilExit()",
                file: file,
                line: line
            )
            return nil
        }
        return box.get()
    }

    /// Emits `count` copies of `char` on the given fd (1 = stdout, 2 = stderr)
    /// with no newlines, so the returned string length is exactly `count`.
    private func emitScript(char: String, count: Int, fd: Int) -> String {
        "head -c \(count) /dev/zero | tr '\\0' '\(char)' >&\(fd)"
    }

    func test_runCommand_largeStdout_doesNotDeadlock() {
        let size = Self.payloadSize
        let result = runWithTimeout(["sh", "-c", emitScript(char: "a", count: size, fd: 1)])

        guard let result = result else { return }
        XCTAssertEqual(result.stdout.count, size, "stdout was truncated")
        XCTAssertEqual(result.exitCode, 0)
    }

    func test_runCommand_largeStderr_doesNotDeadlock() {
        let size = Self.payloadSize
        let result = runWithTimeout(["sh", "-c", emitScript(char: "b", count: size, fd: 2)])

        guard let result = result else { return }
        XCTAssertEqual(result.stderr.count, size, "stderr was truncated")
        XCTAssertTrue(result.stdout.isEmpty)
    }

    /// The nastiest case: draining only one pipe still deadlocks on the other.
    func test_runCommand_largeStdoutAndStderr_doesNotDeadlock() {
        let size = Self.payloadSize
        let script = emitScript(char: "a", count: size, fd: 1)
            + "; " + emitScript(char: "b", count: size, fd: 2)
        let result = runWithTimeout(["sh", "-c", script])

        guard let result = result else { return }
        XCTAssertEqual(result.stdout.count, size, "stdout was truncated")
        XCTAssertEqual(result.stderr.count, size, "stderr was truncated")
        XCTAssertEqual(result.exitCode, 0)
    }

    // MARK: - Existing behaviour must survive the fix

    func test_runCommand_trimsTrailingNewlinesAndKeepsExitCode() {
        let result = runWithTimeout(["sh", "-c", "printf 'hello\\n\\n'; exit 3"])

        guard let result = result else { return }
        XCTAssertEqual(result.stdout, "hello")
        XCTAssertEqual(result.exitCode, 3)
        XCTAssertFalse(result.succeeded)
    }

    func test_runCommand_unknownExecutable_returnsErrorResult() {
        let result = runWithTimeout(["iosdevctl-definitely-not-a-real-binary"])

        guard let result = result else { return }
        XCTAssertNotEqual(result.exitCode, 0)
        XCTAssertFalse(result.succeeded)
    }
}

/// Tiny lock-guarded box so the background result crosses queues safely.
private final class ResultBox {
    private let lock = NSLock()
    private var value: ShellResult?

    func set(_ newValue: ShellResult) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }

    func get() -> ShellResult? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
