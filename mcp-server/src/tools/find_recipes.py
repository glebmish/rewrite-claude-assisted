"""Find recipes tool with mock data for Phase 1."""
import sys
from pathlib import Path
from typing import List, Dict

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from config import config

# Mock recipe database
MOCK_RECIPES = [
    {
        "recipe_id": "org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0",
        "name": "Upgrade to Spring Boot 3.0",
        "description": "Migrate applications to the latest Spring Boot 3.0 release. This recipe will modify an application's build files, make changes to deprecated/preferred APIs, and migrate configuration settings that have changes between versions.",
        "tags": ["spring", "spring-boot", "migration", "upgrade"]
    },
    {
        "recipe_id": "org.openrewrite.java.testing.junit5.JUnit4to5Migration",
        "name": "JUnit 4 to JUnit 5 Migration",
        "description": "Migrates JUnit 4 tests to JUnit 5. This recipe will change the package names, update annotations, and adapt assertion methods to their JUnit 5 equivalents.",
        "tags": ["junit", "testing", "migration", "junit5"]
    },
    {
        "recipe_id": "org.openrewrite.java.migrate.UpgradeToJava17",
        "name": "Migrate to Java 17",
        "description": "This recipe will apply changes commonly needed when migrating to Java 17. This includes updating dependencies, replacing deprecated APIs, and adapting to language changes.",
        "tags": ["java", "java17", "migration", "upgrade"]
    },
    {
        "recipe_id": "org.openrewrite.java.security.SecureRandomPRNG",
        "name": "Use secure random number generation",
        "description": "Replaces instantiation of java.util.Random with java.security.SecureRandom for security-sensitive applications.",
        "tags": ["security", "random", "java"]
    },
    {
        "recipe_id": "org.openrewrite.java.cleanup.RemoveUnusedImports",
        "name": "Remove unused imports",
        "description": "Remove imports that are not referenced in the source file. This recipe will also remove unused static imports.",
        "tags": ["cleanup", "imports", "code-quality"]
    },
    {
        "recipe_id": "org.openrewrite.java.migrate.javax.JavaxMigrationToJakarta",
        "name": "Migrate from javax to jakarta namespace",
        "description": "Migrate from javax.* to jakarta.* namespace as part of Jakarta EE 9+ migration.",
        "tags": ["jakarta", "javax", "migration", "jakarta-ee"]
    },
    {
        "recipe_id": "org.openrewrite.java.logging.slf4j.Log4jToSlf4j",
        "name": "Migrate Log4j to SLF4J",
        "description": "Transforms code written using Log4j to use SLF4J instead.",
        "tags": ["logging", "log4j", "slf4j", "migration"]
    }
]


def _calculate_mock_relevance(recipe: Dict, intent: str) -> float:
    """
    Calculate a mock relevance score based on simple keyword matching.

    In Phase 3, this will be replaced with actual vector similarity.
    """
    intent_lower = intent.lower()
    score = 0.0

    # Check if intent keywords appear in recipe name or description
    words = intent_lower.split()
    text = f"{recipe['name']} {recipe['description']} {' '.join(recipe['tags'])}".lower()

    for word in words:
        if len(word) > 2 and word in text:
            score += 0.15

    # Boost score for tag matches
    for tag in recipe['tags']:
        if tag.lower() in intent_lower:
            score += 0.2

    # Cap at 1.0 and add some base randomness for variety
    return min(1.0, max(0.3, score))


async def find_recipes(intent: str, limit: int = None, min_score: float = None) -> List[Dict]:
    """
    Find OpenRewrite recipes based on user intent (mock implementation).

    Performs a semantic search to find recipes that match the user's described
    intent. This is a mock implementation using simple keyword matching.
    Phase 3 will replace this with real vector similarity search.

    Args:
        intent: Description of what the user wants to accomplish
        limit: Maximum number of results to return (default: 5)
        min_score: Minimum relevance score threshold (default: 0.5)

    Returns:
        List of recipe objects with relevance scores, sorted by relevance
    """
    if limit is None:
        limit = config.DEFAULT_RECIPE_LIMIT
    if min_score is None:
        min_score = config.MIN_SIMILARITY_SCORE

    # Calculate relevance scores for all recipes
    scored_recipes = []
    for recipe in MOCK_RECIPES:
        score = _calculate_mock_relevance(recipe, intent)
        if score >= min_score:
            scored_recipes.append({
                "recipe_id": recipe["recipe_id"],
                "name": recipe["name"],
                "description": recipe["description"],
                "relevance_score": round(score, 3),
                "tags": recipe["tags"]
            })

    # Sort by relevance (descending) and limit results
    scored_recipes.sort(key=lambda x: x["relevance_score"], reverse=True)
    return scored_recipes[:limit]
