# url

Open URLs and deep links on a simulator.

## Subcommands

| Subcommand | Description |
|---|---|
| [`url open`](#url-open) | Open a URL or deep link |

---

## url open

Open a URL or deep link on a booted simulator. Works with `https://` URLs (opens in Safari) and custom URL schemes (opens the registered app).

```
iosdevctl url open <url> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `url` | URL or deep link to open |

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "URL opened successfully.",
  "url": "https://apple.com",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
# Open a web URL in Safari
iosdevctl url open "https://apple.com"

# Open a deep link into your app
iosdevctl url open "myapp://profile/123"

# Test universal links
iosdevctl url open "https://myapp.com/profile/123"

# Open App Store page
iosdevctl url open "https://apps.apple.com/app/id123456789"
```

### Notes

- The simulator must be **booted**.
- For custom URL schemes, the app handling that scheme must be installed.
- Useful for testing deep link routing, onboarding flows, and universal link handling.
