"""Find recipes tool with semantic search (Phase 3)."""
import sys
import logging
from pathlib import Path
from typing import List, Dict, Union

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import config
from db.queries import find_recipes_by_semantic_search, find_recipes_by_multi_query_search

logger = logging.getLogger(__name__)


async def find_recipes(
    intent: Union[str, List[str]],
    limit: int = None,
    min_score: float = None
) -> List[Dict]:
    """
    Find OpenRewrite recipes based on user intent using semantic search.

    Phase 3: Uses vector embeddings and cosine similarity to find recipes
    that match the semantic meaning of the user's intent.

    Phase 4: Supports multiple query variations with Reciprocal Rank Fusion
    for improved recall.

    Args:
        intent: Single query string OR list of query variations
        limit: Maximum number of results to return (default: 5)
        min_score: Minimum similarity score threshold (default: from config)

    Returns:
        List of recipe objects ordered by relevance score (single query)
        or fusion score (multi-query)

    Examples:
        >>> # Single query
        >>> await find_recipes("upgrade Spring Boot to latest version")
        [{'recipe_id': 'org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0', ...}]

        >>> # Multi-query for better recall
        >>> await find_recipes([
        ...     "migrate to Spring Boot 3",
        ...     "upgrade Spring Boot version",
        ...     "Spring Boot 3.x migration"
        ... ], limit=5)
        [{'recipe_id': '...', 'fusion_score': 0.032, 'query_matches': 3, ...}]
    """
    # Apply defaults
    if limit is None:
        limit = config.DEFAULT_RECIPE_LIMIT
    if min_score is None:
        min_score = config.MIN_SIMILARITY_SCORE

    # Normalize intent to list and validate
    if isinstance(intent, str):
        intents = [intent]
        is_multi_query = False
    elif isinstance(intent, list):
        intents = intent
        is_multi_query = True
    else:
        raise ValueError(f"intent must be string or list of strings, got {type(intent)}")

    # Validate list
    if not intents:
        raise ValueError("intent cannot be empty")

    # Filter out empty strings
    intents = [q.strip() for q in intents if q and q.strip()]
    if not intents:
        raise ValueError("intent contains no valid queries")

    # Remove duplicates while preserving order
    seen = set()
    unique_intents = []
    for q in intents:
        if q not in seen:
            seen.add(q)
            unique_intents.append(q)

    if len(unique_intents) < len(intents):
        logger.info(f"Removed {len(intents) - len(unique_intents)} duplicate queries")
        intents = unique_intents

    # Limit max queries
    max_queries = 5
    if len(intents) > max_queries:
        logger.warning(f"Limiting queries from {len(intents)} to {max_queries}")
        intents = intents[:max_queries]

    # Route to appropriate search function
    if len(intents) == 1:
        # Single query path (backward compatible)
        query_type = "single"
        logger.info(f"Semantic search for recipes (intent='{intents[0]}', limit={limit}, min_score={min_score})")

        try:
            results = await find_recipes_by_semantic_search(
                intent=intents[0],
                limit=limit,
                min_score=min_score
            )
        except Exception as e:
            logger.error(f"Semantic search failed: {e}", exc_info=True)
            raise
    else:
        # Multi-query path with fusion
        query_type = "multi"
        logger.info(f"Multi-query semantic search (queries={len(intents)}, limit={limit}, min_score={min_score})")
        logger.debug(f"Queries: {intents}")

        try:
            results = await find_recipes_by_multi_query_search(
                intents=intents,
                limit=limit,
                min_score=min_score
            )
        except Exception as e:
            logger.error(f"Multi-query search failed: {e}", exc_info=True)
            raise

    logger.info(f"{query_type.capitalize()} search found {len(results)} recipes")

    # Log top result for debugging
    if results:
        top = results[0]
        if 'fusion_score' in top:
            logger.debug(f"Top result: {top['recipe_id']} (fusion_score: {top['fusion_score']:.4f}, matches: {top['query_matches']})")
        else:
            logger.debug(f"Top result: {top['recipe_id']} (score: {top['relevance_score']:.3f})")

    return results
