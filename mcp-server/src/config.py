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
    SERVER_NAME: str = "openrewrite-mcp"
    SERVER_VERSION: str = "0.1.0"

    # Database settings (for future phases)
    DB_HOST: str = os.environ["DB_HOST"]
    DB_PORT: int = int(os.environ["DB_PORT"])
    DB_NAME: str = os.environ["DB_NAME"]
    DB_USER: str = os.environ["DB_USER"]
    DB_PASSWORD: str = os.environ["DB_PASSWORD"]

    # Embedding settings (for future phases)
    EMBEDDING_MODEL: str = os.environ["EMBEDDING_MODEL"]
    EMBEDDING_DIMENSION: int = int(os.environ["EMBEDDING_DIMENSION"])

    # Tool settings
    DEFAULT_RECIPE_LIMIT: int = 5
    MIN_SIMILARITY_SCORE: float = 0.5

    @classmethod
    def get_db_url(cls) -> str:
        """Get database connection URL."""
        return f"postgresql://{cls.DB_USER}:{cls.DB_PASSWORD}@{cls.DB_HOST}:{cls.DB_PORT}/{cls.DB_NAME}"


# Global config instance
config = Config()
