import Foundation

struct SimulatorDevice {
    let udid: String
    let name: String
    let state: String
    let runtime: String
    let available: Bool

    var isBooted: Bool { state == "Booted" }

    func toDictionary() -> [String: Any] {
        return [
            "udid": udid,
            "name": name,
            "state": state,
            "runtime": runtime,
            "available": available,
            "kind": "simulator"
        ]
    }
}

struct PhysicalDevice {
    let udid: String
    let name: String
    let modelIdentifier: String  // e.g. "iPhone16,2"
    let osVersion: String        // e.g. "18.3.1"
    let connectionType: String   // "wired" | "wireless"

    func toDictionary() -> [String: Any] {
        return [
            "udid": udid,
            "name": name,
            "state": "Connected",
            "runtime": "iOS \(osVersion)",
            "available": true,
            "kind": "physical",
            "modelIdentifier": modelIdentifier,
            "connectionType": connectionType
        ]
    }
}

enum DeviceKind {
    case simulator(SimulatorDevice)
    case physical(PhysicalDevice)

    var udid: String {
        switch self {
        case .simulator(let d): return d.udid
        case .physical(let d):  return d.udid
        }
    }

    var name: String {
        switch self {
        case .simulator(let d): return d.name
        case .physical(let d):  return d.name
        }
    }

    var isSimulator: Bool {
        if case .simulator = self { return true }
        return false
    }

    var isPhysical: Bool { !isSimulator }

    func toDictionary() -> [String: Any] {
        switch self {
        case .simulator(let d): return d.toDictionary()
        case .physical(let d):  return d.toDictionary()
        }
    }
}

enum DeviceResolver {
    static func listAll() -> [SimulatorDevice] {
        let result = xcrun(["list", "devices", "--json"])
        guard result.succeeded,
              let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devicesMap = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }

