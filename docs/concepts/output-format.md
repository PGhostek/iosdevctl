# Output Format & Exit Codes

## JSON-First Output

Every `iosdevctl` command outputs JSON to stdout. This makes it easy to pipe into `jq`, parse in scripts, or consume in AI agents without screen-scraping.

Use `--pretty` on any command for human-readable indented output:

```bash
iosdevctl device list --pretty
```

### Success Response

Successful commands return a JSON object or array. The shape varies by command but always contains a `"status": "ok"` key for operations (as opposed to queries which return the data directly).

**Query example** (`device list`):
```json
[
  {
    "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
    "name": "iPhone 17 Pro",
    "state": "Booted",
    "runtime": "iOS 26.2",
    "available": true
  }
]
```

**Operation example** (`device boot`):
```json
{
  "status": "ok",
  "message": "Device booted successfully.",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
  "name": "iPhone 17 Pro"
}
```

### Error Response

Errors are written to stderr as a JSON object with three fields:

```json
{
  "status": "error",
  "code": "DEVICE_NOT_FOUND",
  "message": "No simulator found matching \"iPhone 99\".",
  "suggestion": "Run 'iosdevctl device list' to see available simulators."
}
```

| Field | Description |
|---|---|
| `code` | Machine-readable error identifier (see table below) |
| `message` | Human-readable description of what went wrong |
| `suggestion` | Actionable next step to resolve the error |

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | General error (command failed, invalid argument, etc.) |
| `2` | Device not found |
| `3` | App not found |
| `4` | Device not booted |

## Error Codes

| Code | Exit | Description |
|---|---|---|
| `DEVICE_NOT_FOUND` | 2 | No simulator matched the provided name or UDID |
| `MULTIPLE_DEVICES_BOOTED` | 2 | `--device` was omitted but multiple simulators are booted |
| `NO_DEVICE_BOOTED` | 2 | `--device` was omitted but no simulator is booted |
| `DEVICE_NOT_BOOTED` | 4 | The target simulator is not in a booted state |
| `APP_NOT_FOUND` | 3 | Bundle ID not found on the device |
| `FILE_NOT_FOUND` | 1 | A required file path doesn't exist |
| `BOOT_FAILED` | 1 | `xcrun simctl boot` returned a non-zero exit code |
| `SHUTDOWN_FAILED` | 1 | `xcrun simctl shutdown` returned a non-zero exit code |
| `INSTALL_FAILED` | 1 | App installation failed |
| `LAUNCH_FAILED` | 1 | App launch failed |
| `TERMINATE_FAILED` | 1 | App termination failed |
| `SCREENSHOT_FAILED` | 1 | Screenshot capture failed |
| `RECORD_FAILED` | 1 | Screen recording failed to start |
| `RECORDING_ALREADY_IN_PROGRESS` | 1 | A recording is already running |
| `NO_RECORDING_IN_PROGRESS` | 1 | `record stop` called with no active recording |
| `PUSH_FAILED` | 1 | Push notification delivery failed |
| `URL_OPEN_FAILED` | 1 | URL could not be opened |
| `PASTEBOARD_GET_FAILED` | 1 | Clipboard read failed |
| `PASTEBOARD_SET_FAILED` | 1 | Clipboard write failed |
| `STATUS_BAR_FAILED` | 1 | Status bar override failed |
| `INVALID_ARGUMENT` | 1 | An argument value is out of valid range |
| `NOT_IMPLEMENTED` | 1 | Feature is planned but not yet available (Phase 2+) |
| `PARSE_FAILED` | 1 | Failed to parse output from underlying tool |

## Parsing Output in Scripts

```bash
# Get the UDID of the booted simulator
UDID=$(iosdevctl device list | jq -r '.[] | select(.state == "Booted") | .udid' | head -1)

# Take a screenshot and get the path
PATH=$(iosdevctl device screenshot | jq -r '.path')

# Check for errors
OUTPUT=$(iosdevctl app launch com.example.app 2>&1)
if [ $? -ne 0 ]; then
  echo "Error: $(echo $OUTPUT | jq -r '.message')"
fi
```
