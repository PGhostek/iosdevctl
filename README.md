# iosdevctl

`iosdevctl` is an agent-native iOS device control tool — a modern, maintained replacement for Meta's abandoned `idb` (iOS Development Bridge). It wraps `xcrun simctl` with a clean, structured JSON interface designed for both AI agents and CI/CD pipelines: every command returns machine-readable JSON by default, errors include suggested fixes, and there are no interactive prompts.

## Installation

### Homebrew (coming soon)

```sh
brew install iosdevctl
```

### Build from source

Requires Xcode 15+ and Swift 5.9+.

```sh
git clone https://github.com/PGhostek/iosdevctl.git
cd iosdevctl
swift build -c release
cp .build/release/iosdevctl /usr/local/bin/iosdevctl
```

## Quick start

All commands output JSON. Add `--pretty` for human-readable formatting.

### device

```sh
# List all simulators
iosdevctl device list
iosdevctl device list --pretty

# Boot a simulator by name or UDID
iosdevctl device boot --device "iPhone 15"
iosdevctl device boot --device "A1B2C3D4-..."

# Shut down a simulator
iosdevctl device shutdown --device "iPhone 15"

# Take a screenshot (auto-selects booted simulator if --device is omitted)
iosdevctl device screenshot
iosdevctl device screenshot --output /tmp/screen.png

# Record screen
iosdevctl device record start --output /tmp/recording.mp4
iosdevctl device record stop
```

### app

```sh
# Install an app
iosdevctl app install --path /path/to/MyApp.app
iosdevctl app install --path /path/to/MyApp.app --device "iPhone 15"

# Launch an app
iosdevctl app launch com.example.myapp

# Terminate a running app
iosdevctl app terminate com.example.myapp

# List installed apps
iosdevctl app list
iosdevctl app list --device "iPhone 15" --pretty
```

### push

```sh
# Send a push notification
iosdevctl push send com.example.myapp payload.json
```

Example `payload.json`:
```json
{
  "aps": {
    "alert": {
      "title": "Hello",
      "body": "This is a test notification"
    }
  }
}
```

### url

```sh
# Open a URL or deep link
iosdevctl url open "https://example.com"
iosdevctl url open "myapp://onboarding"
```

### pasteboard

```sh
# Read the simulator clipboard
iosdevctl pasteboard get

# Write to the simulator clipboard
iosdevctl pasteboard set "Hello, clipboard!"
```

### status-bar

```sh
# Override status bar for clean screenshots
iosdevctl status-bar override --time "9:41" --battery-level 100 --battery-state charged --network wifi

# Restore status bar defaults
iosdevctl status-bar clear
```

### ui (coming in Phase 2)

```sh
# These commands are stubbed and will return a clear error until Phase 2 is released.
iosdevctl ui tap 100 200
iosdevctl ui swipe 100 500 100 100
iosdevctl ui type "Hello, world!"
iosdevctl ui button home
```

UI interaction (tap, swipe, type, hardware buttons) requires Phase 2. See the [roadmap](IMPLEMENTATION.md#phase-2-touch--ui-interaction-weeks-45) for details.

## Output format

Every command outputs JSON. On success:

```json
{"status": "ok", "message": "...", ...}
```

On error:

```json
{"status": "error", "code": "DEVICE_NOT_FOUND", "message": "...", "suggestion": "..."}
```

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Device not found |
| 3 | App not found |
| 4 | Device not booted |

## Device resolution

Most commands accept `--device <udid-or-name>`. If omitted, `iosdevctl` auto-selects the single booted simulator. It errors clearly if zero or more than one simulator is booted.

## Roadmap

See [IMPLEMENTATION.md](IMPLEMENTATION.md) for the full roadmap, including Phase 2 (UI interaction), Phase 3 (accessibility tree), and Phase 4 (MCP server for Claude Desktop and Cursor).