        var devices: [SimulatorDevice] = []
        for (runtimeKey, deviceList) in devicesMap {
            let runtimeName = runtimeName(from: runtimeKey)
            for deviceDict in deviceList {
                guard let udid = deviceDict["udid"] as? String,
                      let name = deviceDict["name"] as? String,
                      let state = deviceDict["state"] as? String else {
                    continue
                }
                let available = deviceDict["isAvailable"] as? Bool ?? false
                devices.append(SimulatorDevice(
                    udid: udid,
                    name: name,
                    state: state,
                    runtime: runtimeName,
                    available: available
                ))
            }
        }
        return devices
    }

    static func resolve(identifier: String?) -> SimulatorDevice {
        let all = listAll()

        guard let identifier = identifier, !identifier.isEmpty else {
            // Auto-select single booted simulator
            let booted = all.filter { $0.isBooted }
            if booted.count == 1 {
                return booted[0]
            } else if booted.isEmpty {
                Output.error(
                    code: "DEVICE_NOT_BOOTED",
                    message: "No booted simulators found.",
                    suggestion: "Boot a simulator with: iosdevctl device boot --device \"iPhone 15\"",
                    exitCode: 4
                )
            } else {
                let names = booted.map { "\($0.name) (\($0.udid))" }.joined(separator: ", ")
                Output.error(
                    code: "AMBIGUOUS_DEVICE",
                    message: "Multiple booted simulators found: \(names)",
                    suggestion: "Specify a device with --device <udid-or-name>",
                    exitCode: 1
                )
            }
        }

        // Check if it looks like a UUID
        let uuidPattern = #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#
        if identifier.range(of: uuidPattern, options: .regularExpression) != nil {
            if let device = all.first(where: { $0.udid.lowercased() == identifier.lowercased() }) {
                return device
            }
            Output.error(
                code: "DEVICE_NOT_FOUND",
                message: "No simulator found with UDID: \(identifier)",
                suggestion: "Run 'iosdevctl device list' to see available simulators.",
                exitCode: 2
            )
        }

        // Match by name — prefer booted, then first available
        let nameMatches = all.filter { $0.name.lowercased() == identifier.lowercased() }
        if let booted = nameMatches.first(where: { $0.isBooted }) {
            return booted
        }
        if let available = nameMatches.first(where: { $0.available }) {
            return available
        }
        if let any = nameMatches.first {
            return any
        }

        Output.error(
            code: "DEVICE_NOT_FOUND",
            message: "No simulator found matching: \(identifier)",
            suggestion: "Run 'iosdevctl device list' to see available simulators.",
            exitCode: 2
        )
    }

    // MARK: - Physical device support

    /// Lists all connected physical iOS devices via `xcrun devicectl`.
    /// Requires Xcode 15+ / macOS 14+. Returns [] gracefully on older systems.
    static func listPhysical() -> [PhysicalDevice] {
        guard #available(macOS 14, *) else { return [] }

        let result = devicectl(["list", "devices", "--json"])
        guard result.succeeded,
              let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultObj = json["result"] as? [String: Any],
              let devices = resultObj["devices"] as? [[String: Any]] else {
            return []
        }

        return devices.compactMap { d -> PhysicalDevice? in
            guard let hw = d["hardwareProperties"] as? [String: Any],
                  let udid = hw["udid"] as? String,
                  let name = hw["name"] as? String else { return nil }
            let model = hw["productType"] as? String ?? ""
            let dp = d["deviceProperties"] as? [String: Any]
            let osVersion = dp?["osVersionNumber"] as? String ?? ""
            let cp = d["connectionProperties"] as? [String: Any]
            let transport = cp?["transportType"] as? String ?? "unknown"
            return PhysicalDevice(
                udid: udid,
                name: name,
                modelIdentifier: model,
                osVersion: osVersion,
                connectionType: transport
            )
        }
    }

    /// Unified resolver — checks simulators first, then physical devices.
    /// Keeps the original `resolve()` (simulator-only) intact for sim-only commands.
    @discardableResult
    static func resolveAny(identifier: String?) -> DeviceKind {
        let sims = listAll()
        let physical = listPhysical()

        guard let identifier = identifier, !identifier.isEmpty else {
            // nil: prefer single booted sim
            let booted = sims.filter { $0.isBooted }
            if booted.count == 1 { return .simulator(booted[0]) }
            if booted.isEmpty && physical.count == 1 { return .physical(physical[0]) }
            if booted.isEmpty && physical.isEmpty {
                Output.error(
                    code: "DEVICE_NOT_BOOTED",
                    message: "No booted simulators or connected physical devices found.",
                    suggestion: "Boot a simulator with: iosdevctl device boot --device \"iPhone 15\"",
                    exitCode: 4
                )
            }
            let names = (booted.map { "\($0.name) (\($0.udid))" } +
                         physical.map { "\($0.name) (\($0.udid))" }).joined(separator: ", ")
            Output.error(
                code: "AMBIGUOUS_DEVICE",
                message: "Multiple devices found: \(names)",
                suggestion: "Specify a device with --device <udid-or-name>",
                exitCode: 1
            )
        }

        // UUID pattern — check sims then physical
        let uuidPattern = #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#
        let isUUID = identifier.range(of: uuidPattern, options: .regularExpression) != nil
        if isUUID {
            if let d = sims.first(where: { $0.udid.lowercased() == identifier.lowercased() }) {
                return .simulator(d)
            }
            if let d = physical.first(where: { $0.udid.lowercased() == identifier.lowercased() }) {
                return .physical(d)
            }
            Output.error(
                code: "DEVICE_NOT_FOUND",
                message: "No device found with UDID: \(identifier)",
                suggestion: "Run 'iosdevctl device list' to see available devices.",
                exitCode: 2
            )
        }

        // Name match — sims first (prefer booted), then physical
        let simMatches = sims.filter { $0.name.lowercased() == identifier.lowercased() }
        if let d = simMatches.first(where: { $0.isBooted }) { return .simulator(d) }
        if let d = simMatches.first(where: { $0.available }) { return .simulator(d) }
        if let d = simMatches.first { return .simulator(d) }

        if let d = physical.first(where: { $0.name.lowercased() == identifier.lowercased() }) {
            return .physical(d)
        }

        Output.error(
            code: "DEVICE_NOT_FOUND",
            message: "No device found matching: \(identifier)",
            suggestion: "Run 'iosdevctl device list' to see available devices.",
            exitCode: 2
        )
    }

    private static func runtimeName(from key: String) -> String {
        // "com.apple.CoreSimulator.SimRuntime.iOS-17-0" -> "iOS 17.0"
        let prefix = "com.apple.CoreSimulator.SimRuntime."
        var name = key
        if name.hasPrefix(prefix) {
            name = String(name.dropFirst(prefix.count))
        }
        // Replace dashes with spaces and dots
        // "iOS-17-0" -> "iOS 17.0"
        let parts = name.split(separator: "-")
        if parts.count >= 3, let last = parts.last {
            let platform = parts.dropLast().joined(separator: " ")
            // Re-join version parts with dots
            let versionParts = parts.dropFirst()
            let version = versionParts.joined(separator: ".")
            // Actually: parts[0] = "iOS", parts[1] = "17", parts[2] = "0"
            if parts.count == 3 {
                return "\(parts[0]) \(parts[1]).\(parts[2])"
            } else if parts.count == 2 {
                return "\(parts[0]) \(parts[1])"
            }
            _ = platform
            _ = last
            _ = version
        }
        return name.replacingOccurrences(of: "-", with: " ")
    }
}
