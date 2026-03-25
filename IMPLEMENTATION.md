# iosdevctl — Agent-Native iOS Device Control

## Vision

A modern, maintained replacement for Meta's abandoned `idb` (iOS Development Bridge) — designed from the ground up for both human developers and AI agents. One core library, two interfaces: a CLI for shell-based agents and CI/CD pipelines, and an MCP server for GUI-based AI applications like Claude Desktop and Cursor.

## Problem Statement

1. **Meta's `idb` is effectively abandoned** — the Python client breaks with new Xcode/macOS versions, the setup is fragile (gRPC daemon + Python client), and maintenance is minimal.
2. **`xcrun simctl` is powerful but not agent-friendly** — output is unstructured, inconsistent between subcommands, and requires human interpretation.
3. **No tool bridges the gap between device control and AI agents** — existing tools were built for CI pipelines and human operators, not LLMs that need structured output, clear error messages, and vision-based interaction.
4. **MCP ecosystem has no iOS device control server** — Claude Desktop, Cursor, and other MCP-compatible tools have no way to interact with iOS simulators or devices.

## Architecture

```
┌─────────────────────────────────────────┐
│              Core Library               │
│  (Swift/Python — wraps xcrun simctl +   │
│   idb_companion + Accessibility APIs)   │
└──────────┬──────────────────┬───────────┘
           │                  │
    ┌──────▼──────┐    ┌──────▼──────┐
    │     CLI     │    │  MCP Server │
    │  (primary)  │    │  (wrapper)  │
    └─────────────┘    └─────────────┘
```

### Design Principles

- **JSON-first output** — every command returns structured JSON by default, with optional human-readable formatting via `--pretty`
- **Zero interactivity** — no prompts, no confirmators; every operation is fully scriptable
- **Idempotent where possible** — running the same command twice shouldn't fail or produce side effects
- **Clear exit codes** — distinct codes for "not found", "already exists", "device offline", etc.
- **Machine-readable errors** — errors include an error code, message, and suggested fix in JSON

## Implementation Plan

### Phase 1: Core CLI — idb Replacement (Weeks 1–3)

**Goal:** Ship a working CLI that replaces the most-used `idb` and `xcrun simctl` commands with a clean, agent-friendly interface.

**Language choice:** Swift (native macOS, direct access to Apple frameworks, no Python dependency hell)

**Core commands to implement:**

```
iosdevctl device list                    # List all simulators/devices (JSON)
iosdevctl device boot <udid|name>        # Boot a simulator
iosdevctl device shutdown <udid|name>    # Shutdown a simulator
iosdevctl device screenshot [path]       # Take screenshot, returns path
iosdevctl device record start/stop       # Screen recording
iosdevctl app install <path>             # Install .app or .ipa
iosdevctl app launch <bundle-id>         # Launch app
iosdevctl app terminate <bundle-id>      # Terminate app
iosdevctl app list                       # List installed apps
iosdevctl ui tap <x> <y>                 # Tap at coordinates
iosdevctl ui swipe <x1> <y1> <x2> <y2>  # Swipe gesture
iosdevctl ui type <text>                 # Type text
iosdevctl ui button <name>              # Press hardware button (home, lock, etc.)
iosdevctl push send <bundle-id> <file>   # Send push notification
iosdevctl url open <url>                 # Open URL on device
iosdevctl pasteboard get/set             # Clipboard operations
iosdevctl status-bar override            # Override status bar for screenshots
```

**Deliverables:**
- [ ] Project scaffolding (Swift Package Manager)
- [ ] Core library wrapping `xcrun simctl` with structured output parsing
- [ ] CLI interface using Swift Argument Parser
- [ ] JSON output for all commands
- [ ] Homebrew formula for easy installation
- [ ] Basic README and usage docs
- [ ] GitHub Actions CI

### Phase 2: Touch & UI Interaction (Weeks 4–5)

**Goal:** Add reliable tap, swipe, and text input — the key gap that `xcrun simctl` doesn't cover.

