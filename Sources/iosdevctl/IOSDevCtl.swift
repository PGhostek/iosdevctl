import ArgumentParser
import Foundation

struct IOSDevCtl: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iosdevctl",
        abstract: "Agent-native iOS device control — a modern replacement for Meta's idb.",
        version: "0.1.0",
        subcommands: [
            DeviceCommand.self,
            AppCommand.self,
            UICommand.self,
            PushCommand.self,
            URLCommand.self,
            PasteboardCommand.self,
            StatusBarCommand.self
        ]
    )
}
