# mcp

Start an MCP (Model Context Protocol) JSON-RPC server over stdin/stdout. Allows Claude Desktop, Cursor, and any MCP-compatible client to call all `iosdevctl` capabilities as native tools.

## Subcommands

| Subcommand | Description |
|---|---|
| [`mcp serve`](#mcp-serve) | Start the MCP server (default) |

---

## mcp serve

```
iosdevctl mcp serve
```

Reads newline-delimited JSON-RPC 2.0 requests from stdin and writes responses to stdout. Follows the [MCP specification (2024-11-05)](https://modelcontextprotocol.io).

Each `tools/call` re-invokes the `iosdevctl` binary with the appropriate arguments, so all existing command logic, error handling, and exit codes are reused unchanged.

### Setup — Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "iosdevctl": {
      "command": "/usr/local/bin/iosdevctl",
      "args": ["mcp", "serve"]
    }
  }
}
```

If running from a local build:

```json
{
  "mcpServers": {
    "iosdevctl": {
      "command": "/path/to/iosdevctl/.build/release/iosdevctl",
      "args": ["mcp", "serve"]
    }
  }
}
```

Restart Claude Desktop after editing the config.

### Manual testing

```bash
# Handshake
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"test"}}}' \
  | iosdevctl mcp serve

# List all tools
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | iosdevctl mcp serve

# Call a tool
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"device_list","arguments":{}}}' \
  | iosdevctl mcp serve
```

---

## Available tools

All 17 tools mirror their CLI equivalents. The `device` parameter is always optional — if omitted, the single booted simulator is used.

### Device tools

| Tool | CLI equivalent | Required params |
|---|---|---|
| `device_list` | `device list` | — |
| `device_boot` | `device boot` | — |
| `device_shutdown` | `device shutdown` | — |
| `device_screenshot` | `device screenshot` | `output` (file path) |

### App tools

| Tool | CLI equivalent | Required params |
|---|---|---|
| `app_list` | `app list` | — |
| `app_launch` | `app launch` | `bundle_id` |
| `app_terminate` | `app terminate` | `bundle_id` |

### UI tools

| Tool | CLI equivalent | Required params |
|---|---|---|
| `ui_tap` | `ui tap` | `x`, `y` |
| `ui_swipe` | `ui swipe` | `x1`, `y1`, `x2`, `y2` |
| `ui_type` | `ui type` | `text` |
| `ui_long_press` | `ui long-press` | `x`, `y` |
| `ui_tree` | `ui tree` | — |
| `ui_element_tap` | `ui element-tap` | `identifier` |
| `ui_button` | `ui button` | `name` |

### Utility tools

| Tool | CLI equivalent | Required params |
|---|---|---|
| `pasteboard_get` | `pasteboard get` | — |
| `pasteboard_set` | `pasteboard set` | `value` |
| `url_open` | `url open` | `url` |

---

## Response format

Successful tool calls return:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{"type": "text", "text": "<iosdevctl JSON output>"}],
    "isError": false
  }
}
```

Failed tool calls (non-zero exit from the CLI) return the same shape with `"isError": true` and the error JSON in `text`.

---

## Error codes

| Code | Meaning |
|---|---|
| `-32700` | Parse error — request was not valid JSON |
| `-32600` | Invalid request — `method` field missing |
| `-32601` | Method not found |
| `-32602` | Invalid params — missing required field or unknown tool name |
