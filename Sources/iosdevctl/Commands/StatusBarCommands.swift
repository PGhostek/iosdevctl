import ArgumentParser
import Foundation

struct StatusBarCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status-bar",
        abstract: "Override or clear the simulator status bar.",
        subcommands: [
            StatusBarOverride.self,
            StatusBarClear.self
        ]
    )
}

struct StatusBarOverride: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "override",
        abstract: "Override status bar properties for clean screenshots."
    )

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    @Option(name: .long, help: "Time to display (e.g. \"9:41\").")
    var time: String?

    @Option(name: .long, help: "Battery level (0-100).")
    var batteryLevel: Int?

    @Option(name: .long, help: "Battery state (charging, charged, discharging).")
    var batteryState: String?

    @Option(name: .long, help: "Network type (wifi, lte, 4g, 3g, 2g, edge, gprs, none).")
    var network: String?

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

        var args = ["status_bar", sim.udid, "override"]

        if let time = time {
            args += ["--time", time]
        }

        if let batteryLevel = batteryLevel {
            guard batteryLevel >= 0 && batteryLevel <= 100 else {
                Output.error(
                    code: "INVALID_ARGUMENT",
                    message: "Battery level must be between 0 and 100.",
                    suggestion: "Provide a value like --battery-level 85"
                )
            }
            args += ["--batteryLevel", "\(batteryLevel)"]
        }

        if let batteryState = batteryState {
            let validStates = ["charging", "charged", "discharging"]
            guard validStates.contains(batteryState.lowercased()) else {
                Output.error(
                    code: "INVALID_ARGUMENT",
                    message: "Battery state must be one of: \(validStates.joined(separator: ", ")).",
                    suggestion: "Provide a value like --battery-state charging"
                )
            }
            args += ["--batteryState", batteryState]
        }

        if let network = network {
            let validNetworks = ["wifi", "lte", "4g", "3g", "2g", "edge", "gprs", "none"]
            guard validNetworks.contains(network.lowercased()) else {
                Output.error(
                    code: "INVALID_ARGUMENT",
                    message: "Network must be one of: \(validNetworks.joined(separator: ", ")).",
                    suggestion: "Provide a value like --network wifi"
                )
            }
            args += ["--dataNetwork", network]
        }

        let result = xcrun(args)
        if !result.succeeded {
            Output.error(
                code: "STATUS_BAR_FAILED",
                message: result.stderr.isEmpty ? "Failed to override status bar." : result.stderr,
                suggestion: "Ensure the simulator is booted."
            )
        }

        var overrides: [String: Any] = [:]
        if let time = time { overrides["time"] = time }
        if let batteryLevel = batteryLevel { overrides["batteryLevel"] = batteryLevel }
        if let batteryState = batteryState { overrides["batteryState"] = batteryState }
        if let network = network { overrides["network"] = network }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Status bar overridden successfully.",
            "overrides": overrides,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

struct StatusBarClear: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Clear status bar overrides and restore defaults."
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

        let result = xcrun(["status_bar", sim.udid, "clear"])
        if !result.succeeded {
            Output.error(
                code: "STATUS_BAR_CLEAR_FAILED",
                message: result.stderr.isEmpty ? "Failed to clear status bar overrides." : result.stderr,
                suggestion: "Ensure the simulator is booted."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "Status bar overrides cleared.",
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}
