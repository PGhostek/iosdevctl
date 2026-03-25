# iosdevctl — Claude Context

## Project Overview

`iosdevctl` is an agent-native iOS device control CLI — a modern, maintained replacement for Meta's abandoned `idb` (iOS Development Bridge). It wraps `xcrun simctl` and `idb_companion` behind a JSON-first interface designed for both human developers and AI agents.

**GitHub:** https://github.com/PGhostek/iosdevctl

## Tech Stack

- **Language:** Swift 5.9+
- **CLI framework:** `swift-argument-parser`
- **Platform:** macOS 13+
- **Build system:** Swift Package Manager
- **Underlying tools:** `xcrun simctl`, `idb_companion` (for Phase 2+ touch events)

## Build & Run

```bash
# Build debug
swift build

# Build release
swift build -c release

# Run directly
swift run iosdevctl device list

# Run built binary
.build/debug/iosdevctl device list
```

## Project Structure

```
Sources/iosdevctl/
  IOSDevCtl.swift              # Root ParsableCommand — registers all subcommand groups
  main.swift                   # Entry point — calls IOSDevCtl.main()
  Core/
    Shell.swift                # runCommand(), xcrun() helpers; ShellResult struct
    Output.swift               # Output.success(), Output.error() — all JSON output goes here
    DeviceResolver.swift       # Resolves --device flag by name or UDID; auto-selects booted sim
  Commands/
    DeviceCommands.swift       # device list/boot/shutdown/screenshot/record
    AppCommands.swift          # app install/launch/terminate/list
    UICommands.swift           # ui tap/swipe/type/button (Phase 2 stubs)
    PushCommands.swift         # push send
    URLCommands.swift          # url open
    PasteboardCommands.swift   # pasteboard get/set
    StatusBarCommands.swift    # status-bar override/clear
docs/
  index.md                     # Overview and quick start
  roadmap.md                   # All phases + commercial tier
  commands/                    # Per-command reference docs
  concepts/                    # Output format, device resolution
```

## Key Conventions

### Output
- **Every command outputs JSON.** Use `Output.success(_:pretty:)` for success, `Output.error(code:message:suggestion:exitCode:)` for errors.
- `Output.error` calls `exit()` — it never returns.
- Add `--pretty` flag to every command for human-readable output.
- Errors go to stderr; data goes to stdout.

### Exit Codes
| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | General error |
| 2 | Device not found |
| 3 | App not found |
| 4 | Device not booted |

### Device Resolution
- All commands take `--device <udid-or-name>` (optional).
- If omitted, `DeviceResolver.resolve(identifier: nil)` auto-selects the single booted sim.
- Errors with `NO_DEVICE_BOOTED` or `MULTIPLE_DEVICES_BOOTED` if ambiguous.
- Always call `DeviceResolver.resolve(identifier: device)` at the top of every command's `run()`.

### Adding a New Command
1. Create or add to an existing file in `Sources/iosdevctl/Commands/`
2. Conform to `ParsableCommand`
3. Add `--device: String?` and `--pretty: Bool` options
4. Register the subcommand in the parent command's `subcommands: []` array
5. Register the parent in `IOSDevCtl.swift` if it's a new top-level group
6. **Update `docs/commands/<group>.md`** with the new command
7. If it's a new command group, add a row to the table in `docs/index.md`

### Documentation Rule
**Every new command or feature must be documented before the work is considered complete.** Update the relevant file in `docs/commands/` and mark phases complete in `docs/roadmap.md` when done.

## Phase Status

| Phase | Status | Description |
|---|---|---|
| Phase 1 | ✅ Complete | Core CLI — device, app, push, url, pasteboard, status-bar |
| Phase 2 | Planned | Touch & UI interaction (tap, swipe, type) via idb_companion gRPC |
| Phase 3 | Planned | UI inspection — accessibility tree, element-based tapping |
| Phase 4 | Planned | MCP server wrapping the CLI |
| Phase 5 | Planned | Agent-optimized features (ui context, tap-text, wait-for) |

## Phase 2 Implementation Notes

When implementing Phase 2 (UI interaction), the approach is:
- Connect to `idb_companion`'s gRPC API (already installed at `/opt/homebrew/bin/idb_companion`)
- Start `idb_companion --udid <udid> --grpc-port 10882` as a background process if not running
- Send touch events via gRPC calls
- Alternative: use an XCUITest helper app bundled with iosdevctl

The `UICommands.swift` stubs are already in place — just replace the `Output.error(NOT_IMPLEMENTED...)` calls with real implementations.
