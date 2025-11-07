#!/usr/bin/env python3
"""OpenRewrite MCP Server - Main server implementation."""
import sys
import logging
from typing import Optional
from mcp.server import Server
from mcp.types import Tool, TextContent
import mcp.server.stdio

from config import config
from db.connection import init_pool, close_pool
from tools.test_connection import test_connection
from tools.find_recipes import find_recipes
from tools.get_recipe import get_recipe


# Configure logging to stderr only (CRITICAL: never stdout, corrupts JSON-RPC)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stderr)]
)
logger = logging.getLogger(__name__)


# Initialize MCP server
app = Server(config.SERVER_NAME)


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="test_connection",
            description="Test the MCP server connection. Returns status and echoes an optional message.",
            inputSchema={
                "type": "object",
                "properties": {
                    "message": {
                        "type": "string",
                        "description": "Optional message to echo back"
                    }
                }
            }
        ),
        Tool(
            name="find_recipes",
            description="Find OpenRewrite recipes based on user intent. Uses semantic search to discover relevant recipes for code transformations, migrations, and refactorings.",
            inputSchema={
                "type": "object",
                "properties": {
                    "intent": {
                        "type": "string",
                        "description": "Description of what you want to accomplish (e.g., 'migrate to Spring Boot 3', 'upgrade to Java 17', 'fix security issues')"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of results to return",
                        "default": 5,
                        "minimum": 1,
                        "maximum": 20
                    },
                    "min_score": {
                        "type": "number",
                        "description": "Minimum relevance score threshold (0.0 to 1.0)",
                        "default": 0.5,
                        "minimum": 0.0,
                        "maximum": 1.0
                    }
                },
                "required": ["intent"]
            }
        ),
        Tool(
            name="get_recipe",
            description="Get detailed documentation for a specific OpenRewrite recipe. Returns complete information including usage instructions, examples, and configuration options.",
            inputSchema={
                "type": "object",
                "properties": {
                    "recipe_id": {
                        "type": "string",
                        "description": "Unique identifier for the recipe (e.g., 'org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0')"
                    }
                },
                "required": ["recipe_id"]
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Handle tool calls."""
    try:
        logger.info(f"Tool called: {name} with arguments: {arguments}")

        if name == "test_connection":
            result = await test_connection(arguments.get("message"))
            return [TextContent(type="text", text=str(result))]

        elif name == "find_recipes":
            intent = arguments["intent"]
            limit = arguments.get("limit")
            min_score = arguments.get("min_score")

            results = await find_recipes(intent, limit, min_score)

            if not results:
                return [TextContent(
                    type="text",
                    text=f"No recipes found matching '{intent}' with the given criteria. Try lowering min_score or using different keywords."
                )]

            # Format results as readable text
            output = f"Found {len(results)} recipe(s) matching '{intent}':\n\n"
            for i, recipe in enumerate(results, 1):
                output += f"{i}. **{recipe['name']}** (score: {recipe['relevance_score']})\n"
                output += f"   ID: `{recipe['recipe_id']}`\n"
                output += f"   Description: {recipe['description']}\n"
                output += f"   Tags: {', '.join(recipe['tags'])}\n\n"

            return [TextContent(type="text", text=output)]

        elif name == "get_recipe":
            recipe_id = arguments["recipe_id"]

            try:
                recipe = await get_recipe(recipe_id)
            except ValueError as e:
                return [TextContent(type="text", text=f"Error: {str(e)}")]

            # Format recipe documentation
            output = f"# {recipe['name']}\n\n"
            output += f"**Recipe ID:** `{recipe['recipe_id']}`\n\n"
            output += f"**Description:** {recipe['description']}\n\n"

            if recipe['full_documentation']:
                output += f"{recipe['full_documentation']}\n\n"

            output += f"## Usage\n\n{recipe['usage_instructions']}\n\n"

            if recipe['examples']:
                output += "## Examples\n\n"
                for example in recipe['examples']:
                    output += f"### {example['title']}\n\n"
                    output += f"**Before:**\n```java\n{example['before']}\n```\n\n"
                    output += f"**After:**\n```java\n{example['after']}\n```\n\n"

            if recipe['options']:
                output += "## Configuration Options\n\n"
                for option in recipe['options']:
                    output += f"- **{option['name']}** ({option['type']}): {option['description']}\n"
                    output += f"  Default: `{option['default']}`\n"

            output += f"\n**Tags:** {', '.join(recipe['tags'])}\n"
            output += f"\n**Documentation:** {recipe['source_url']}\n"

            return [TextContent(type="text", text=output)]

        else:
            return [TextContent(type="text", text=f"Unknown tool: {name}")]

    except Exception as e:
        logger.error(f"Error executing tool {name}: {e}", exc_info=True)
        return [TextContent(type="text", text=f"Error: {str(e)}")]


async def main():
    """Run the MCP server."""
    logger.info(f"Starting {config.SERVER_NAME} v{config.SERVER_VERSION}")

    # Initialize database connection pool (required - server will fail if DB unavailable)
    try:
        await init_pool(
            host=config.DB_HOST,
            port=config.DB_PORT,
            database=config.DB_NAME,
            user=config.DB_USER,
            password=config.DB_PASSWORD
        )
        logger.info("Database connection established")
    except Exception as e:
        logger.error(f"Failed to connect to database: {e}")
        logger.error("Server cannot start without database connection")
        sys.exit(1)

    logger.info("Server ready to accept connections via stdio")

    try:
        async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
            await app.run(
                read_stream,
                write_stream,
                app.create_initialization_options()
            )
    finally:
        # Cleanup on shutdown
        await close_pool()
        logger.info("Server shutdown complete")


if __name__ == "__main__":
    import asyncio
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}", exc_info=True)
        sys.exit(1)
