# ui

UI interaction commands — tap, swipe, type text, and press hardware buttons.

> **Phase 2 — Not yet implemented.**
> These commands are stubbed and will return a `NOT_IMPLEMENTED` error until Phase 2 is complete.
> See the [roadmap](../roadmap.md) for timeline.

## Planned Subcommands

| Subcommand | Description |
|---|---|
| [`ui tap`](#ui-tap) | Tap at coordinates |
| [`ui swipe`](#ui-swipe) | Swipe gesture |
| [`ui type`](#ui-type) | Type text via keyboard |
| [`ui button`](#ui-button) | Press a hardware button |

---

## ui tap

Tap at a specific coordinate on the simulator screen.

```
iosdevctl ui tap <x> <y> [--device <udid-or-name>]
```

### Arguments

| Argument | Description |
|---|---|
| `x` | X coordinate in points |
| `y` | Y coordinate in points |

### Planned Output

```json
{
  "status": "ok",
  "message": "Tap performed.",
  "x": 195,
  "y": 422,
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

---

## ui swipe

Perform a swipe gesture from one point to another.

```
iosdevctl ui swipe <x1> <y1> <x2> <y2> [--device <udid-or-name>]
```

### Arguments

| Argument | Description |
|---|---|
| `x1` | Start X coordinate |
| `y1` | Start Y coordinate |
| `x2` | End X coordinate |
| `y2` | End Y coordinate |

---

## ui type

Type text into the currently focused text field.

```
iosdevctl ui type <text> [--device <udid-or-name>]
```

### Arguments

| Argument | Description |
|---|---|
| `text` | Text to type |

---

## ui button

Press a hardware button.

```
iosdevctl ui button <name> [--device <udid-or-name>]
```

### Arguments

| Argument | Description |
|---|---|
| `name` | Button name: `home`, `lock`, `siri`, `volume-up`, `volume-down` |

---

## Current Behavior

All `ui` commands currently return:

```json
{
  "status": "error",
  "code": "NOT_IMPLEMENTED",
  "message": "UI interaction requires Phase 2. See https://github.com/PGhostek/iosdevctl#roadmap",
  "suggestion": "Install idb Python client as a temporary workaround: pip install fb-idb"
}
```

## Temporary Workaround

Until Phase 2 ships, use Meta's `idb` Python client:

```bash
pip install fb-idb

# Start the idb_companion daemon (already installed with iosdevctl dependencies)
idb_companion --udid <udid> &

# Use idb for UI interactions
idb tap 195 422
idb type "hello world"
idb press-button HOME
```
