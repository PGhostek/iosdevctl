import Foundation

struct ShellResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    var succeeded: Bool { exitCode == 0 }
}

func runCommand(_ args: [String]) -> ShellResult {
    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = args
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
        try process.run()
    } catch {
        return ShellResult(stdout: "", stderr: error.localizedDescription, exitCode: 1)
    }

    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8) ?? ""

    return ShellResult(
        stdout: stdout.trimmingCharacters(in: .newlines),
        stderr: stderr.trimmingCharacters(in: .newlines),
        exitCode: process.terminationStatus
    )
}

@discardableResult
func xcrun(_ args: [String]) -> ShellResult {
    return runCommand(["xcrun", "simctl"] + args)
}

@discardableResult
func devicectl(_ args: [String]) -> ShellResult {
    return runCommand(["xcrun", "devicectl"] + args)
}