**Approach:** Use `idb_companion` gRPC API for touch events (it's still maintained, unlike the Python client), or alternatively use Apple's `XCUITest` framework via a helper app.

**Deliverables:**
- [ ] Touch input (tap, long press, swipe, pinch)
- [ ] Text input (keyboard simulation)
- [ ] Hardware button simulation
- [ ] Gesture recording and replay

### Phase 3: UI Inspection & Accessibility (Weeks 6–7)

**Goal:** Enable agents to understand what's on screen — not just take screenshots, but query the UI tree.

```
iosdevctl ui tree                        # Full accessibility tree (JSON)
iosdevctl ui tree --query "Login"        # Find elements matching text
iosdevctl ui tree --type button          # Find all buttons
iosdevctl ui element <id> tap            # Tap element by accessibility ID
```

**Deliverables:**
- [ ] Accessibility tree extraction via XCUITest helper
- [ ] Element querying by text, type, accessibility ID
- [ ] Element-based interactions (tap element by ID, not coordinates)
- [ ] Screen diff detection (has the screen changed?)

### Phase 4: MCP Server (Week 8)

**Goal:** Thin MCP wrapper around the CLI for Claude Desktop, Cursor, and other MCP-compatible tools.

**Implementation:** The MCP server calls the CLI under the hood. Each CLI command maps to one MCP tool.

**MCP Tools:**
```
device_list          → iosdevctl device list
device_boot          → iosdevctl device boot
device_screenshot    → iosdevctl device screenshot
app_install          → iosdevctl app install
app_launch           → iosdevctl app launch
ui_tap               → iosdevctl ui tap
ui_swipe             → iosdevctl ui swipe
ui_type              → iosdevctl ui type
ui_tree              → iosdevctl ui tree
ui_element_tap       → iosdevctl ui element <id> tap
push_notification    → iosdevctl push send
```

**Deliverables:**
- [ ] MCP server (TypeScript or Python — whatever the MCP ecosystem favors)
- [ ] Tool definitions with clear schemas and descriptions
- [ ] Configuration instructions for Claude Desktop / Cursor
- [ ] npm/pip package for easy installation

### Phase 5: Agent-Optimized Features (Weeks 9–10)

**Goal:** Features that only make sense for AI agents — things a human wouldn't need but an LLM does.

**Features:**
- **Screenshot + UI tree combo** — one command that returns both a screenshot path and the accessibility tree, so the agent gets visual + structural context in one call
- **Smart element targeting** — `iosdevctl ui tap-text "Login"` finds the element containing "Login" and taps it, no coordinates needed
- **Screen state hashing** — quick check: "has the screen changed since last time?" without taking a full screenshot
- **Wait-for conditions** — `iosdevctl ui wait-for --text "Welcome"` blocks until element appears (with timeout)
- **Session management** — `iosdevctl session start/stop` to track a sequence of actions and roll back

**Deliverables:**
- [ ] Combined screenshot + tree command
- [ ] Text-based element targeting
- [ ] Screen change detection
- [ ] Wait-for conditions with configurable timeout
- [ ] Session recording and replay

## Features Roadmap

### Tier 1: Open Source Core (Free)
*The idb replacement. Builds community, mindshare, adoption.*

| Feature | Priority | Description |
|---------|----------|-------------|
| Device management | P0 | List, boot, shutdown, erase simulators |
| App lifecycle | P0 | Install, launch, terminate, list apps |
| Screenshots | P0 | Take screenshots, screen recording |
| Touch input | P0 | Tap, swipe, type, hardware buttons |
| JSON output | P0 | Structured output for every command |
| Push notifications | P1 | Send simulated push notifications |
| URL handling | P1 | Open URLs, deep links |
| Clipboard | P1 | Get/set pasteboard |
| Status bar | P1 | Override status bar for clean screenshots |
| Location simulation | P1 | Set simulated GPS location |
| Accessibility tree | P1 | Query UI element hierarchy |
| Homebrew distribution | P0 | `brew install iosdevctl` |

### Tier 2: Agent Power Features (Free / Open Source)
*What differentiates this from a mere idb clone. Attracts AI tooling community.*

| Feature | Priority | Description |
|---------|----------|-------------|
| Text-based tapping | P0 | Tap elements by visible text, not coordinates |
| Combined context | P0 | Screenshot + UI tree in one call |
| Wait-for conditions | P1 | Block until element appears/disappears |
| Screen change detection | P1 | Hash-based "did the screen change?" |
| MCP server | P0 | Full MCP integration for Claude Desktop / Cursor |
| Smart error messages | P1 | Errors include what went wrong and how to fix it |
| Session replay | P2 | Record and replay interaction sequences |
| Multi-device orchestration | P2 | Run commands across multiple simulators |

### Tier 3: Physical Device Support (Open Source + Potential Premium)
*Extends from simulators to real hardware.*

| Feature | Priority | Description |
|---------|----------|-------------|
| Device detection | P0 | List connected physical devices |
| App install (device) | P0 | Install .ipa on physical devices |
| Screenshot (device) | P0 | Capture screenshots from devices |
| Touch relay (device) | P1 | Tap/swipe on physical devices |
| Device logs | P1 | Stream device logs |
| Crash log collection | P2 | Retrieve and parse crash logs |

### Tier 4: Commercial Potential
*Once adoption exists, these are natural paid extensions.*

| Feature | Model | Description |
|---------|-------|-------------|
| Cloud device farm | SaaS | Hosted simulators/devices accessible via API — like Browserbase for mobile |
| CI/CD integration | Free+SaaS | GitHub Actions, Bitrise, CircleCI plugins — free for simulators, paid for cloud devices |
| Visual regression testing | SaaS | Screenshot comparison across app versions, powered by vision AI |
| Test flow recording | SaaS | Record human interactions → generate reproducible test scripts |
| Android support | Expansion | Extend the same CLI/MCP interface to Android emulators + devices |
| Team collaboration | SaaS | Shared device sessions, recorded test flows, team dashboards |

## Name

**`iosdevctl`** — iOS Device Control. Available on GitHub, npm, Homebrew. No conflicts found.

## Tech Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Core library | Swift | Native macOS, direct Apple framework access, no runtime dependencies |
| CLI | Swift Argument Parser | Standard for Swift CLI tools |
| MCP server | TypeScript | MCP SDK is TypeScript-first, best ecosystem support |
| Distribution | Homebrew + npm | Homebrew for CLI, npm for MCP server |
| CI | GitHub Actions | macOS runners available, standard for open source |

## Success Metrics

1. **Phase 1:** CLI can replace 80% of common `idb` usage with zero Python dependency
2. **Phase 2–3:** An AI agent (Claude Code) can autonomously navigate an iOS app using only this tool
3. **Phase 4:** MCP server listed in Claude Desktop's recommended tools
4. **Phase 5:** GitHub stars > 500 within 3 months of launch (idb has ~4.5k)
5. **Commercial:** First paying customer for cloud device farm within 6 months of Tier 4 launch
