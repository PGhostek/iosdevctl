import ArgumentParser
import Foundation

struct AppCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app",
        abstract: "Manage apps on simulators.",
        subcommands: [
            AppInstall.self,
            AppLaunch.self,
            AppTerminate.self,
            AppList.self
        ]
    )
}

// MARK: - app install

struct AppInstall: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install an app on a simulator."
    )

    @Option(name: .long, help: "Path to .app or .ipa file.")
    var path: String

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

        guard FileManager.default.fileExists(atPath: path) else {
            Output.error(
                code: "FILE_NOT_FOUND",
                message: "App file not found at path: \(path)",
                suggestion: "Ensure the path points to a valid .app or .ipa file."
            )
        }

        let result = xcrun(["install", sim.udid, path])
        if !result.succeeded {
            Output.error(
                code: "INSTALL_FAILED",
                message: result.stderr.isEmpty ? "Failed to install app." : result.stderr,
                suggestion: "Ensure the app is built for the simulator architecture."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "App installed successfully.",
            "path": path,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - app launch

struct AppLaunch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "launch",
        abstract: "Launch an app on a simulator."
    )

    @Argument(help: "Bundle identifier of the app to launch.")
    var bundleId: String

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

        let result = xcrun(["launch", sim.udid, bundleId])
        if !result.succeeded {
            let stderr = result.stderr.lowercased()
            if stderr.contains("unable to find") || stderr.contains("no such") {
                Output.error(
                    code: "APP_NOT_FOUND",
                    message: "App with bundle ID \"\(bundleId)\" not found on device \"\(sim.name)\".",
                    suggestion: "Install the app first with: iosdevctl app install --path <path>",
                    exitCode: 3
                )
            }
            Output.error(
                code: "LAUNCH_FAILED",
                message: result.stderr.isEmpty ? "Failed to launch app." : result.stderr,
                suggestion: "Ensure the app is installed on the simulator."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "App launched successfully.",
            "bundleId": bundleId,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - app terminate

struct AppTerminate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "terminate",
        abstract: "Terminate a running app on a simulator."
    )

    @Argument(help: "Bundle identifier of the app to terminate.")
    var bundleId: String

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

        let result = xcrun(["terminate", sim.udid, bundleId])
        if !result.succeeded {
            let stderr = result.stderr.lowercased()
            if stderr.contains("unable to find") || stderr.contains("no such") || stderr.contains("not running") {
                Output.error(
                    code: "APP_NOT_FOUND",
                    message: "App with bundle ID \"\(bundleId)\" is not running on device \"\(sim.name)\".",
                    suggestion: "Launch the app first with: iosdevctl app launch \(bundleId)",
                    exitCode: 3
                )
            }
            Output.error(
                code: "TERMINATE_FAILED",
                message: result.stderr.isEmpty ? "Failed to terminate app." : result.stderr,
                suggestion: "Ensure the app is running on the simulator."
            )
        }

        let payload: [String: Any] = [
            "status": "ok",
            "message": "App terminated successfully.",
            "bundleId": bundleId,
            "device": sim.name,
            "udid": sim.udid
        ]
        Output.success(payload, pretty: pretty)
    }
}

// MARK: - app list

struct AppList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed apps on a simulator."
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

        let result = xcrun(["listapps", sim.udid])
        if !result.succeeded {
            Output.error(
                code: "LIST_FAILED",
                message: result.stderr.isEmpty ? "Failed to list apps." : result.stderr,
                suggestion: "Ensure the simulator is booted."
            )
        }

        guard let data = result.stdout.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let appsDict = plist as? [String: [String: Any]] else {
            Output.error(
                code: "PARSE_FAILED",
                message: "Failed to parse app list output.",
                suggestion: "Ensure Xcode command line tools are up to date."
            )
        }

        let apps: [[String: Any]] = appsDict.map { (bundleId, info) in
            var app: [String: Any] = ["bundleId": bundleId]
            if let name = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String {
                app["name"] = name
            } else {
                app["name"] = bundleId
            }
            if let version = info["CFBundleShortVersionString"] as? String {
                app["version"] = version
            } else {
                app["version"] = ""
            }
            if let path = info["Bundle"] as? String {
                app["path"] = path
            } else {
                app["path"] = ""
            }
            return app
        }.sorted { ($0["bundleId"] as? String ?? "") < ($1["bundleId"] as? String ?? "") }

        Output.success(apps, pretty: pretty)
    }
}
