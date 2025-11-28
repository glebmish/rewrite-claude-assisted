#!/usr/bin/env python3
import sys
import argparse
from datetime import datetime
from fastmcp import FastMCP

# Parse command line arguments
parser = argparse.ArgumentParser(description='Log MCP Server')
parser.add_argument('--log-file', type=str, help='Path to log file')
args = parser.parse_args()

mcp = FastMCP("log-mcp-server")

@mcp.tool()
def log(message: str) -> str:
    """Write a message to configured log destination"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{timestamp}] [MCP] {message}\n"

    if args.log_file:
        # Write to file with immediate flush
        try:
            with open(args.log_file, 'a') as f:
                f.write(log_line)
                f.flush()
        except Exception as e:
            sys.stderr.write(f"Error writing to log file: {e}\n")
            sys.stderr.flush()
    else:
        # Fallback to stderr
        sys.stderr.write(log_line)
        sys.stderr.flush()

    return f"Logged: {message}"

if __name__ == "__main__":
    mcp.run()
