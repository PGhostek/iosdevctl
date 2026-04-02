import ArgumentParser
import Foundation

struct DeviceCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "device",
        abstract: "Manage iOS simulators and connected physical devices.",
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
        abstract: "List all available simulators and connected physical devices."
    )

    @Flag(name: .long, help: "Pretty-print JSON output.")
    var pretty: Bool = false

    func run() throws {
        let sims = DeviceResolver.listAll().map { $0.toDictionary() }
        let physical = DeviceResolver.listPhysical().map { $0.toDictionary() }
        Output.success(sims + physical, pretty: pretty)
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
        // Pre-flight: graceful error if this is a physical device
        if let id = device, case .physical = DeviceResolver.resolveAny(identifier: id) {
            Output.error(
                code: "NOT_APPLICABLE_FOR_PHYSICAL",
                message: "device boot is not applicable for physical devices. Physical devices boot themselves when powered on.",
                suggestion: "Use 'iosdevctl device list' to see connected devices.",
                exitCode: 1
            )
        }

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
        // Pre-flight: graceful error if this is a physical device
        if let id = device, case .physical = DeviceResolver.resolveAny(identifier: id) {
            Output.error(
                code: "NOT_APPLICABLE_FOR_PHYSICAL",
                message: "device shutdown is not applicable for physical devices.",
                suggestion: "Power off the device manually or use 'iosdevctl device list' to see device state.",
                exitCode: 1
            )
        }

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
        let deviceKind = DeviceResolver.resolveAny(identifier: device)
        let timestamp = Int(Date().timeIntervalSince1970)
        let outputPath = output ?? "/tmp/iosdevctl-screenshot-\(timestamp).png"

        switch deviceKind {
        case .simulator(let sim):
            if !sim.isBooted {
                Output.error(
                    code: "DEVICE_NOT_BOOTED",
                    message: "Device \"\(sim.name)\" (\(sim.udid)) is not booted.",
                    suggestion: "Boot it first with: iosdevctl device boot --device \"\(sim.name)\"",
                    exitCode: 4
                )
            }
            let result = xcrun(["io", sim.udid, "screenshot", outputPath])
            if !result.succeeded {
                Output.error(
                    code: "SCREENSHOT_FAILED",
                    message: result.stderr.isEmpty ? "Failed to take screenshot." : result.stderr,
                    suggestion: "Ensure the simulator is booted and the output path is writable."
                )
            }

        case .physical(let phys):
            let result = devicectl(["device", "capture", "screenshot",
                                    "--device-id", phys.udid, "--output", outputPath])
            if !result.succeeded {
                Output.error(
                    code: "SCREENSHOT_FAILED",
                    message: result.stderr.isEmpty ? "Failed to take screenshot." : result.stderr,
                    suggestion: "Ensure the device is connected and trusted."
                )
            }
        }

        let payload: [String: Any] = [
            "status": "ok",
            "path": outputPath,
            "device": deviceKind.name,
            "udid": deviceKind.udid
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
        // Pre-flight: graceful error if this is a physical device
        if let id = device, case .physical = DeviceResolver.resolveAny(identifier: id) {
            Output.error(
                code: "NOT_APPLICABLE_FOR_PHYSICAL",
                message: "Screen recording is not supported on physical devices.",
                suggestion: "Recording is currently only available for simulators.",
                exitCode: 1
            )
        }

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
        writePathFile(path: output)

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
        let savedPath = readPathFile()
        let result = runCommand(["kill", "-SIGINT", "\(pid)"])
        deletePidFile()
        deletePathFile()

        if !result.succeeded && result.exitCode != 1 {
            // Exit code 1 from kill means process not found — already stopped
            Output.error(
                code: "STOP_FAILED",
                message: "Failed to stop recording process (PID \(pid)).",
                suggestion: "The process may have already terminated."
            )
        }

        // Wait briefly for simctl to finalize the file
        Thread.sleep(forTimeInterval: 0.5)

        var payload: [String: Any] = [
            "status": "ok",
            "message": "Recording stopped.",
            "pid": pid
        ]
        if let path = savedPath {
            payload["path"] = path
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int {
                payload["size_bytes"] = size
            }
        }
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

private let recordingPathFile = "/tmp/iosdevctl-recording-path.txt"

private func writePathFile(path: String) {
    try? path.write(toFile: recordingPathFile, atomically: true, encoding: .utf8)
}

private func readPathFile() -> String? {
    try? String(contentsOfFile: recordingPathFile, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func deletePathFile() {
    try? FileManager.default.removeItem(atPath: recordingPathFile)
}
