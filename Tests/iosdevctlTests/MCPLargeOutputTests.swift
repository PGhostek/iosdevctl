import Foundation
import XCTest

/// Regression tests for the MCP server's re-invocation of its own binary
/// (`invokeSubprocess` in Commands/MCPCommand.swift).
///
/// The original implementation called `process.waitUntilExit()` and only *then*
/// read stdout/stderr. That deadlocks as soon as the tool subprocess writes more
/// than the OS pipe buffer (~64 KB): the child blocks writing into a full pipe,
/// the server blocks waiting for the child to exit, and nobody drains. The server
/// then never answers that `tools/call` — no response, no error, no timeout — so
/// the connected agent hangs on its very first `ui_tree` or `agent_context`, which
/// are exactly the calls that dump hundreds of KB of accessibility tree.
///
/// Core/Shell.swift was fixed for the same bug on 2026-08-10; the MCP path carried
/// its own copy of the broken pattern.
final class MCPLargeOutputTests: XCTestCase {

    /// Comfortably past the 64 KB pipe buffer, well under ARG_MAX.
    private static let payloadSize = 120_000

    // MARK: - Draining runner

    /// Pipes one JSON-RPC line into `iosdevctl mcp serve`, draining both output
    /// pipes concurrently so the *test harness* can't deadlock on a large reply.
    /// Returns nil (and fails) if the server does not answer within `seconds`.
    private func mcpRequestDrained(
        _ jsonLine: String,
        seconds: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CLIResult? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: iosdevctlBinaryPath)
        process.arguments = ["mcp", "serve"]

        let stdinPipe = Pipe(), stdoutPipe = Pipe(), stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            XCTFail("Could not launch mcp serve: \(error)", file: file, line: line)
            return nil
        }
        stdinPipe.fileHandleForWriting.write((jsonLine + "\n").data(using: .utf8)!)
        stdinPipe.fileHandleForWriting.closeFile()

        let box = DataBox()
        let drained = expectation(description: "mcp serve answered and exited")
        DispatchQueue.global(qos: .userInitiated).async {
            let out = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let err = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            box.set(out: out, err: err, code: process.terminationStatus)
            drained.fulfill()
        }

        guard XCTWaiter.wait(for: [drained], timeout: seconds) == .completed else {
            process.terminate()
            XCTFail(
                "mcp serve never answered (>\(Int(seconds))s) — the tool subprocess's "
                + "pipes must be drained before waitUntilExit()",
                file: file, line: line
            )
            return nil
        }
        let snapshot = box.get()
        return CLIResult(
            stdout: snapshot.out.trimmingCharacters(in: .whitespacesAndNewlines),
            stderr: snapshot.err.trimmingCharacters(in: .whitespacesAndNewlines),
            exitCode: snapshot.code
        )
    }

    // MARK: - Tests

    /// A tool call whose output exceeds the pipe buffer must still get a response.
    ///
    /// `device boot --device <very long name>` echoes the name back in its
    /// DEVICE_NOT_FOUND message, so it produces a >64 KB reply from the tool
    /// subprocess without needing a booted simulator.
    func test_toolsCall_toolOutputLargerThanPipeBuffer_doesNotDeadlock() {
        let longName = String(repeating: "Z", count: Self.payloadSize)
        let request = requestJSON(toolName: "device_boot", arguments: ["device": longName])

        guard let result = mcpRequestDrained(request) else { return }

        guard let res = result.jsonDict?["result"] as? [String: Any],
              let text = (res["content"] as? [[String: Any]])?.first?["text"] as? String else {
            return XCTFail("Expected a JSON-RPC result, got \(result.stdout.prefix(400))")
        }
        XCTAssertEqual(res["isError"] as? Bool, true, "Unknown device must report isError")
        XCTAssertTrue(
            text.contains(longName),
            "Tool output was truncated at \(text.count) bytes — the full \(Self.payloadSize)-byte "
            + "payload must survive"
        )
    }

    /// The fix must not change small-output behaviour: exit code still drives
    /// `isError`, and stdout is still returned intact.
    func test_toolsCall_smallOutput_stillReturnsToolJSON() {
        let request = requestJSON(toolName: "device_list", arguments: [:])

        guard let result = mcpRequestDrained(request) else { return }

        guard let res = result.jsonDict?["result"] as? [String: Any],
              let text = (res["content"] as? [[String: Any]])?.first?["text"] as? String else {
            return XCTFail("Expected a JSON-RPC result, got \(result.stdout.prefix(400))")
        }
        XCTAssertEqual(res["isError"] as? Bool, false)
        XCTAssertNotNil(
            try? JSONSerialization.jsonObject(with: Data(text.utf8)),
            "device_list content must be the tool's JSON, got: \(text.prefix(200))"
        )
    }

    // MARK: - Helpers

    private func requestJSON(toolName: String, arguments: [String: Any]) -> String {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": ["name": toolName, "arguments": arguments]
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return String(data: data, encoding: .utf8)!
    }
}

/// Lock-guarded box so the drained output crosses queues safely.
private final class DataBox {
    private let lock = NSLock()
    private var out = "", err = "", code: Int32 = -1

    func set(out: Data, err: Data, code: Int32) {
        lock.lock()
        defer { lock.unlock() }
        self.out = String(data: out, encoding: .utf8) ?? ""
        self.err = String(data: err, encoding: .utf8) ?? ""
        self.code = code
    }

    func get() -> (out: String, err: String, code: Int32) {
        lock.lock()
        defer { lock.unlock() }
        return (out, err, code)
    }
}
