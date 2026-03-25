import ArgumentParser
import Foundation

struct UICommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ui",
        abstract: "UI interaction commands (Phase 2).",
        subcommands: [
            UITap.self,
            UISwipe.self,
            UIType.self,
            UIButton.self
        ]
    )
}

private let phase2Error = (
    code: "NOT_IMPLEMENTED",
    message: "UI interaction requires Phase 2. See https://github.com/PGhostek/iosdevctl#roadmap",
    suggestion: "Install idb Python client as a temporary workaround: pip install fb-idb"
)

struct UITap: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tap",
        abstract: "Tap at coordinates (Phase 2)."
    )

    @Argument(help: "X coordinate.")
    var x: Double

    @Argument(help: "Y coordinate.")
    var y: Double

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    func run() throws {
        Output.error(
            code: phase2Error.code,
            message: phase2Error.message,
            suggestion: phase2Error.suggestion
        )
    }
}

struct UISwipe: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swipe",
        abstract: "Swipe gesture (Phase 2)."
    )

    @Argument(help: "Start X coordinate.")
    var x1: Double

    @Argument(help: "Start Y coordinate.")
    var y1: Double

    @Argument(help: "End X coordinate.")
    var x2: Double

    @Argument(help: "End Y coordinate.")
    var y2: Double

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    func run() throws {
        Output.error(
            code: phase2Error.code,
            message: phase2Error.message,
            suggestion: phase2Error.suggestion
        )
    }
}

struct UIType: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "type",
        abstract: "Type text (Phase 2)."
    )

    @Argument(help: "Text to type.")
    var text: String

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    func run() throws {
        Output.error(
            code: phase2Error.code,
            message: phase2Error.message,
            suggestion: phase2Error.suggestion
        )
    }
}

struct UIButton: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "button",
        abstract: "Press a hardware button (Phase 2)."
    )

    @Argument(help: "Button name (home, lock, siri, etc.).")
    var name: String

    @Option(name: .long, help: "Device UDID or name.")
    var device: String?

    func run() throws {
        Output.error(
            code: phase2Error.code,
            message: phase2Error.message,
            suggestion: phase2Error.suggestion
        )
    }
}
