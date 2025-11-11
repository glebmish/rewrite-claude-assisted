#!/usr/bin/env python3
"""
Common utilities for data ingestion Python scripts

Usage:
    from common import ScriptConfig, Logger, get_db_connection

    config = ScriptConfig()
    logger = Logger(verbose=config.VERBOSE)

    logger.print_stage_header("Stage 3: Process Data")
    # ... your code ...
    logger.print_stage_footer("3", "next-script.py")
"""

import os
import sys
from pathlib import Path
from typing import Optional


class ScriptConfig:
    """Centralized configuration for all Python scripts"""

    def __init__(self):
        # Path configuration
        self.SCRIPT_DIR = Path(__file__).parent
        self.PROJECT_DIR = self.SCRIPT_DIR.parent

        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv(self.PROJECT_DIR / '.env')

        # Database configuration
        self.DB_HOST = os.getenv('DB_HOST', 'localhost')
        self.DB_PORT = int(os.getenv('DB_PORT', '5432'))
        self.DB_NAME = os.getenv('DB_NAME', 'openrewrite_recipes')
        self.DB_USER = os.getenv('DB_USER', 'mcp_user')
        self.DB_PASSWORD = os.getenv('DB_PASSWORD', 'changeme')
        self.POSTGRES_CONTAINER_NAME = os.getenv('POSTGRES_CONTAINER_NAME', 'openrewrite-postgres')

        # Generator configuration
        self.GENERATOR_WORKSPACE = os.getenv('GENERATOR_WORKSPACE', str(self.PROJECT_DIR / 'workspace'))
        self.GENERATOR_OUTPUT_DIR = os.getenv('GENERATOR_OUTPUT_DIR', 'build/docs')
        self.GENERATOR_DIR = Path(self.GENERATOR_WORKSPACE) / 'rewrite-recipe-markdown-generator'

        # Embedding configuration
        self.EMBEDDING_MODEL = os.getenv('EMBEDDING_MODEL', 'all-MiniLM-L6-v2')
        self.EMBEDDING_DIMENSION = int(os.getenv('EMBEDDING_DIMENSION', '384'))

        # Logging
        self.VERBOSE = os.getenv('VERBOSE', 'false').lower() == 'true'

    def get_metadata_file(self) -> Path:
        """Get path to recipe metadata JSON file"""
        return self.GENERATOR_DIR / self.GENERATOR_OUTPUT_DIR / 'recipe-metadata.json'

    def get_recipes_dir(self) -> Path:
        """Get path to recipes markdown directory"""
        return self.GENERATOR_DIR / self.GENERATOR_OUTPUT_DIR / 'recipes'


class Logger:
    """Logging utilities with consistent formatting"""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose

    def log(self, message: str, force: bool = False):
        """Log message if verbose mode is enabled or force is True"""
        if self.verbose or force:
            print(message, file=sys.stderr)

    def print_stage_header(self, stage_title: str):
        """Print stage header with consistent formatting"""
        self.log("=" * 40, force=True)
        self.log(stage_title, force=True)
        self.log("=" * 40, force=True)
        self.log("", force=True)

    def print_stage_footer(self, stage_num: str, next_step: Optional[str] = None):
        """Print stage footer with consistent formatting"""
        self.log("", force=True)
        self.log("=" * 40, force=True)
        self.log(f"✓ Stage {stage_num} Complete", force=True)
        self.log("=" * 40, force=True)
        if next_step:
            self.log("", force=True)
            self.log(f"Next step: {next_step}", force=True)
        self.log("", force=True)


async def get_db_connection(config: ScriptConfig):
    """
    Create database connection with standard configuration

    Args:
        config: ScriptConfig instance with database settings

    Returns:
        asyncpg.Connection object
    """
    import asyncpg

    return await asyncpg.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        database=config.DB_NAME,
        user=config.DB_USER,
        password=config.DB_PASSWORD
    )


async def test_db_connection(config: ScriptConfig, logger: Logger) -> bool:
    """
    Test database connection

    Args:
        config: ScriptConfig instance with database settings
        logger: Logger instance for output

    Returns:
        True if connection successful, False otherwise
    """
    try:
        conn = await get_db_connection(config)
        await conn.close()
        return True
    except Exception as e:
        logger.log(f"✗ Database connection failed: {e}", force=True)
        return False
