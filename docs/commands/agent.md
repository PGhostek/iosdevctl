# agent

Agent-optimized commands designed to reduce round-trips in AI agent workflows. Each command combines multiple lower-level operations into a single call.

## Subcommands

| Subcommand | Description |
|---|---|
| [`agent tap-text`](#agent-tap-text) | Tap element by visible label — no coordinates needed |
| [`agent wait-for`](#agent-wait-for) | Block until an element appears on screen |
| [`agent context`](#agent-context) | Screenshot + accessibility tree in one call |

---

## agent tap-text

Find the first element whose label or value matches the given text and tap its center. Eliminates the `ui tree` → parse → `ui tap` round-trip.

```
iosdevctl agent tap-text <text> [--type <element-type>] [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `text` | Text to match against element labels and values (case-insensitive) |

### Options

| Option | Description |
|---|---|
| `--type` | Restrict match to a specific element type (e.g. `Button`, `StaticText`) |

### Example

```bash
# Tap the first element labelled "Submit"
iosdevctl agent tap-text "Submit" --pretty

# Tap only if it's a Button (avoids matching a label with the same text)
iosdevctl agent tap-text "Submit" --type Button --pretty
```

```json
{
  "status": "ok",
  "message": "Tapped element.",
  "matched_label": "Submit",
  "x": 196,
  "y": 744,
  "device": "iPhone 17 Pro",
  "udid": "8F5A0F44-5E98-4F9A-9402-FB9AE4D3E874"
}
```

### Notes

- Matches the **first** element found in tree traversal order (top-down, left-to-right).
- Matching is case-insensitive and substring-based — `"Sub"` matches `"Submit"`.
- Use `--type Button` to avoid accidentally tapping a `StaticText` label with the same text.
- Falls back to exit code `3` (`ELEMENT_NOT_FOUND`) if no match exists.

---

## agent wait-for

Poll the accessibility tree until an element matching the given text appears, or until the timeout expires. Useful after actions that trigger navigation or async UI updates.

```
iosdevctl agent wait-for <text> [--timeout <seconds>] [--interval <seconds>] [--type <element-type>] [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `text` | Text to wait for (case-insensitive, substring match) |

### Options

| Option | Default | Description |
|---|---|---|
| `--timeout` | `10` | Maximum seconds to wait before failing |
| `--interval` | `0.5` | How often to poll the accessibility tree (seconds) |
| `--type` | — | Restrict match to a specific element type |

### Example

```bash
# Wait up to 10s for a "Home" element after login
iosdevctl agent wait-for "Home" --pretty

# Wait up to 30s with faster polling for a slow network load
iosdevctl agent wait-for "Dashboard" --timeout 30 --interval 0.2 --pretty
```

```json
{
  "status": "ok",
  "found": true,
  "matched_label": "Home",
  "frame": {"x": 0, "y": 762, "width": 92.5, "height": 56},
  "device": "iPhone 17 Pro",
  "udid": "8F5A0F44-5E98-4F9A-9402-FB9AE4D3E874"
}
```

### Notes

- Returns immediately as soon as the element is found — does not wait for the full timeout.
- Returns exit code `1` (`WAIT_TIMEOUT`) if the element never appears.
- Combine with `agent tap-text` for reliable post-navigation tapping:

```bash
iosdevctl agent wait-for "Profile" && iosdevctl agent tap-text "Profile"
```

---

## agent context

Take a screenshot and fetch the full accessibility tree in a single call. The best starting point for an agent that needs to understand the current screen before deciding what to do.

```
iosdevctl agent context [--output <path>] [--query <text>] [--type <element-type>] [--device <udid-or-name>] [--pretty]
```

### Options

| Option | Description |
|---|---|
| `--output` | Screenshot file path (default: `/tmp/iosdevctl-context-<timestamp>.png`) |
| `--query` | Filter accessibility tree by label/value text |
| `--type` | Filter accessibility tree by element type |

### Example

```bash
# Full context (screenshot + complete tree)
iosdevctl agent context --pretty

# Context with only Button elements (smaller response for agents)
iosdevctl agent context --type Button --pretty
```

```json
{
  "status": "ok",
  "device": "iPhone 17 Pro",
  "udid": "8F5A0F44-5E98-4F9A-9402-FB9AE4D3E874",
  "screenshot": "/tmp/iosdevctl-context-1774684324.png",
  "elements": [
    {
      "type": "Button",
      "AXLabel": "Back",
      "AXUniqueId": null,
      "frame": {"x": 16, "y": 56, "width": 44, "height": 44},
      "enabled": true
    }
  ]
}
```

### Notes

- The screenshot is saved to disk; the response contains the **path**, not the image data.
- Use `--type Button` to limit the tree to interactive elements only — reduces token usage when passing context to an LLM.
- Also exposed as the `agent_context` MCP tool, making it usable directly from Claude Desktop with no extra steps.

---

## MCP tools

All three commands are available as MCP tools when running `iosdevctl mcp serve`:

| MCP tool | Maps to |
|---|---|
| `agent_tap_text` | `agent tap-text` |
| `agent_wait_for` | `agent wait-for` |
| `agent_context` | `agent context` |

See [mcp.md](mcp.md) for server setup.

---

## Error codes

| Code | Meaning |
|---|---|
| `DEVICE_NOT_BOOTED` | Target simulator is not booted |
| `COMPANION_UNAVAILABLE` | `idb_companion` failed to start |
| `ACCESSIBILITY_FAILED` | gRPC call to `accessibility_info` failed |
| `ACCESSIBILITY_PARSE_FAILED` | Could not parse tree JSON from `idb_companion` |
| `ELEMENT_NOT_FOUND` | No element matching the given text found on screen (exit 3) |
| `ELEMENT_NO_FRAME` | Element found but has no usable frame |
| `SCREENSHOT_FAILED` | `xcrun simctl io screenshot` failed |
| `WAIT_TIMEOUT` | Element did not appear within the timeout window (exit 1) |
