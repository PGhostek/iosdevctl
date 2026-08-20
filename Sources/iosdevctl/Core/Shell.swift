import Foundation

struct ShellResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    var succeeded: Bool { exitCode == 0 }
}

/// Raw, untrimmed output of a finished child process.
struct ProcessOutput {
    let stdout: Data
    let stderr: Data
    let exitCode: Int32
}

/// Launches `executable` with `arguments` and returns everything it wrote.
///
/// Both pipes are drained concurrently BEFORE waiting for exit. Reading only
/// after `waitUntilExit()` deadlocks as soon as the child writes more than the
/// OS pipe buffer (~64 KB): the child blocks writing into a full pipe while we
/// block waiting for it to exit, and nobody drains. `simctl listapps`,
/// `simctl list devices --json` and an `iosdevctl ui tree` dump all get there.
///
/// Throws only if the process could not be launched at all.
func captureProcessOutput(executable: String, arguments: [String]) throws -> ProcessOutput {
    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()

    var stdoutData = Data()
    var stderrData = Data()
    let drainGroup = DispatchGroup()
    let drainQueue = DispatchQueue(label: "iosdevctl.shell.drain", attributes: .concurrent)

    drainQueue.async(group: drainGroup) {
        stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    }
    drainQueue.async(group: drainGroup) {
        stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    }

    drainGroup.wait()
    process.waitUntilExit()

    return ProcessOutput(stdout: stdoutData, stderr: stderrData, exitCode: process.terminationStatus)
}

func runCommand(_ args: [String]) -> ShellResult {
    do {
        let output = try captureProcessOutput(executable: "/usr/bin/env", arguments: args)
        let stdout = String(data: output.stdout, encoding: .utf8) ?? ""
        let stderr = String(data: output.stderr, encoding: .utf8) ?? ""
        return ShellResult(
            stdout: stdout.trimmingCharacters(in: .newlines),
            stderr: stderr.trimmingCharacters(in: .newlines),
            exitCode: output.exitCode
        )
    } catch {
        return ShellResult(stdout: "", stderr: error.localizedDescription, exitCode: 1)
    }
}

@discardableResult
func xcrun(_ args: [String]) -> ShellResult {
    return runCommand(["xcrun", "simctl"] + args)
}
