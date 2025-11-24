#!/usr/bin/env python3
"""OpenRewrite MCP Server - Main server implementation."""
import sys
import logging
import json
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
            return [TextContent(type="text", text=json.dumps(result, indent=2))]

        elif name == "find_recipes":
            intent = arguments["intent"]
            limit = arguments.get("limit")
            min_score = arguments.get("min_score")

            results = await find_recipes(intent, limit, min_score)

            if not results:
                response = {
                    "recipes": [],
                    "total_count": 0,
                    "query": intent,
                    "message": "No recipes found matching the given criteria. Try lowering min_score or using different keywords."
                }
                return [TextContent(type="text", text=json.dumps(response, indent=2))]

            # Return structured JSON response
            response = {
                "recipes": [
                    {
                        "id": recipe["recipe_id"],
                        "name": recipe["name"],
                        "description": recipe["description"],
                        "tags": recipe["tags"],
                        "score": recipe["relevance_score"]
                    }
                    for recipe in results
                ],
                "total_count": len(results),
                "query": intent
            }
            return [TextContent(type="text", text=json.dumps(response, indent=2))]

        elif name == "get_recipe":
            recipe_id = arguments["recipe_id"]

            try:
                recipe = await get_recipe(recipe_id)
            except ValueError as e:
                error_response = {
                    "error": str(e),
                    "recipe_id": recipe_id
                }
                return [TextContent(type="text", text=json.dumps(error_response, indent=2))]

            # Return structured JSON with recipe details
            response = {
                "recipe_id": recipe["recipe_id"],
                "markdown_documentation": recipe["markdown_documentation"]
            }
            return [TextContent(type="text", text=json.dumps(response, indent=2))]

        else:
            error_response = {"error": f"Unknown tool: {name}"}
            return [TextContent(type="text", text=json.dumps(error_response, indent=2))]

    except Exception as e:
        logger.error(f"Error executing tool {name}: {e}", exc_info=True)
        error_response = {"error": str(e), "tool": name}
        return [TextContent(type="text", text=json.dumps(error_response, indent=2))]


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
