# status-bar

Override or clear the simulator status bar — useful for producing clean screenshots and App Store assets.

## Subcommands

| Subcommand | Description |
|---|---|
| [`status-bar override`](#status-bar-override) | Override status bar properties |
| [`status-bar clear`](#status-bar-clear) | Restore default status bar |

---

## status-bar override

Override one or more status bar properties on a booted simulator.

```
iosdevctl status-bar override [--device <udid-or-name>] [--time <time>] [--battery-level <0-100>] [--battery-state <state>] [--network <type>] [--pretty]
```

### Options

| Flag | Type | Description |
|---|---|---|
| `--device` | string | Device UDID or name. Auto-selects if one simulator is booted. |
| `--time` | string | Time to display (e.g. `"9:41"`) |
| `--battery-level` | integer | Battery percentage, 0–100 |
| `--battery-state` | string | `charging`, `charged`, or `discharging` |
| `--network` | string | `wifi`, `lte`, `4g`, `3g`, `2g`, `edge`, `gprs`, or `none` |
| `--pretty` | flag | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Status bar overridden successfully.",
  "overrides": {
    "time": "9:41",
    "batteryLevel": 100,
    "batteryState": "charged",
    "network": "wifi"
  },
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
# Classic App Store screenshot setup: 9:41, full battery, WiFi
iosdevctl status-bar override --time "9:41" --battery-level 100 --battery-state charged --network wifi

# Show charging indicator
iosdevctl status-bar override --battery-state charging --battery-level 72

# Simulate no network
iosdevctl status-bar override --network none

# Override only the time
iosdevctl status-bar override --time "12:00"
```

### Notes

- The simulator must be **booted**.
- Overrides persist until `status-bar clear` is called or the simulator is restarted.
- `9:41` is the traditional Apple marketing time (used in keynotes and App Store screenshots).

---

## status-bar clear

Clear all status bar overrides and restore the simulator's real status bar.

```
iosdevctl status-bar clear [--device <udid-or-name>] [--pretty]
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
  "message": "Status bar overrides cleared.",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
# Restore real status bar after taking screenshots
iosdevctl status-bar clear
```
