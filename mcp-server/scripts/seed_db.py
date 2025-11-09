#!/usr/bin/env python3
"""Seed database with initial recipe data from Phase 1 mock data."""
import asyncio
import asyncpg
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

# Import existing mock data
from tools.find_recipes import MOCK_RECIPES
from tools.get_recipe import MOCK_RECIPE_DOCS


def generate_markdown_from_mock(recipe_data: dict, full_doc: dict = None) -> str:
    """Generate markdown documentation from mock recipe data."""
    recipe_id = recipe_data['recipe_id']
    name = recipe_data['name']
    description = recipe_data['description']
    tags = recipe_data.get('tags', [])

    # Start with basic structure
    markdown = f"""---
sidebar_label: "{name}"
---

# {name}

**{recipe_id}**

_{description}_

### Tags

{chr(10).join(f'* {tag}' for tag in tags) if tags else '* No tags'}

## Recipe source

This is a placeholder recipe for Phase 2 testing.
"""

    # Add full documentation if available
    if full_doc:
        if full_doc.get('full_documentation'):
            markdown += f"\n{full_doc['full_documentation']}\n"

        if full_doc.get('usage_instructions'):
            markdown += f"\n## Usage\n\n{full_doc['usage_instructions']}\n"

        # Add examples
        if full_doc.get('examples'):
            markdown += "\n## Examples\n\n"
            for example in full_doc['examples']:
                markdown += f"### {example['title']}\n\n"
                markdown += f"**Before:**\n```java\n{example['before']}\n```\n\n"
                markdown += f"**After:**\n```java\n{example['after']}\n```\n\n"

        # Add options
        if full_doc.get('options'):
            markdown += "\n## Options\n\n"
            markdown += "| Type | Name | Description | Default |\n"
            markdown += "| -- | -- | -- | -- |\n"
            for option in full_doc['options']:
                markdown += f"| `{option['type']}` | {option['name']} | {option['description']} | `{option['default']}` |\n"

    return markdown


async def seed_database(
    host: str = "localhost",
    port: int = 5432,
    database: str = "openrewrite_recipes",
    user: str = "mcp_user",
    password: str = "changeme"
):
    """Populate database with mock data."""
    print(f"Connecting to database {database} at {host}:{port}...")

    try:
        conn = await asyncpg.connect(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password,
            timeout=10
        )
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}", file=sys.stderr)
        print(f"   Make sure PostgreSQL is running: docker-compose up -d", file=sys.stderr)
        sys.exit(1)

    try:
        print(f"Seeding {len(MOCK_RECIPES)} recipes...")

        for recipe_data in MOCK_RECIPES:
            recipe_name = recipe_data['recipe_id']
            print(f"  - {recipe_data['name']}")

            # Get full documentation if available
            full_doc = MOCK_RECIPE_DOCS.get(recipe_name)

            # Generate markdown
            markdown_doc = generate_markdown_from_mock(recipe_data, full_doc)

            # Insert recipe with markdown
            await conn.execute("""
                INSERT INTO recipes (recipe_name, markdown_doc)
                VALUES ($1, $2)
                ON CONFLICT (recipe_name) DO UPDATE
                SET markdown_doc = EXCLUDED.markdown_doc,
                    updated_at = NOW()
            """, recipe_name, markdown_doc)

        count = await conn.fetchval("SELECT COUNT(*) FROM recipes")
        print(f"\n✅ Database seeded successfully with {count} recipes")

    except Exception as e:
        print(f"❌ Error seeding database: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        await conn.close()


if __name__ == "__main__":
    # Read from environment or use defaults
    host = os.getenv("DB_HOST", "localhost")
    port = int(os.getenv("DB_PORT", "5432"))
    database = os.getenv("DB_NAME", "openrewrite_recipes")
    user = os.getenv("DB_USER", "mcp_user")
    password = os.getenv("DB_PASSWORD", "changeme")

    asyncio.run(seed_database(host, port, database, user, password))
