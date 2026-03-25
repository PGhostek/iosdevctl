# device

Manage iOS simulators — list, boot, shutdown, take screenshots, and record the screen.

## Subcommands

| Subcommand | Description |
|---|---|
| [`device list`](#device-list) | List all available simulators |
| [`device boot`](#device-boot) | Boot a simulator |
| [`device shutdown`](#device-shutdown) | Shutdown a simulator |
| [`device screenshot`](#device-screenshot) | Take a screenshot |
| [`device record start`](#device-record-start) | Start screen recording |
| [`device record stop`](#device-record-stop) | Stop screen recording |

---

## device list

List all available simulators with their state, UDID, and runtime.

```
iosdevctl device list [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--pretty` | Pretty-print JSON output |

### Output

Returns a JSON array of simulator objects.

```json
[
  {
    "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
    "name": "iPhone 17 Pro",
    "state": "Booted",
    "runtime": "iOS 26.2",
    "available": true
  },
  {
    "udid": "7C04B005-90CE-40A9-BB7B-660F11FDA77C",
    "name": "iPhone 17 Pro Max",
    "state": "Shutdown",
    "runtime": "iOS 26.2",
    "available": true
  }
]
```

| Field | Type | Description |
|---|---|---|
| `udid` | string | Unique device identifier |
| `name` | string | Simulator display name |
| `state` | string | `"Booted"` or `"Shutdown"` |
| `runtime` | string | iOS version (e.g. `"iOS 26.2"`) |
| `available` | boolean | Whether the simulator is usable |

### Examples

```bash
# List all simulators
iosdevctl device list

# List and filter booted simulators with jq
iosdevctl device list | jq '.[] | select(.state == "Booted")'

# Get UDIDs of all available simulators
iosdevctl device list | jq -r '.[].udid'
```

---

## device boot

Boot a simulator.

```
iosdevctl device boot [--device <udid-or-name>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Device booted successfully.",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
  "name": "iPhone 17 Pro"
}
```

If the device is already booted, returns the same shape with `"message": "Device already booted."`.

### Examples

```bash
iosdevctl device boot --device "iPhone 17 Pro"
iosdevctl device boot --device "A07C8D70-4443-4C52-8270-F1228996DA09"
```

---

## device shutdown

Shutdown a booted simulator.

```
iosdevctl device shutdown [--device <udid-or-name>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Device shut down successfully.",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
  "name": "iPhone 17 Pro"
}
```

### Examples

```bash
iosdevctl device shutdown
iosdevctl device shutdown --device "iPhone 17 Pro"
```

---

## device screenshot

Capture a screenshot from a booted simulator.

```
iosdevctl device screenshot [--device <udid-or-name>] [--output <path>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--output` | Output file path. Defaults to `/tmp/iosdevctl-screenshot-<timestamp>.png` |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "path": "/tmp/iosdevctl-screenshot-1742900000.png",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
# Screenshot with auto-generated filename
iosdevctl device screenshot

# Screenshot to a specific path
iosdevctl device screenshot --output ~/Desktop/screen.png

# Screenshot and open immediately
iosdevctl device screenshot --output /tmp/screen.png && open /tmp/screen.png

# Screenshot and extract the path
SCREENSHOT=$(iosdevctl device screenshot | jq -r '.path')
```

### Notes

- The simulator must be **booted**. Use `device boot` first if needed.
- Output format is always PNG.

---

## device record start

Start recording the simulator screen to a video file.

```
iosdevctl device record start --output <path> [--device <udid-or-name>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--output` | *(required)* Output video file path (`.mp4`) |
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Recording started.",
  "pid": 12345,
  "output": "/tmp/recording.mp4",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Notes

- The recording PID is saved to `/tmp/iosdevctl-recording.pid` for use by `record stop`.
- Only one recording can be active at a time.
- The simulator must be **booted**.

---

## device record stop

Stop an active screen recording.

```
iosdevctl device record stop [--device <udid-or-name>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name (optional for stop) |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Recording stopped.",
  "pid": 12345
}
```

### Examples

```bash
# Start a recording
iosdevctl device record start --output /tmp/test-run.mp4

# ... do things in the simulator ...

# Stop and finalize the video
iosdevctl device record stop
```

### Notes

- Sends `SIGINT` to the recording process to allow the video to be properly finalized before the process exits.
- Errors if no recording is in progress.
