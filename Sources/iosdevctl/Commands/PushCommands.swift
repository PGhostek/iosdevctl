import ArgumentParser
import Foundation

struct PushCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "push",
        abstract: "Send push notifications to simulators.",
        subcommands: [PushSend.self]
    )
}

struct PushSend: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a push notification payload to an app."
    )

    @Argument(help: "Bundle identifier of the target app.")
    var bundleId: String

    @Argument(help: "Path to the push notification payload JSON file.")
    var payloadFile: String

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

        guard FileManager.default.fileExists(atPath: payloadFile) else {
            Output.error(
                code: "FILE_NOT_FOUND",
                message: "Payload file not found at path: \(payloadFile)",
                suggestion: "Ensure the path points to a valid JSON push notification payload file."
            )
        }

        let result = xcrun(["push", sim.udid, bundleId, payloadFile])
        if !result.succeeded {
            let stderr = result.stderr.lowercased()
            if stderr.contains("no such") || stderr.contains("not found") {
                Output.error(
                    code: "APP_NOT_FOUND",
                    message: "App with bundle ID \"\(bundleId)\" not found on device \"\(sim.name)\".",
                    suggestion: "Install the app first with: iosdevctl app install --path <path>",
                    exitCode: 3
                )
            }
            Output.error(
                code: "PUSH_FAILED",
                message: result.stderr.isEmpty ? "Failed to send push notification." : result.stderr,
                suggestion: "Ensure the payload file is a valid APNS JSON payload."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Push notification sent successfully.",
            "bundleId": bundleId,
            "payloadFile": payloadFile,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}
