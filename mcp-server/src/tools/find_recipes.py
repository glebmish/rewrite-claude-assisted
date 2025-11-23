"""Find recipes tool with semantic search (Phase 3)."""
import sys
import logging
from pathlib import Path
from typing import List, Dict

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import config
from db.queries import find_recipes_by_semantic_search

logger = logging.getLogger(__name__)


async def find_recipes(intent: str, limit: int = None, min_score: float = None) -> List[Dict]:
    """
    Find OpenRewrite recipes based on user intent using semantic search.

    Phase 3: Uses vector embeddings and cosine similarity to find recipes
    that match the semantic meaning of the user's intent.

    Args:
        intent: Description of what the user wants to accomplish
        limit: Maximum number of results to return (default: 5)
        min_score: Minimum similarity score threshold (default: from config)

    Returns:
        List of recipe objects ordered by relevance score

    Examples:
        >>> await find_recipes("upgrade Spring Boot to latest version")
        [{'recipe_id': 'org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0', ...}]

        >>> await find_recipes("migrate from JUnit 4 to JUnit 5", limit=3)
        [{'recipe_id': 'org.openrewrite.java.testing.junit5.JUnit4to5Migration', ...}]
    """
    if limit is None:
        limit = config.DEFAULT_RECIPE_LIMIT
    if min_score is None:
        min_score = config.MIN_SIMILARITY_SCORE

    logger.info(f"Semantic search for recipes (intent='{intent}', limit={limit}, min_score={min_score})")

    try:
        results = await find_recipes_by_semantic_search(
            intent=intent,
            limit=limit,
            min_score=min_score
        )
        logger.info(f"Found {len(results)} recipes with semantic search")

        # Log top result for debugging
        if results:
            top = results[0]
            logger.debug(f"Top result: {top['recipe_id']} (score: {top['relevance_score']:.3f})")

        return results
    except Exception as e:
        logger.error(f"Semantic search failed: {e}", exc_info=True)
        raise
