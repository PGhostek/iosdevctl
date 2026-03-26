# ui

UI interaction and inspection commands — tap, swipe, type text, press hardware buttons, long-press, and accessibility tree queries.

All commands connect to `idb_companion`'s gRPC API. `idb_companion` is managed automatically — it starts if not running, and restarts if running for a different UDID.

## Subcommands

| Subcommand | Description |
|---|---|
| [`ui tap`](#ui-tap) | Tap at coordinates |
| [`ui swipe`](#ui-swipe) | Swipe gesture |
| [`ui type`](#ui-type) | Type text via keyboard |
| [`ui button`](#ui-button) | Press a hardware button |
| [`ui long-press`](#ui-long-press) | Long-press at coordinates |
| [`ui tree`](#ui-tree) | Dump the accessibility element tree |
| [`ui element-tap`](#ui-element-tap) | Tap an element by accessibility identifier |

---

## ui tap

Tap at a specific coordinate on the simulator screen.

```
iosdevctl ui tap <x> <y> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `x` | X coordinate in points |
| `y` | Y coordinate in points |

### Example

```bash
iosdevctl ui tap 195 422
```

```json
{
  "status": "ok",
  "message": "Tap performed.",
  "x": 195,
  "y": 422,
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

---

## ui swipe

Perform a swipe gesture from one point to another. The gesture is interpolated across 10 intermediate points.

```
iosdevctl ui swipe <x1> <y1> <x2> <y2> [--duration <seconds>] [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `x1` | Start X coordinate |
| `y1` | Start Y coordinate |
| `x2` | End X coordinate |
| `y2` | End Y coordinate |

### Options

| Option | Default | Description |
|---|---|---|
| `--duration` | `0.5` | Swipe duration in seconds |

### Example

```bash
# Scroll up (swipe finger up the screen)
iosdevctl ui swipe 200 600 200 200 --duration 0.3
```

```json
{
  "status": "ok",
  "message": "Swipe performed.",
  "from": {"x": 200, "y": 600},
  "to": {"x": 200, "y": 200},
  "duration": 0.3,
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

---

## ui type

Type text into the currently focused text field using keyboard simulation.

```
iosdevctl ui type <text> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `text` | Text to type |

### Notes

- The text field must already be focused (tap on it first with `ui tap`).
- Supports printable ASCII. Non-ASCII characters are silently skipped.

### Example

```bash
iosdevctl ui tap 195 300   # Focus the text field
iosdevctl ui type "hello world"
```

```json
{
  "status": "ok",
  "message": "Text typed.",
  "text": "hello world",
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

---

## ui button

Press a hardware button.

```
iosdevctl ui button <name> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `name` | Button name (see table below) |

### Supported buttons

| Name | Description |
|---|---|
| `home` | Home button |
| `lock` | Lock / power button |
| `siri` | Siri button |
| `side` | Side button |
| `apple-pay` | Apple Pay button |

### Example

```bash
iosdevctl ui button home
```

```json
{
  "status": "ok",
  "message": "Button pressed.",
  "button": "home",
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

---

## ui long-press

Long-press at a coordinate for a specified duration.

```
iosdevctl ui long-press <x> <y> [--duration <seconds>] [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `x` | X coordinate in points |
| `y` | Y coordinate in points |

### Options

| Option | Default | Description |
|---|---|---|
| `--duration` | `1.0` | Hold duration in seconds |

### Example

```bash
# Long-press to trigger context menu
iosdevctl ui long-press 195 422 --duration 1.5
```

```json
{
  "status": "ok",
  "message": "Long press performed.",
  "x": 195,
  "y": 422,
  "duration": 1.5,
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

---

---

## ui tree

Dump the full accessibility element tree for the current screen as JSON. Use `--query` or `--type` to filter the results.

```
iosdevctl ui tree [--query <text>] [--type <type>] [--device <udid-or-name>] [--pretty]
```

### Options

| Option | Description |
|---|---|
| `--query` | Return only elements whose label or value contains this text (case-insensitive) |
| `--type` | Return only elements matching this type (e.g. `Button`, `TextField`, `StaticText`) |

### Examples

```bash
# Full tree
iosdevctl ui tree --pretty

# Find all buttons
iosdevctl ui tree --type Button --pretty

# Find elements mentioning "Login"
iosdevctl ui tree --query "Login" --pretty
```

```json
{
  "status": "ok",
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
  "elements": [
    {
      "type": "Button",
      "label": "Login",
      "value": "",
      "identifier": "loginButton",
      "frame": {"x": 100, "y": 400, "width": 190, "height": 44},
      "enabled": true,
      "focused": false,
      "children": []
    }
  ]
}
```

---

## ui element-tap

Tap an element by its accessibility identifier. Fetches the accessibility tree, finds the element, and taps its center — no coordinates needed.

```
iosdevctl ui element-tap <identifier> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `identifier` | The `AXUniqueId` value from `ui tree` output |

### Example

```bash
iosdevctl ui element-tap loginButton
```

```json
{
  "status": "ok",
  "message": "Tapped element.",
  "identifier": "loginButton",
  "x": 195,
  "y": 422,
  "device": "iPhone 16 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Notes

- Use `iosdevctl ui tree` to discover available identifiers.
- The element must be visible on screen when the command runs.
- Falls back to exit code 3 (`ELEMENT_NOT_FOUND`) if the identifier is not present.

---

## Error codes

| Code | Meaning |
|---|---|
| `COMPANION_UNAVAILABLE` | `idb_companion` failed to start. Install with `brew install idb-companion`. |
| `DEVICE_NOT_BOOTED` | The target simulator is not booted. |
| `INVALID_BUTTON` | The button name is not recognized. |
| `TAP_FAILED` | gRPC call failed for tap. |
| `SWIPE_FAILED` | gRPC call failed for swipe. |
| `TYPE_FAILED` | gRPC call failed for type. |
| `BUTTON_FAILED` | gRPC call failed for button press. |
| `LONG_PRESS_FAILED` | gRPC call failed for long press. |
| `ACCESSIBILITY_FAILED` | gRPC call to `accessibility_info` failed. |
| `ACCESSIBILITY_PARSE_FAILED` | Could not parse the JSON returned by `idb_companion`. |
| `ELEMENT_NOT_FOUND` | No element with the given identifier found on screen. |
| `ELEMENT_NO_FRAME` | Element found but has no usable frame (can't calculate tap coordinates). |
