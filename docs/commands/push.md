# push

Send simulated push notifications to apps on a simulator.

## Subcommands

| Subcommand | Description |
|---|---|
| [`push send`](#push-send) | Send a push notification payload to an app |

---

## push send

Send a push notification payload JSON file to a specific app on a simulator.

```
iosdevctl push send <bundle-id> <payload-file> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `bundle-id` | Bundle identifier of the target app |
| `payload-file` | Path to the APNS payload JSON file |

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Push notification sent successfully.",
  "bundleId": "com.example.myapp",
  "payloadFile": "payload.json",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Payload Format

The payload file must be a valid APNS payload JSON file. The `"Simulator Target Bundle"` key can optionally be included to override the bundle ID:

```json
{
  "Simulator Target Bundle": "com.example.myapp",
  "aps": {
    "alert": {
      "title": "New Message",
      "body": "You have a new message from Alice."
    },
    "badge": 1,
    "sound": "default"
  }
}
```

### Examples

```bash
# Send a basic push notification
iosdevctl push send com.example.myapp payload.json

# Send to a specific device
iosdevctl push send com.example.myapp payload.json --device "iPhone 17 Pro"
```

### Notes

- The simulator must be **booted**.
- The app must be installed on the simulator.
- The app does not need to be running — push notifications can wake it.
- Useful for testing notification handling, deep links from notifications, and badge counts.
