import Foundation
import XCTest

// MARK: - CLI runner

struct CLIResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    var json: Any? {
        guard let data = stdout.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    var jsonDict: [String: Any]? { json as? [String: Any] }
    var jsonArray: [[String: Any]]? { json as? [[String: Any]] }
}

/// Runs the iosdevctl binary with the given arguments.
/// SPM sets the working directory to the package root, so the debug binary is at .build/debug/iosdevctl.
@discardableResult
func iosdevctl(_ args: String...) -> CLIResult {
    let binaryPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // iosdevctlTests/
        .deletingLastPathComponent()   // Tests/
        .deletingLastPathComponent()   // package root
        .appendingPathComponent(".build/debug/iosdevctl")
        .path

    let process = Process()
    process.executableURL = URL(fileURLWithPath: binaryPath)
    process.arguments = args

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try? process.run()
    process.waitUntilExit()

    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    return CLIResult(
        stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
        stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines),
        exitCode: process.terminationStatus
    )
}

/// Pipes input into iosdevctl mcp serve and returns the response line.
func mcpRequest(_ jsonLine: String) -> CLIResult {
    let binaryPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent(".build/debug/iosdevctl")
        .path

    let process = Process()
    process.executableURL = URL(fileURLWithPath: binaryPath)
    process.arguments = ["mcp", "serve"]

    let stdinPipe = Pipe()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardInput = stdinPipe
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try? process.run()
    let inputData = (jsonLine + "\n").data(using: .utf8)!
    stdinPipe.fileHandleForWriting.write(inputData)
    stdinPipe.fileHandleForWriting.closeFile()
    process.waitUntilExit()

    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    return CLIResult(
        stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
        stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines),
        exitCode: process.terminationStatus
    )
}
