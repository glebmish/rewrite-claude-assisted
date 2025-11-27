#!/usr/bin/env python3
import sys
from fastmcp import FastMCP

# Initialize the MCP server
mcp = FastMCP("log-mcp-server")

@mcp.tool()
def log(message: str) -> str:
    """Write a message to stderr for logging purposes"""
    sys.stderr.write(message + "\n")
    sys.stderr.flush()
    return f"Logged message to stderr: {message}"

if __name__ == "__main__":
    mcp.run()
