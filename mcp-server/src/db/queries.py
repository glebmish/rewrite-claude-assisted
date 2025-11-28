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


async def find_recipes_by_multi_query_search(
    intents: List[str],
    limit: int = 5,
    min_score: float = 0.0,
    k: int = 60
) -> List[Dict]:
    """
    Find recipes using multiple query variations with Reciprocal Rank Fusion.

    Uses RRF to merge results from multiple semantic searches, giving higher
    scores to recipes that appear in results for multiple query variations.

    Args:
        intents: List of query variations (different phrasings of same intent)
        limit: Maximum number of results after fusion
        min_score: Minimum similarity score for individual queries
        k: RRF constant (default: 60, based on literature)

    Returns:
        Fused and re-ranked list of recipes with fusion metadata

    Algorithm:
        1. Execute semantic search for each query
        2. Build rank mapping for each recipe
        3. Apply RRF: score = Σ(1/(k + rank)) for each query
        4. Sort by fusion score and return top N
    """
    from collections import defaultdict

    logger.info(f"Multi-query search with {len(intents)} queries (limit={limit}, min_score={min_score})")

    # Step 1: Execute search for each query
    all_results = []
    for idx, intent in enumerate(intents):
        logger.debug(f"Query {idx+1}/{len(intents)}: '{intent}'")
        try:
            results = await find_recipes_by_semantic_search(
                intent=intent,
                limit=limit * 2,  # Get more results per query for better fusion
                min_score=min_score
            )
            all_results.append(results)
            logger.debug(f"Query {idx+1} returned {len(results)} results")
        except Exception as e:
            logger.error(f"Query {idx+1} failed: {e}", exc_info=True)
            # Continue with other queries
            all_results.append([])

    # Check if all queries failed
    if all(len(r) == 0 for r in all_results):
        logger.warning("All queries returned no results")
        return []

    # Step 2: Build rank mapping and collect recipe metadata
    recipe_ranks = defaultdict(list)  # {recipe_id: [(query_idx, rank, score), ...]}
    recipe_metadata = {}  # {recipe_id: full_recipe_dict}

    for query_idx, results in enumerate(all_results):
        for rank, recipe in enumerate(results, start=1):
            recipe_id = recipe['recipe_id']
            recipe_ranks[recipe_id].append((query_idx, rank, recipe['relevance_score']))

            # Store metadata from first occurrence
            if recipe_id not in recipe_metadata:
                recipe_metadata[recipe_id] = recipe

    # Step 3: Apply RRF fusion
    fused_recipes = []
    for recipe_id, rank_data in recipe_ranks.items():
        # Calculate RRF score
        rrf_score = sum(1.0 / (k + rank) for _, rank, _ in rank_data)

        # Get max original score and query match count
        max_score = max(score for _, _, score in rank_data)
        query_matches = len(rank_data)

        # Build result with fusion metadata
        recipe = recipe_metadata[recipe_id].copy()
        recipe['relevance_score'] = max_score
        recipe['fusion_score'] = rrf_score
        recipe['query_matches'] = query_matches

        fused_recipes.append(recipe)

    # Step 4: Sort by RRF score and apply limit
    fused_recipes.sort(key=lambda r: r['fusion_score'], reverse=True)
    final_results = fused_recipes[:limit]

    logger.info(f"Fusion complete: {len(fused_recipes)} unique recipes, returning top {len(final_results)}")

    return final_results


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
