"""Get recipe documentation tool with mock data for Phase 1."""
from typing import Optional, Dict, List

# Mock detailed recipe documentation
MOCK_RECIPE_DOCS = {
    "org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0": {
        "recipe_id": "org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0",
        "name": "Upgrade to Spring Boot 3.0",
        "description": "Migrate applications to the latest Spring Boot 3.0 release. This recipe will modify an application's build files, make changes to deprecated/preferred APIs, and migrate configuration settings that have changes between versions.",
        "full_documentation": """# Spring Boot 3.0 Migration

This recipe will migrate your Spring Boot 2.x application to Spring Boot 3.0.

## What it does

- Updates Spring Boot dependency versions to 3.0.x
- Migrates from javax.* to jakarta.* namespace
- Updates deprecated API usages
- Migrates configuration properties
- Updates security configuration for Spring Security 6

## Prerequisites

- Java 17 or higher (Spring Boot 3.0 requires Java 17 minimum)
- Spring Boot 2.7.x (recommended starting point)
""",
        "usage_instructions": "Add this recipe to your rewrite.yml:\n\n```yaml\nrecipeList:\n  - org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0\n```\n\nThen run: `mvn rewrite:run` or `gradle rewriteRun`",
        "examples": [
            {
                "title": "Jakarta namespace migration",
                "before": "import javax.servlet.http.HttpServletRequest;",
                "after": "import jakarta.servlet.http.HttpServletRequest;"
            },
            {
                "title": "Dependency version update",
                "before": "<parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>2.7.14</version>\n</parent>",
                "after": "<parent>\n    <groupId>org.springframework.boot</groupId>\n    <artifactId>spring-boot-starter-parent</artifactId>\n    <version>3.0.0</version>\n</parent>"
            }
        ],
        "options": [
            {
                "name": "skipVersionCheck",
                "type": "boolean",
                "description": "Skip checking the Spring Boot version",
                "default": False
            }
        ],
        "tags": ["spring", "spring-boot", "migration", "upgrade"],
        "source_url": "https://docs.openrewrite.org/recipes/java/spring/boot3/upgradespringboot_3_0"
    },
    "org.openrewrite.java.testing.junit5.JUnit4to5Migration": {
        "recipe_id": "org.openrewrite.java.testing.junit5.JUnit4to5Migration",
        "name": "JUnit 4 to JUnit 5 Migration",
        "description": "Migrates JUnit 4 tests to JUnit 5. This recipe will change the package names, update annotations, and adapt assertion methods to their JUnit 5 equivalents.",
        "full_documentation": """# JUnit 4 to JUnit 5 Migration

Automatically migrates your JUnit 4 tests to JUnit 5 (Jupiter).

## What it does

- Changes imports from org.junit to org.junit.jupiter.api
- Updates @Test annotations and removes expected/timeout parameters
- Migrates assertions (assertEquals, assertTrue, etc.)
- Updates @Before/@After to @BeforeEach/@AfterEach
- Converts @RunWith annotations to @ExtendWith
- Updates Maven/Gradle dependencies

## Key Changes

- `@Before` → `@BeforeEach`
- `@After` → `@AfterEach`
- `@BeforeClass` → `@BeforeAll`
- `@AfterClass` → `@AfterAll`
- `@Ignore` → `@Disabled`
""",
        "usage_instructions": "Add this recipe to your rewrite.yml:\n\n```yaml\nrecipeList:\n  - org.openrewrite.java.testing.junit5.JUnit4to5Migration\n```",
        "examples": [
            {
                "title": "Test annotation migration",
                "before": "@Test(expected = IllegalArgumentException.class)\npublic void testException() {\n    throw new IllegalArgumentException();\n}",
                "after": "@Test\nvoid testException() {\n    assertThrows(IllegalArgumentException.class, () -> {\n        throw new IllegalArgumentException();\n    });\n}"
            },
            {
                "title": "Lifecycle annotation migration",
                "before": "@Before\npublic void setUp() {\n    // setup code\n}",
                "after": "@BeforeEach\nvoid setUp() {\n    // setup code\n}"
            }
        ],
        "options": [],
        "tags": ["junit", "testing", "migration", "junit5"],
        "source_url": "https://docs.openrewrite.org/recipes/java/testing/junit5/junit4to5migration"
    },
    "org.openrewrite.java.migrate.UpgradeToJava17": {
        "recipe_id": "org.openrewrite.java.migrate.UpgradeToJava17",
        "name": "Migrate to Java 17",
        "description": "This recipe will apply changes commonly needed when migrating to Java 17. This includes updating dependencies, replacing deprecated APIs, and adapting to language changes.",
        "full_documentation": """# Migrate to Java 17

Migrates Java applications to use Java 17 language features and APIs.

## What it does

- Updates Java version in build files (Maven/Gradle)
- Removes deprecated API usages
- Migrates to modern Java APIs
- Updates security providers
- Adapts to JVM changes

## Benefits of Java 17

- Latest LTS release
- Pattern matching for instanceof
- Sealed classes
- Text blocks
- Records
- Switch expressions
- Improved garbage collection
""",
        "usage_instructions": "Add this recipe to your rewrite.yml:\n\n```yaml\nrecipeList:\n  - org.openrewrite.java.migrate.UpgradeToJava17\n```",
        "examples": [
            {
                "title": "Java version update in pom.xml",
                "before": "<properties>\n    <java.version>11</java.version>\n</properties>",
                "after": "<properties>\n    <java.version>17</java.version>\n</properties>"
            }
        ],
        "options": [],
        "tags": ["java", "java17", "migration", "upgrade"],
        "source_url": "https://docs.openrewrite.org/recipes/java/migrate/upgradetojava17"
    }
}


async def get_recipe(recipe_id: str) -> Dict:
    """
    Get detailed documentation for a specific OpenRewrite recipe (mock implementation).

    Retrieves the full documentation, usage instructions, examples, and configuration
    options for a specific recipe. This is a mock implementation with hardcoded data.
    Phase 3 will replace this with real database queries.

    Args:
        recipe_id: Unique identifier for the recipe

    Returns:
        Dictionary containing full recipe documentation

    Raises:
        ValueError: If recipe_id is not found
    """
    if recipe_id not in MOCK_RECIPE_DOCS:
        raise ValueError(
            f"Recipe '{recipe_id}' not found. "
            f"Available recipes: {', '.join(MOCK_RECIPE_DOCS.keys())}"
        )

    return MOCK_RECIPE_DOCS[recipe_id]
