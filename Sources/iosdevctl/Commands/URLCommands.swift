import ArgumentParser
import Foundation

struct URLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "url",
        abstract: "Open URLs and deep links on simulators.",
        subcommands: [URLOpen.self]
    )
}

struct URLOpen: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "Open a URL or deep link on a simulator."
    )

    @Argument(help: "URL or deep link to open.")
    var url: String

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

        let result = xcrun(["openurl", sim.udid, url])
        if !result.succeeded {
            Output.error(
                code: "URL_OPEN_FAILED",
                message: result.stderr.isEmpty ? "Failed to open URL." : result.stderr,
                suggestion: "Ensure the URL is valid and any required app for the URL scheme is installed."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "URL opened successfully.",
            "url": url,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}
