# app

Manage apps on iOS simulators — install, launch, terminate, and list installed apps.

## Subcommands

| Subcommand | Description |
|---|---|
| [`app install`](#app-install) | Install an app on a simulator |
| [`app launch`](#app-launch) | Launch an installed app |
| [`app terminate`](#app-terminate) | Terminate a running app |
| [`app list`](#app-list) | List all installed apps |

---

## app install

Install an `.app` bundle or `.ipa` file on a simulator.

```
iosdevctl app install --path <path> [--device <udid-or-name>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--path` | *(required)* Path to the `.app` bundle or `.ipa` file |
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "App installed successfully.",
  "path": "/path/to/MyApp.app",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
iosdevctl app install --path .build/Debug-iphonesimulator/MyApp.app
iosdevctl app install --path MyApp.app --device "iPhone 17 Pro"
```

### Notes

- The simulator must be **booted**.
- The app must be built for the simulator architecture (`x86_64` or `arm64` simulator slice).
- `.ipa` files are supported but may require simulator-compatible builds.

---

## app launch

Launch an installed app by bundle identifier.

```
iosdevctl app launch <bundle-id> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `bundle-id` | Bundle identifier of the app (e.g. `com.example.myapp`) |

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "App launched successfully.",
  "bundleId": "com.example.myapp",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
iosdevctl app launch com.example.myapp
iosdevctl app launch com.apple.mobilesafari
```

### Error Codes

| Code | Meaning |
|---|---|
| `APP_NOT_FOUND` (exit 3) | Bundle ID not installed on the device |
| `DEVICE_NOT_BOOTED` (exit 4) | Simulator is not booted |

---

## app terminate

Terminate a running app by bundle identifier.

```
iosdevctl app terminate <bundle-id> [--device <udid-or-name>] [--pretty]
```

### Arguments

| Argument | Description |
|---|---|
| `bundle-id` | Bundle identifier of the running app |

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

```json
{
  "status": "ok",
  "message": "App terminated successfully.",
  "bundleId": "com.example.myapp",
  "device": "iPhone 17 Pro",
  "udid": "A07C8D70-4443-4C52-8270-F1228996DA09"
}
```

### Examples

```bash
iosdevctl app terminate com.example.myapp
```

---

## app list

List all apps installed on a simulator.

```
iosdevctl app list [--device <udid-or-name>] [--pretty]
```

### Options

| Flag | Description |
|---|---|
| `--device` | Device UDID or name. Auto-selects if one simulator is booted. |
| `--pretty` | Pretty-print JSON output |

### Output

Returns a JSON array sorted by bundle ID.

```json
[
  {
    "bundleId": "com.apple.mobilesafari",
    "name": "Safari",
    "version": "26.0",
    "path": "/Applications/Xcode.app/.../Safari.app"
  },
  {
    "bundleId": "com.example.myapp",
    "name": "My App",
    "version": "1.0.0",
    "path": "/Users/.../data/Containers/Bundle/Application/.../MyApp.app"
  }
]
```

| Field | Type | Description |
|---|---|---|
| `bundleId` | string | App bundle identifier |
| `name` | string | Display name (`CFBundleDisplayName` or `CFBundleName`) |
| `version` | string | Short version string (`CFBundleShortVersionString`) |
| `path` | string | File system path to the installed `.app` bundle |

### Examples

```bash
# List all apps
iosdevctl app list

# Find a specific app
iosdevctl app list | jq '.[] | select(.bundleId | contains("example"))'

# Get just bundle IDs
iosdevctl app list | jq -r '.[].bundleId'
```

### Notes

- The simulator must be **booted**.
- Includes both system apps and user-installed apps.
