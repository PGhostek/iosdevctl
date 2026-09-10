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

        // Check if a recording is already in progress (stale pid files are cleared here)
        if let existingPid = RecordingRegistry.activePid() {
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
        RecordingRegistry.writePid(pid)
        RecordingRegistry.writePath(output)

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
        guard let pid = RecordingRegistry.activePid() else {
            Output.error(
                code: "NO_RECORDING_IN_PROGRESS",
                message: "No recording is currently in progress.",
                suggestion: "Start a recording with: iosdevctl device record start --output <path>"
            )
        }

        // Send SIGINT to gracefully stop the recording (allows the video to be finalized)
        let savedPath = RecordingRegistry.readPath()
        let result = runCommand(["kill", "-SIGINT", "\(pid)"])
        RecordingRegistry.clear()

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

// MARK: - Recording registry

/// Tracks the in-flight `simctl io … recordVideo` child across CLI invocations.
///
/// The pid file used to be trusted on sight: `record start` refused to run
/// whenever the file existed, and `record stop` SIGINT'd whatever number it
/// held. Nothing removed the file except a successful `stop`, so an interrupted
/// agent run — or the simulator shutting down, which makes simctl exit on its
/// own — left it behind indefinitely: `record start` then answered
/// RECORDING_ALREADY_IN_PROGRESS forever, and the documented remedy
/// (`record stop`) fired SIGINT at a PID macOS had long since recycled onto an
/// unrelated process, then reported "Recording stopped."
///
/// So the pid file is now only believed when the PID is still alive AND the
/// process is recognisably the recording we started.
enum RecordingRegistry {
    static var pidFilePath  = defaultPidFilePath
    static var pathFilePath = defaultPathFilePath

    static let defaultPidFilePath  = "/tmp/iosdevctl-recording.pid"
    static let defaultPathFilePath = "/tmp/iosdevctl-recording-path.txt"

    /// Command line of a running process, or nil when the PID is dead.
    /// Injectable so tests don't need a real recording.
    static var commandLineForPid: (Int32) -> String? = defaultCommandLineProbe

    static let defaultCommandLineProbe: (Int32) -> String? = { pid in
        let result = runCommand(["ps", "-p", "\(pid)", "-o", "command="])
        guard result.succeeded else { return nil }
        let line = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return line.isEmpty ? nil : line
    }

    /// A recycled PID is alive but is not ours — signalling it would hit an
    /// innocent process, so require the simctl recording verb in the command line.
    static func isLiveRecording(commandLine: String?) -> Bool {
        guard let commandLine = commandLine else { return false }
        return commandLine.contains("recordVideo")
    }

    /// PID of the recording actually in progress, or nil. Clears stale state on the way.
    static func activePid() -> Int32? {
        guard let pid = readPid() else { return nil }
        guard isLiveRecording(commandLine: commandLineForPid(pid)) else {
            clear()
            return nil
        }
        return pid
    }

    static func readPid() -> Int32? {
        guard let content = try? String(contentsOfFile: pidFilePath, encoding: .utf8),
              let pid = Int32(content.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return pid
    }

    static func writePid(_ pid: Int32) {
        try? "\(pid)".write(toFile: pidFilePath, atomically: true, encoding: .utf8)
    }

    static func readPath() -> String? {
        try? String(contentsOfFile: pathFilePath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func writePath(_ path: String) {
        try? path.write(toFile: pathFilePath, atomically: true, encoding: .utf8)
    }

    static func clear() {
        try? FileManager.default.removeItem(atPath: pidFilePath)
        try? FileManager.default.removeItem(atPath: pathFilePath)
    }

    /// Test hook — restores the real /tmp locations after a test redirects them.
    static func resetPathsToDefaults() {
        pidFilePath  = defaultPidFilePath
        pathFilePath = defaultPathFilePath
    }
}
