import ArgumentParser
import Foundation

struct DeviceCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "device",
        abstract: "Manage iOS simulators.",
        subcommands: [
            DeviceList.self,
            DeviceBoot.self,
            DeviceShutdown.self,
            DeviceScreenshot.self,
            DeviceRecord.self
        ]
    )
}

// MARK: - device list

struct DeviceList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available simulators."
    )

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let devices = DeviceResolver.listAll()
        let output = devices.map { $0.toDictionary() }
        Output.success(output, pretty: pretty)
    }
}

// MARK: - device boot

struct DeviceBoot: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "boot",
        abstract: "Boot a simulator."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)

        if sim.isBooted {
            let payload: [String: Any] = [
                "status": "ok",
                "message": "Device already booted.",
                "udid": sim.udid,
                "name": sim.name
            ]
            Output.success(payload, pretty: pretty)
        }

        let result = xcrun(["boot", sim.udid])
        if !result.succeeded {
            Output.error(
                code: "BOOT_FAILED",
                message: result.stderr.isEmpty ? "Failed to boot device." : result.stderr,
                suggestion: "Ensure the simulator is available and Xcode is installed."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Device booted successfully.",
            "udid": sim.udid,
            "name": sim.name
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - device shutdown

struct DeviceShutdown: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shutdown",
        abstract: "Shutdown a simulator."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)

        if sim.state == "Shutdown" {
            let payload: [String: Any] = [
                "status": "ok",
                "message": "Device already shut down.",
                "udid": sim.udid,
                "name": sim.name
            ]
            Output.success(payload, pretty: pretty)
        }

        let result = xcrun(["shutdown", sim.udid])
        if !result.succeeded {
            Output.error(
                code: "SHUTDOWN_FAILED",
                message: result.stderr.isEmpty ? "Failed to shut down device." : result.stderr,
                suggestion: "Ensure the device is booted and Xcode is installed."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Device shut down successfully.",
            "udid": sim.udid,
            "name": sim.name
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - device screenshot

struct DeviceScreenshot: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Take a screenshot of a simulator."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Option(name: .long, help: "Output file path (default: /tmp/iosdevctl-screenshot-<timestamp>.png).")
    var output: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)

        if !sim.isBooted {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device \"\(sim.name)\" (\(sim.udid)) is not booted.",
                suggestion: "Boot it first with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let outputPath = output ?? "/tmp/iosdevctl-screenshot-\(timestamp).png"

        let result = xcrun(["io", sim.udid, "screenshot", outputPath])
        if !result.succeeded {
            Output.error(
                code: "SCREENSHOT_FAILED",
                message: result.stderr.isEmpty ? "Failed to take screenshot." : result.stderr,
                suggestion: "Ensure the simulator is booted and the output path is writable."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "path": outputPath,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - device record

struct DeviceRecord: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "record",
        abstract: "Record simulator screen.",
        subcommands: [
            DeviceRecordStart.self,
            DeviceRecordStop.self
        ]
    )
}

let recordingPidFile = "/tmp/iosdevctl-recording.pid"

struct DeviceRecordStart: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start screen recording."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Option(name: .long, help: "Output file path.")
    var output: String

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sim = DeviceResolver.resolve(identifier: device)

        if !sim.isBooted {
            Output.error(
                code: "DEVICE_NOT_BOOTED",
                message: "Device \"\(sim.name)\" (\(sim.udid)) is not booted.",
                suggestion: "Boot it first with: iosdevctl device boot --device \"\(sim.name)\"",
                exitCode: 4
            )
        }

        // Check if a recording is already in progress
        if let existingPid = readPidFile() {
            Output.error(
                code: "RECORDING_ALREADY_IN_PROGRESS",
                message: "A recording is already in progress (PID \(existingPid)).",
                suggestion: "Stop the current recording with: iosdevctl device record stop"
            )
        }

        // Launch xcrun simctl io <udid> recordVideo <path> as a background process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "io", sim.udid, "recordVideo", "--force", output]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            Output.error(
                code: "RECORD_FAILED",
                message: "Failed to start recording: \(error.localizedDescription)",
                suggestion: "Ensure the simulator is booted and the output path is writable."
            )
        }

        let pid = process.processIdentifier
        writePidFile(pid: pid)

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Recording started.",
            "pid": pid,
            "output": output,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

struct DeviceRecordStop: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop screen recording."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        guard let pid = readPidFile() else {
            Output.error(
                code: "NO_RECORDING_IN_PROGRESS",
                message: "No recording is currently in progress.",
                suggestion: "Start a recording with: iosdevctl device record start --output <path>"
            )
        }

        // Send SIGINT to gracefully stop the recording (allows the video to be finalized)
        let result = runCommand(["kill", "-SIGINT", "\(pid)"])
        deletePidFile()

        if !result.succeeded && result.exitCode != 1 {
            // Exit code 1 from kill means process not found — already stopped
            Output.error(
                code: "STOP_FAILED",
                message: "Failed to stop recording process (PID \(pid)).",
                suggestion: "The process may have already terminated."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Recording stopped.",
            "pid": pid
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - PID file helpers

private func readPidFile() -> Int32? {
    guard let content = try? String(contentsOfFile: recordingPidFile, encoding: .utf8),
          let pid = Int32(content.trimmingCharacters(in: .whitespacesAndNewlines)) else {
        return nil
    }
    return pid
}

private func writePidFile(pid: Int32) {
    try? "\(pid)".write(toFile: recordingPidFile, atomically: true, encoding: .utf8)
}

private func deletePidFile() {
    try? FileManager.default.removeItem(atPath: recordingPidFile)
}
