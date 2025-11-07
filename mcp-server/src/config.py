"""Configuration management for OpenRewrite MCP Server."""
import os
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class Config:
    """Configuration settings for the MCP server."""

    # Server metadata
    SERVER_NAME: str = "openrewrite-assistant"
    SERVER_VERSION: str = "0.1.0"

    # Database settings (for future phases)
    DB_HOST: str = os.getenv("DB_HOST", "localhost")
    DB_PORT: int = int(os.getenv("DB_PORT", "5432"))
    DB_NAME: str = os.getenv("DB_NAME", "openrewrite_recipes")
    DB_USER: str = os.getenv("DB_USER", "mcp_user")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")

    # Embedding settings (for future phases)
    EMBEDDING_MODEL: str = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
    EMBEDDING_DIMENSION: int = int(os.getenv("EMBEDDING_DIMENSION", "384"))

    # Tool settings
    DEFAULT_RECIPE_LIMIT: int = 5
    MIN_SIMILARITY_SCORE: float = 0.5

    @classmethod
    def get_db_url(cls) -> str:
        """Get database connection URL."""
        return f"postgresql://{cls.DB_USER}:{cls.DB_PASSWORD}@{cls.DB_HOST}:{cls.DB_PORT}/{cls.DB_NAME}"


# Global config instance
config = Config()
