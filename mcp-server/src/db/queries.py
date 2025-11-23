"""Database queries for recipes."""
import logging
import re
from typing import List, Dict, Optional

from db.connection import get_connection

logger = logging.getLogger(__name__)

# Lazy-load sentence transformers to avoid startup delay
_embedding_model = None


def get_embedding_model():
    """Get or create the embedding model (lazy initialization)."""
    global _embedding_model
    if _embedding_model is None:
        from sentence_transformers import SentenceTransformer
        logger.info("Loading embedding model: all-MiniLM-L6-v2")
        _embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        logger.info("Embedding model loaded successfully")
    return _embedding_model


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


async def find_recipes_by_semantic_search(
    intent: str,
    limit: int = 5,
    min_score: float = 0.0
) -> List[Dict]:
    """
    Find recipes using semantic search with vector embeddings.

    Phase 3: Uses cosine similarity to find recipes matching the user's intent.

    Args:
        intent: User's description of what they want to accomplish
        limit: Maximum number of results to return
        min_score: Minimum similarity score (0.0-1.0) for results

    Returns:
        List of recipe dictionaries ordered by relevance score
    """
    # Generate embedding for the user's intent
    model = get_embedding_model()
    intent_embedding = model.encode(intent, show_progress_bar=False)

    # Convert embedding to PostgreSQL vector format
    embedding_str = '[' + ','.join(str(x) for x in intent_embedding) + ']'

    async with get_connection() as conn:
        # Use cosine similarity for vector search
        # 1 - (embedding <=> query_embedding) converts distance to similarity (0-1 range)
        results = await conn.fetch("""
            SELECT
                r.id,
                r.recipe_name,
                r.markdown_doc,
                m.display_name,
                m.description,
                m.tags,
                m.is_composite,
                m.recipe_count,
                1 - (e.embedding <=> $1::vector) AS relevance_score
            FROM recipes r
            INNER JOIN recipe_embeddings e ON r.id = e.recipe_id
            LEFT JOIN recipe_metadata m ON r.id = m.recipe_id
            WHERE 1 - (e.embedding <=> $1::vector) >= $2
            ORDER BY relevance_score DESC
            LIMIT $3
        """, embedding_str, min_score, limit)

        return [
            {
                'recipe_id': r['recipe_name'],
                'name': r['display_name'] or extract_title_from_markdown(r['markdown_doc']),
                'description': r['description'] or extract_description_from_markdown(r['markdown_doc']),
                'tags': r['tags'] or [],
                'is_composite': r['is_composite'],
                'recipe_count': r['recipe_count'],
                'relevance_score': float(r['relevance_score'])
            }
            for r in results
        ]


async def get_recipe_details(recipe_name: str) -> Optional[Dict]:
    """
    Get full recipe documentation.

    Args:
        recipe_name: Unique recipe name (fully qualified)

    Returns:
        Dictionary with recipe_id and markdown_documentation, or None if not found
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
            'markdown_documentation': recipe['markdown_doc']
        }


async def get_recipe_count() -> int:
    """Get total number of recipes in database."""
    async with get_connection() as conn:
        count = await conn.fetchval("SELECT COUNT(*) FROM recipes")
        return count
