"""Database queries for recipes."""
import logging
from typing import List, Dict, Optional

from db.connection import get_connection

logger = logging.getLogger(__name__)


async def find_all_recipes(limit: int = 5) -> List[Dict]:
    """
    Find recipes from database.

    Phase 2: Simple implementation - returns all recipes (ignores search intent).
    Phase 3: Will use vector similarity search with embeddings.

    Args:
        limit: Maximum number of recipes to return

    Returns:
        List of recipe dictionaries with basic information
    """
    async with get_connection() as conn:
        results = await conn.fetch("""
            SELECT
                recipe_id,
                name,
                description,
                tags
            FROM recipes
            ORDER BY name
            LIMIT $1
        """, limit)

        return [
            {
                'recipe_id': r['recipe_id'],
                'name': r['name'],
                'description': r['description'],
                'tags': list(r['tags']) if r['tags'] else [],
                'relevance_score': 1.0  # Placeholder for Phase 3
            }
            for r in results
        ]


async def get_recipe_details(recipe_id: str) -> Optional[Dict]:
    """
    Get full recipe details including examples and options.

    Args:
        recipe_id: Unique recipe identifier

    Returns:
        Dictionary with full recipe details, or None if not found
    """
    async with get_connection() as conn:
        # Fetch recipe
        recipe = await conn.fetchrow("""
            SELECT * FROM recipes WHERE recipe_id = $1
        """, recipe_id)

        if not recipe:
            return None

        # Fetch examples
        examples = await conn.fetch("""
            SELECT title, before_code, after_code
            FROM recipe_examples
            WHERE recipe_id = $1
            ORDER BY display_order, id
        """, recipe['id'])

        # Fetch options
        options = await conn.fetch("""
            SELECT name, type, description, default_value
            FROM recipe_options
            WHERE recipe_id = $1
            ORDER BY display_order, id
        """, recipe['id'])

        return {
            'recipe_id': recipe['recipe_id'],
            'name': recipe['name'],
            'description': recipe['description'],
            'full_documentation': recipe['full_documentation'],
            'usage_instructions': recipe['usage_instructions'],
            'source_url': recipe['source_url'],
            'tags': list(recipe['tags']) if recipe['tags'] else [],
            'examples': [
                {
                    'title': e['title'],
                    'before': e['before_code'],
                    'after': e['after_code']
                }
                for e in examples
            ],
            'options': [
                {
                    'name': o['name'],
                    'type': o['type'],
                    'description': o['description'],
                    'default': o['default_value']
                }
                for o in options
            ]
        }


async def get_recipe_count() -> int:
    """Get total number of recipes in database."""
    async with get_connection() as conn:
        count = await conn.fetchval("SELECT COUNT(*) FROM recipes")
        return count
