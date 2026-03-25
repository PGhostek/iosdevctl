# ui

UI interaction commands — tap, swipe, type text, press hardware buttons, and long-press.

All commands connect to `idb_companion`'s gRPC API to inject touch and keyboard events into the simulator. `idb_companion` is managed automatically — it starts if not running, and restarts if running for a different UDID.

## Subcommands

| Subcommand | Description |
|---|---|
| [`ui tap`](#ui-tap) | Tap at coordinates |
| [`ui swipe`](#ui-swipe) | Swipe gesture |
| [`ui type`](#ui-type) | Type text via keyboard |
| [`ui button`](#ui-button) | Press a hardware button |
| [`ui long-press`](#ui-long-press) | Long-press at coordinates |

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
