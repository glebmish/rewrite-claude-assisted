#!/usr/bin/env python3
"""
Script: 03-ingest-docs.py
Purpose: Parse generated markdown files and ingest them into PostgreSQL database

Note: This script expects the PostgreSQL database to already be running and
initialized with the schema. Run 00-init-database.sh first if not already done.
"""

import asyncio
import asyncpg
import os
import sys
import re
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv
from tqdm import tqdm

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent

# Load environment variables
load_dotenv(PROJECT_DIR / '.env')

# Database configuration
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_NAME = os.getenv('DB_NAME', 'openrewrite_recipes')
DB_USER = os.getenv('DB_USER', 'mcp_user')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'changeme')

# Generator configuration
GENERATOR_WORKSPACE = str(PROJECT_DIR / 'workspace')
GENERATOR_OUTPUT_DIR = 'build/docs'
GENERATOR_DIR = Path(GENERATOR_WORKSPACE) / 'rewrite-recipe-markdown-generator'
RECIPES_DIR = GENERATOR_DIR / GENERATOR_OUTPUT_DIR / 'recipes'

# Verbose mode
VERBOSE = os.getenv('VERBOSE', 'false').lower() == 'true'


def log(message: str, force: bool = False):
    """Log message if verbose mode is enabled or force is True."""
    if VERBOSE or force:
        print(message, file=sys.stderr)


def extract_recipe_name_from_markdown(markdown: str, normalized_path: str) -> Optional[str]:
    """
    Extract recipe name from markdown by finding bold pattern containing normalized path.

    Args:
        markdown: The markdown content to search
        normalized_path: The normalized path (e.g., "java.spring.boot3.upgradespringboot_3_0")

    Returns:
        The full recipe name if found, None otherwise

    Example:
        normalized_path: "java.spring.boot3.upgradespringboot_3_0"
        markdown contains: "**org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0**"
        returns: "org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0"
    """
    # Find all bold patterns **...**
    pattern = r'\*\*([^*]+)\*\*'
    matches = re.finditer(pattern, markdown)

    # Search for a match containing the normalized path (case-insensitive)
    normalized_lower = normalized_path.lower()

    for match in matches:
        bold_content = match.group(1)
        if normalized_lower in bold_content.lower():
            return bold_content.strip()

    return None


def path_to_normalized_name(file_path: Path, recipes_base: Path) -> str:
    """
    Convert file path to normalized recipe path for matching.

    Example:
        recipes/java/spring/boot3/upgradespringboot_3_0.md
        -> java.spring.boot3.upgradespringboot_3_0
    """
    # Get relative path from recipes base
    rel_path = file_path.relative_to(recipes_base)

    # Remove .md extension
    path_without_ext = rel_path.with_suffix('')

    # Convert path separators to dots
    normalized = str(path_without_ext).replace('/', '.')

    return normalized


def extract_recipe_name(file_path: Path, markdown: str, recipes_base: Path) -> str:
    """
    Extract recipe name by finding bold pattern containing normalized path.

    Process:
    1. Convert file path to normalized name (e.g., java/spring/boot3/upgradespringboot.md -> java.spring.boot3.upgradespringboot)
    2. Find bold pattern **...** containing this normalized path (case-insensitive)
    3. Return the full content between ** markers as the recipe name

    Raises:
        ValueError: If recipe name cannot be extracted
    """
    # Get normalized path from file
    normalized_path = path_to_normalized_name(file_path, recipes_base)

    # Extract recipe name from markdown using normalized path
    recipe_name = extract_recipe_name_from_markdown(markdown, normalized_path)

    if recipe_name:
        return recipe_name

    # If not found, raise error with helpful message
    raise ValueError(
        f"Could not extract recipe name from {file_path.name}. "
        f"Expected to find bold pattern containing '{normalized_path}' (case-insensitive)"
    )


async def test_connection() -> bool:
    """Test database connection."""
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            timeout=10
        )
        await conn.close()
        return True
    except Exception as e:
        log(f"✗ Database connection failed: {e}", force=True)
        return False


async def ingest_recipes():
    """Main ingestion function."""
    log(f"=========================================", force=True)
    log(f"Stage 3: Ingest Documentation to Database", force=True)
    log(f"=========================================", force=True)

    # Verify recipes directory exists
    if not RECIPES_DIR.exists():
        log(f"✗ Error: Recipes directory not found: {RECIPES_DIR}", force=True)
        log(f"  Run 02-generate-docs.sh first", force=True)
        sys.exit(1)

    # Test database connection
    log(f"→ Testing database connection...", force=True)
    if not await test_connection():
        log(f"  Database is not running or not initialized.", force=True)
        log(f"  Run 00-init-database.sh first to initialize the database.", force=True)
        sys.exit(1)
    log(f"✓ Database connection successful", force=True)

    # Connect to database
    log(f"→ Connecting to database...", force=True)
    conn = await asyncpg.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

    try:
        # Collect all markdown files (excluding README.md files)
        log(f"→ Scanning for markdown files...", force=True)
        all_markdown_files = list(RECIPES_DIR.rglob('*.md'))
        markdown_files = [f for f in all_markdown_files if f.name != 'README.md']
        total_files = len(markdown_files)
        excluded_count = len(all_markdown_files) - total_files
        log(f"✓ Found {total_files} markdown files (excluded {excluded_count} README.md files)", force=True)

        if total_files == 0:
            log(f"✗ Error: No markdown files found in {RECIPES_DIR}", force=True)
            sys.exit(1)

        # Process files with progress bar
        log(f"→ Ingesting recipes...", force=True)
        ingested = 0
        skipped = 0
        errors = []

        progress_bar = tqdm(markdown_files, desc="Ingesting", unit="recipe")

        for md_file in progress_bar:
            try:
                # Read markdown content
                markdown_content = md_file.read_text(encoding='utf-8')

                # Extract recipe name
                recipe_name = extract_recipe_name(md_file, markdown_content, RECIPES_DIR)

                # Update progress bar
                progress_bar.set_postfix({"current": recipe_name.split('.')[-1][:20]})

                # Insert or update recipe
                await conn.execute("""
                    INSERT INTO recipes (recipe_name, markdown_doc)
                    VALUES ($1, $2)
                    ON CONFLICT (recipe_name) DO UPDATE
                    SET markdown_doc = EXCLUDED.markdown_doc,
                        updated_at = NOW()
                """, recipe_name, markdown_content)

                ingested += 1
                log(f"  ✓ {recipe_name}")

            except Exception as e:
                errors.append((md_file.name, str(e)))
                skipped += 1
                log(f"  ✗ Error processing {md_file.name}: {e}")

        progress_bar.close()

        # Get final count from database
        total_in_db = await conn.fetchval("SELECT COUNT(*) FROM recipes")

        log(f"", force=True)
        log(f"=========================================", force=True)
        log(f"✓ Stage 3 Complete", force=True)
        log(f"=========================================", force=True)
        log(f"Processed: {total_files} files", force=True)
        log(f"Ingested successfully: {ingested}", force=True)
        log(f"Skipped (errors): {skipped}", force=True)
        log(f"Total recipes in database: {total_in_db}", force=True)

        if errors:
            log(f"", force=True)
            log(f"Errors encountered:", force=True)
            for filename, error in errors[:10]:  # Show first 10 errors
                log(f"  - {filename}: {error}", force=True)
            if len(errors) > 10:
                log(f"  ... and {len(errors) - 10} more", force=True)

        log(f"", force=True)
        log(f"Next step: Run 04-create-image.sh", force=True)

    finally:
        await conn.close()


if __name__ == '__main__':
    asyncio.run(ingest_recipes())
