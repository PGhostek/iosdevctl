import ArgumentParser
import Foundation

struct PasteboardCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pasteboard",
        abstract: "Read and write the simulator pasteboard.",
        subcommands: [
            PasteboardGet.self,
            PasteboardSet.self
        ]
    )
}

struct PasteboardGet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get the current pasteboard content."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

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

        let result = xcrun(["pbpaste", sim.udid])
        if !result.succeeded {
            Output.error(
                code: "PASTEBOARD_GET_FAILED",
                message: result.stderr.isEmpty ? "Failed to get pasteboard content." : result.stderr,
                suggestion: "Ensure the simulator is booted."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "content": result.stdout,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

struct PasteboardSet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set the pasteboard content."
    )

    @Argument(help: "Content to set on the pasteboard.")
    var content: String

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

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

        // xcrun simctl pbcopy <udid> reads from stdin
        let process = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "pbcopy", sim.udid]
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            Output.error(
                code: "PASTEBOARD_SET_FAILED",
                message: "Failed to start pbcopy process: \(error.localizedDescription)",
                suggestion: "Ensure the simulator is booted."
            )
        }

        if let data = content.data(using: .utf8) {
            stdinPipe.fileHandleForWriting.write(data)
        }
        stdinPipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            Output.error(
                code: "PASTEBOARD_SET_FAILED",
                message: stderr.isEmpty ? "Failed to set pasteboard content." : stderr,
                suggestion: "Ensure the simulator is booted."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Pasteboard updated successfully.",
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}
