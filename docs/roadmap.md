# Roadmap

## Phase 1 — Core CLI ✅

*Status: Complete*

A clean, JSON-first replacement for Meta's abandoned `idb` Python client. Wraps `xcrun simctl` with structured output, auto device resolution, and machine-readable errors.

**Commands shipped:**
- `device list / boot / shutdown / screenshot / record start / record stop`
- `app install / launch / terminate / list`
- `push send`
- `url open`
- `pasteboard get / set`
- `status-bar override / clear`

---

## Phase 2 — Touch & UI Interaction ✅

*Status: Complete*

Add reliable tap, swipe, and text input — the key gap that `xcrun simctl` alone doesn't cover.

**Approach:** Connects to `idb_companion`'s gRPC API to relay HID touch events. `idb_companion` is launched automatically as a background process if not already running.

**Commands shipped:**
- `ui tap <x> <y>` — Tap at coordinates
- `ui swipe <x1> <y1> <x2> <y2> [--duration]` — Swipe gesture (10-point interpolation)
- `ui type <text>` — Type text via keyboard simulation (USB HID keycodes)
- `ui button <name>` — Press hardware button (home, lock, siri, side, apple-pay)
- `ui long-press <x> <y> [--duration]` — Long press at coordinates

---

## Phase 3 — UI Inspection & Accessibility ✅

*Status: Complete*

Enable agents to understand what's on screen — not just capture screenshots, but query the full UI element hierarchy.

**Approach:** Calls `idb_companion`'s `accessibility_info` gRPC RPC (same companion process used for Phase 2). The response JSON contains the full nested accessibility tree.

**Commands shipped:**
- `ui tree` — Full accessibility tree as JSON
- `ui tree --query <text>` — Find elements matching visible text (label or value)
- `ui tree --type <type>` — Find elements by type (Button, TextField, StaticText, etc.)
- `ui element-tap <identifier>` — Tap element by accessibility identifier (no coordinates needed)

**Why this matters for agents:** Coordinate-based tapping is fragile — it breaks when layouts shift. Accessibility-ID-based interaction is robust across device sizes and orientations.

---

## Phase 4 — MCP Server ✅

*Status: Complete*

A thin MCP (Model Context Protocol) JSON-RPC 2.0 server over stdin/stdout. Allows Claude Desktop, Cursor, and any MCP-compatible client to call all `iosdevctl` capabilities as native tools without shelling out manually.

**Approach:** Each `tools/call` re-invokes the `iosdevctl` binary itself — zero code duplication, all existing error handling reused.

**17 tools shipped:**
- `device_list`, `device_boot`, `device_shutdown`, `device_screenshot`
- `app_list`, `app_launch`, `app_terminate`
- `ui_tap`, `ui_swipe`, `ui_type`, `ui_long_press`, `ui_tree`, `ui_element_tap`, `ui_button`
- `pasteboard_get`, `pasteboard_set`, `url_open`

**Config example for Claude Desktop:**
```json
{
  "mcpServers": {
    "iosdevctl": {
      "command": "/usr/local/bin/iosdevctl",
      "args": ["mcp", "serve"]
    }
  }
}
```

See [commands/mcp.md](commands/mcp.md) for full reference.

---

## Phase 5 — Agent-Optimized Features ✅

*Status: Complete*

Commands designed specifically for AI agents — things a human would rarely need but an LLM benefits from greatly. Each collapses multiple round-trips into a single call.

**Commands shipped:**
- `agent tap-text <text>` — Find element by visible label and tap it (no coordinates needed)
- `agent wait-for <text> [--timeout] [--interval]` — Poll accessibility tree until element appears
- `agent context [--query] [--type]` — Screenshot + accessibility tree in one call

**Also exposed as MCP tools:** `agent_tap_text`, `agent_wait_for`, `agent_context` (total: 20 MCP tools)

See [commands/agent.md](commands/agent.md) for full reference.

---

## Tier 3 — Physical Device Support

*Status: Future*

Extend all commands to work with physically connected iOS devices (not just simulators).

- All Phase 1–5 commands on real hardware
- `device logs` — Stream device logs in real time
- `device crash-logs` — Retrieve and parse crash reports
- Requires `libimobiledevice` or Apple's private frameworks

---

## Tier 4 — Commercial Extensions

*Status: Future*

Once open source adoption is established:

| Feature | Model | Description |
|---|---|---|
| Cloud device farm | SaaS | Hosted simulators and devices accessible via the same CLI over API — like Browserbase for mobile |
| CI/CD plugins | Free + SaaS | GitHub Actions, Bitrise, CircleCI integrations |
| Visual regression | SaaS | Screenshot comparison across app versions, powered by vision AI |
| Test flow recording | SaaS | Record human interactions → generate reproducible scripts |
| Android support | Expansion | Same CLI interface wrapping `adb` for Android emulators and devices |
| Team dashboards | SaaS | Shared sessions, recorded flows, test history |
