import Foundation

/// Xcode 27 compatibility for `idb_companion` (1.1.8, unmaintained).
///
/// Xcode 27 moved `SimulatorKit.framework` from
/// `Contents/Developer/Library/PrivateFrameworks/` to `Contents/SharedFrameworks/`
/// and dropped `Simulator.app` (replaced by DeviceHub). idb_companion still
/// loads SimulatorKit from the old path, so every HID event fails with
/// "SimulatorKit is required for HID interactions".
///
/// Instead of touching Xcode.app (that would break its code signature), we
/// build a symlink mirror of `Xcode.app/Contents` under `~/.iosdevctl/xcode-shim/`
/// that also exposes SimulatorKit at the old path, and start idb_companion
/// with `DEVELOPER_DIR` pointing into the mirror.
enum XcodeShim {

    /// The active developer dir (`DEVELOPER_DIR`, else `xcode-select -p`).
    static func developerDir() -> String? {
        if let env = ProcessInfo.processInfo.environment["DEVELOPER_DIR"], !env.isEmpty {
            return env
        }
        let r = runCommand(["xcode-select", "-p"])
        return r.succeeded && !r.stdout.isEmpty ? r.stdout : nil
    }

    /// Whether the classic Simulator.app exists (absent in Xcode 27+).
    static func hasSimulatorApp() -> Bool {
        guard let dev = developerDir() else { return true }
        return FileManager.default.fileExists(atPath: dev + "/Applications/Simulator.app")
    }

    /// Returns a `DEVELOPER_DIR` for idb_companion, or nil if the real one works.
    static func companionDeveloperDir() -> String? {
        let fm = FileManager.default
        guard let dev = developerDir() else { return nil }
        let oldPath = dev + "/Library/PrivateFrameworks/SimulatorKit.framework"
        if fm.fileExists(atPath: oldPath) { return nil }

        let contents = (dev as NSString).deletingLastPathComponent
        let shared = contents + "/SharedFrameworks/SimulatorKit.framework"
        guard fm.fileExists(atPath: shared) else { return nil }

        let build = (NSDictionary(contentsOfFile: contents + "/version.plist")?["ProductBuildVersion"] as? String) ?? "current"
        let shimContents = NSHomeDirectory() + "/.iosdevctl/xcode-shim/\(build)/Xcode.app/Contents"
        let shimDev = shimContents + "/Developer"
        if fm.fileExists(atPath: shimDev + "/Library/PrivateFrameworks/SimulatorKit.framework") {
            return shimDev
        }

        do {
            try? fm.removeItem(atPath: shimContents)
            try fm.createDirectory(atPath: shimDev + "/Library/PrivateFrameworks",
                                   withIntermediateDirectories: true)
            try mirror(from: contents, to: shimContents, except: "Developer")
            try mirror(from: dev, to: shimDev, except: "Library")
            try mirror(from: dev + "/Library", to: shimDev + "/Library", except: "PrivateFrameworks")
            if fm.fileExists(atPath: dev + "/Library/PrivateFrameworks") {
                try mirror(from: dev + "/Library/PrivateFrameworks",
                           to: shimDev + "/Library/PrivateFrameworks", except: nil)
            }
            try fm.createSymbolicLink(atPath: shimDev + "/Library/PrivateFrameworks/SimulatorKit.framework",
                                      withDestinationPath: shared)
            return shimDev
        } catch {
            return nil  // fall back to the real developer dir; idb_companion reports its own error
        }
    }

    /// Symlinks every entry of `src` into `dst`, skipping `except`.
    private static func mirror(from src: String, to dst: String, except: String?) throws {
        let fm = FileManager.default
        for name in try fm.contentsOfDirectory(atPath: src) where name != except {
            let link = dst + "/" + name
            if fm.fileExists(atPath: link) { continue }
            try fm.createSymbolicLink(atPath: link, withDestinationPath: src + "/" + name)
        }
    }
}
