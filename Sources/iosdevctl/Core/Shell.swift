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

    // Drain both pipes concurrently BEFORE waiting for exit. Reading only after
    // waitUntilExit() deadlocks as soon as the child writes more than the OS pipe
    // buffer (~64 KB): the child blocks writing into a full pipe while we block
    // waiting for it to exit. `simctl listapps` and `simctl list devices --json`
    // both get there on a well-stocked Mac.
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
