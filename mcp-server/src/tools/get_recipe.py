"""Get recipe documentation tool with database backend (Phase 2)."""
import sys
import logging
from pathlib import Path
from typing import Optional, Dict, List

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from db.queries import get_recipe_details

logger = logging.getLogger(__name__)


async def get_recipe(recipe_id: str) -> Dict:
    """
    Get detailed documentation for a specific OpenRewrite recipe.

    Phase 2: Retrieves recipe details from PostgreSQL database.
    Phase 3: Will add embedding-based recommendations.

    Args:
        recipe_id: Unique identifier for the recipe

    Returns:
        Dictionary containing full recipe documentation

    Raises:
        ValueError: If recipe_id is not found
    """
    logger.info(f"Getting recipe details for: {recipe_id}")

    try:
        recipe = await get_recipe_details(recipe_id)

        if recipe is None:
            raise ValueError(
                f"Recipe '{recipe_id}' not found in database. "
                "Use find_recipes to search for available recipes."
            )

        return recipe
    except ValueError:
        # Re-raise ValueError as-is
        raise
    except Exception as e:
        logger.error(f"Database query failed: {e}")
        raise
