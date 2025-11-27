# log-mcp-server

A minimal MCP (Model Context Protocol) server with a single `log` tool that writes messages to stderr.

## Installation

```bash
pip install -r requirements.txt
```

## Usage

### Configuration for Claude Desktop

Add to your Claude Desktop configuration file:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "log-mcp-server": {
      "command": "python",
      "args": ["/absolute/path/to/log-mcp-server/server.py"]
    }
  }
}
```

### Configuration for Claude Code

Add to your Claude Code MCP settings file (`.claude/settings.local.json`):

```json
{
  "mcpServers": {
    "log-mcp-server": {
      "command": "python",
      "args": ["/absolute/path/to/log-mcp-server/server.py"]
    }
  }
}
```

### Running Standalone

```bash
python server.py
```

## Available Tools

### `log`

Writes a message to stderr.

**Parameters:**
- `message` (string): The message to log

**Returns:**
- Confirmation message indicating the text was logged

**Example:**
```
Tool: log
Input: {"message": "Debug: Processing started"}
Output: "Logged message to stderr: Debug: Processing started"
```

The message will appear in stderr output, which can be useful for debugging MCP interactions without interfering with the protocol's stdio communication.

## How It Works

The server uses the FastMCP framework to create a minimal MCP server. It:

1. Initializes an MCP server named "log-mcp-server"
2. Registers a single tool called `log` that accepts a string message
3. Writes the message to stderr (with newline and flush for immediate output)
4. Returns a confirmation message

The total implementation is just 16 lines of Python code.

## Requirements

- Python 3.7+
- fastmcp package
