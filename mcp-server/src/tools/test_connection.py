"""Test connection tool for verifying MCP server connectivity."""
from datetime import datetime
from typing import Optional


async def test_connection(message: Optional[str] = None) -> dict:
    """
    Test the MCP server connection.

    A simple echo/ping tool to verify that the MCP protocol is working correctly.

    Args:
        message: Optional message to echo back

    Returns:
        Dictionary with status, timestamp, and echoed message
    """
    timestamp = datetime.now().isoformat()

    response = {
        "status": "connected",
        "timestamp": timestamp,
        "server": "openrewrite-mcp",
        "version": "0.1.0"
    }

    if message:
        response["echo"] = message
    else:
        response["echo"] = "Connection successful!"

    return response
