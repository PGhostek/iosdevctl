# pasteboard

Read and write the simulator's clipboard (pasteboard).

## Subcommands

| Subcommand | Description |
|---|---|
| [`pasteboard get`](#pasteboard-get) | Read the current clipboard content |
| [`pasteboard set`](#pasteboard-set) | Write content to the clipboard |

---

## pasteboard get

Read the current content of the simulator's clipboard.

```
iosdevctl pasteboard get [--device <udid-or-name>] [--pretty]
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
  "content": "Hello from the simulator!",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
# Get clipboard content
iosdevctl pasteboard get

# Extract just the content
iosdevctl pasteboard get | jq -r '.content'
```

---

## pasteboard set

Write text content to the simulator's clipboard.

```
iosdevctl pasteboard set <content> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `content` | Text content to write to the clipboard |

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "Pasteboard updated successfully.",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
# Set clipboard to a test value
iosdevctl pasteboard set "test@example.com"

# Pre-fill clipboard before launching app
iosdevctl pasteboard set "https://example.com/invite/abc123"
iosdevctl app launch com.example.myapp
```

### Notes

- The simulator must be **booted**.
- Useful for pre-filling text fields (paste content after tapping into a field), testing paste functionality, and sharing content between host and simulator.
- Currently supports text content only. Binary/image pasteboard items are not supported.
