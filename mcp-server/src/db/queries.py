"""Database queries for recipes."""
import logging
import re
from typing import List, Dict, Optional

from db.connection import get_connection

logger = logging.getLogger(__name__)


def extract_title_from_markdown(markdown: str) -> str:
    """Extract recipe title from markdown (first # heading)."""
    match = re.search(r'^#\s+(.+?)$', markdown, re.MULTILINE)
    return match.group(1) if match else "Unknown Recipe"


def extract_description_from_markdown(markdown: str) -> str:
    """Extract short description from markdown (text after recipe name in bold)."""
    # Look for pattern like **org.openrewrite.java.ChangeType**
    # followed by description text
    match = re.search(r'\*\*([^*]+)\*\*\s*\n\s*\n_([^_]+)_', markdown, re.MULTILINE)
    if match:
        return match.group(2).strip()

    # Fallback: first paragraph after frontmatter
    lines = markdown.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('---') and i > 0:
            # Found end of frontmatter, look for first non-empty line
            for j in range(i+1, len(lines)):
                if lines[j].strip() and not lines[j].startswith('#'):
                    return lines[j].strip()

    return "No description available"


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
                id,
                recipe_name,
                markdown_doc
            FROM recipes
            ORDER BY recipe_name
            LIMIT $1
        """, limit)

        return [
            {
                'recipe_id': r['recipe_name'],
                'name': extract_title_from_markdown(r['markdown_doc']),
                'description': extract_description_from_markdown(r['markdown_doc']),
                'tags': [],  # Could extract from markdown if needed
                'relevance_score': 1.0  # Placeholder for Phase 3
            }
            for r in results
        ]


async def get_recipe_details(recipe_name: str) -> Optional[Dict]:
    """
    Get full recipe documentation.

    Args:
        recipe_name: Unique recipe name (fully qualified)

    Returns:
        Dictionary with recipe name and full markdown documentation, or None if not found
    """
    async with get_connection() as conn:
        recipe = await conn.fetchrow("""
            SELECT recipe_name, markdown_doc
            FROM recipes
            WHERE recipe_name = $1
        """, recipe_name)

        if not recipe:
            return None

        return {
            'recipe_id': recipe['recipe_name'],
            'name': extract_title_from_markdown(recipe['markdown_doc']),
            'markdown_documentation': recipe['markdown_doc']
        }


async def get_recipe_count() -> int:
    """Get total number of recipes in database."""
    async with get_connection() as conn:
        count = await conn.fetchval("SELECT COUNT(*) FROM recipes")
        return count
