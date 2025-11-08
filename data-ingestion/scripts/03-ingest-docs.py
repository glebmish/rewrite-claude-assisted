#!/usr/bin/env python3
"""
Script: 03-ingest-docs.py
Purpose: Parse generated markdown files and ingest them into PostgreSQL database
"""

import asyncio
import asyncpg
import os
import sys
import re
from pathlib import Path
from typing import Optional, Dict, Tuple
from dotenv import load_dotenv
from tqdm import tqdm
import yaml

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
GENERATOR_WORKSPACE = os.getenv('GENERATOR_WORKSPACE', str(PROJECT_DIR / 'workspace'))
GENERATOR_OUTPUT_DIR = os.getenv('GENERATOR_OUTPUT_DIR', 'build/docs')
GENERATOR_DIR = Path(GENERATOR_WORKSPACE) / 'rewrite-recipe-markdown-generator'
RECIPES_DIR = GENERATOR_DIR / GENERATOR_OUTPUT_DIR / 'recipes'

# Verbose mode
VERBOSE = os.getenv('VERBOSE', 'false').lower() == 'true'


def log(message: str, force: bool = False):
    """Log message if verbose mode is enabled or force is True."""
    if VERBOSE or force:
        print(message, file=sys.stderr)


def extract_frontmatter(markdown: str) -> Tuple[Optional[Dict], str]:
    """
    Extract YAML frontmatter from markdown.

    Returns:
        (frontmatter_dict, markdown_without_frontmatter)
    """
    if not markdown.startswith('---'):
        return None, markdown

    # Find the closing ---
    end_match = re.search(r'\n---\n', markdown[3:])
    if not end_match:
        return None, markdown

    frontmatter_text = markdown[3:3 + end_match.start()]
    remaining_markdown = markdown[3 + end_match.end():]

    try:
        frontmatter = yaml.safe_load(frontmatter_text)
        return frontmatter, remaining_markdown
    except yaml.YAMLError:
        return None, markdown


def extract_recipe_name_from_markdown(markdown: str) -> Optional[str]:
    """
    Extract recipe name from markdown content.

    Strategies:
    1. Look for bold recipe name pattern: **org.openrewrite.java.ChangeType**
    2. Look for H2/H3 with 'Recipe source' or 'Fully qualified name'
    """
    # Strategy 1: Bold pattern (most common)
    # Look for **fully.qualified.ClassName** or **org.openrewrite...**
    pattern = r'\*\*(org\.openrewrite\.[a-zA-Z0-9_.]+)\*\*'
    match = re.search(pattern, markdown)
    if match:
        return match.group(1)

    # Strategy 2: Look for lines starting with "**Fully qualified name:**"
    pattern = r'\*\*Fully qualified name:\*\*\s+`([^`]+)`'
    match = re.search(pattern, markdown)
    if match:
        return match.group(1)

    return None


def path_to_recipe_name(file_path: Path, recipes_base: Path) -> str:
    """
    Convert file path to fully qualified recipe name.

    Example:
        recipes/java/spring/boot3/upgradespringboot_3_0.md
        -> org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0
    """
    # Get relative path from recipes base
    rel_path = file_path.relative_to(recipes_base)

    # Remove .md extension
    path_without_ext = rel_path.with_suffix('')

    # Convert path to package-like structure
    parts = list(path_without_ext.parts)

    # Convert last part (class name) to PascalCase if needed
    # This is a best-effort conversion
    class_name = parts[-1]

    # Common convention: file names are lowercase, class names are PascalCase
    # Example: changetype -> ChangeType
    if class_name.islower() or '_' in class_name:
        # Try to detect word boundaries and capitalize
        words = re.findall(r'[a-z]+|[A-Z][a-z]*|\d+', class_name)
        class_name = ''.join(word.capitalize() for word in words)

    parts[-1] = class_name

    # Join with dots and add org.openrewrite prefix
    return 'org.openrewrite.' + '.'.join(parts)


def extract_recipe_name(file_path: Path, markdown: str, recipes_base: Path) -> str:
    """
    Extract recipe name using multiple strategies.

    Priority:
    1. Frontmatter recipe_id field
    2. Bold pattern in markdown
    3. Derive from file path
    """
    # Strategy 1: Frontmatter
    frontmatter, _ = extract_frontmatter(markdown)
    if frontmatter and 'recipe_id' in frontmatter:
        return frontmatter['recipe_id']

    # Strategy 2: Extract from markdown content
    recipe_name = extract_recipe_name_from_markdown(markdown)
    if recipe_name:
        return recipe_name

    # Strategy 3: Derive from path (fallback)
    log(f"  Warning: Could not extract recipe name from content, deriving from path: {file_path}")
    return path_to_recipe_name(file_path, recipes_base)


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
        log(f"  Make sure PostgreSQL is running:", force=True)
        log(f"  docker-compose up -d", force=True)
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
        # Collect all markdown files
        log(f"→ Scanning for markdown files...", force=True)
        markdown_files = list(RECIPES_DIR.rglob('*.md'))
        total_files = len(markdown_files)
        log(f"✓ Found {total_files} markdown files", force=True)

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
