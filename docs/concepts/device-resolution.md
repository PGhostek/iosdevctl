# Device Resolution

Most `iosdevctl` commands accept an optional `--device` flag to specify which simulator to target. This document explains how device resolution works.

## The `--device` Flag

```bash
iosdevctl device screenshot --device "iPhone 17 Pro"
iosdevctl device screenshot --device "A07C8D70-4443-4C52-8270-F1228996DA09"
```

You can pass either:
- **A device name** — matched case-insensitively (e.g. `"iphone 17 pro"` works)
- **A UDID** — matched exactly (e.g. `A07C8D70-4443-4C52-8270-F1228996DA09`)

## Auto-Selection (No `--device`)

If `--device` is omitted, iosdevctl auto-selects a device using this logic:

1. Count all currently booted simulators
2. If **exactly one** is booted → use it
3. If **none** are booted → error `NO_DEVICE_BOOTED`
4. If **two or more** are booted → error `MULTIPLE_DEVICES_BOOTED`

This means for most workflows where you have a single active simulator, you never need to specify `--device`.

## Name Matching

When resolving by name, iosdevctl:
1. Searches all available simulators across all runtimes
2. Prefers a **booted** match over a shutdown match
3. Returns the first match if multiple simulators share the same name

```bash
# If you have both an iOS 16 and iOS 17 "iPhone 15", the booted one is preferred
iosdevctl device screenshot --device "iPhone 15"
```

## Finding Device Identifiers

```bash
# List all available simulators with their UDIDs
iosdevctl device list --pretty

# Example output:
# [
#   {
#     "udid": "A07C8D70-4443-4C52-8270-F1228996DA09",
#     "name": "iPhone 17 Pro",
#     "state": "Booted",
#     "runtime": "iOS 26.2",
#     "available": true
#   },
#   ...
# ]
```

## Error Messages

```json
{
  "status": "error",
  "code": "NO_DEVICE_BOOTED",
  "message": "No simulator is currently booted.",
  "suggestion": "Boot a simulator with: iosdevctl device boot --device \"iPhone 17 Pro\""
}
```

```json
{
  "status": "error",
  "code": "MULTIPLE_DEVICES_BOOTED",
  "message": "Multiple simulators are booted. Specify one with --device.",
  "suggestion": "Run 'iosdevctl device list' to see booted simulators, then use --device <udid>."
}
```

```json
{
  "status": "error",
  "code": "DEVICE_NOT_FOUND",
  "message": "No simulator found matching \"iPhone 99\".",
  "suggestion": "Run 'iosdevctl device list' to see available simulators."
}
```
