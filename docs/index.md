# iosdevctl Documentation

**iosdevctl** is an agent-native iOS device control CLI — a modern, maintained replacement for Meta's abandoned `idb`. It wraps `xcrun simctl` and `idb_companion` behind a clean, JSON-first interface designed for both human developers and AI agents.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Concepts](#concepts)
- [Roadmap](#roadmap)

## Installation

### Build from Source

```bash
git clone https://github.com/PGhostek/iosdevctl.git
cd iosdevctl
swift build -c release
cp .build/release/iosdevctl /usr/local/bin/iosdevctl
```

**Requirements:** macOS 13+, Xcode 14+ (for `xcrun simctl`)

### Homebrew *(coming soon)*

```bash
brew install iosdevctl
```

## Quick Start

```bash
# List all simulators
iosdevctl device list

# Boot a simulator by name
iosdevctl device boot --device "iPhone 17 Pro"

# Take a screenshot
iosdevctl device screenshot --output ~/Desktop/screen.png

# Install and launch an app
iosdevctl app install --path MyApp.app
iosdevctl app launch com.example.myapp

# Send a push notification
iosdevctl push send com.example.myapp payload.json

# Open a deep link
iosdevctl url open "myapp://home"
```

## Commands

| Command group | Description | Status |
|---|---|---|
| [`device`](commands/device.md) | List, boot, shutdown, screenshot, record | Phase 1 |
| [`app`](commands/app.md) | Install, launch, terminate, list apps | Phase 1 |
| [`ui`](commands/ui.md) | Tap, swipe, type, hardware buttons | Phase 2 |
| [`push`](commands/push.md) | Send push notification payloads | Phase 1 |
| [`url`](commands/url.md) | Open URLs and deep links | Phase 1 |
| [`pasteboard`](commands/pasteboard.md) | Get and set clipboard content | Phase 1 |
| [`status-bar`](commands/status-bar.md) | Override status bar for screenshots | Phase 1 |
| [`mcp`](commands/mcp.md) | MCP server for Claude Desktop and other AI tools | Phase 4 |

## Concepts

- [Output format & exit codes](concepts/output-format.md)
- [Device resolution](concepts/device-resolution.md)

## Roadmap

See [roadmap.md](roadmap.md) for the full feature roadmap across all phases.
