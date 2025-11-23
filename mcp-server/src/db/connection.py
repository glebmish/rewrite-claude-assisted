"""Database connection pool management."""
import asyncpg
import logging
from typing import Optional
from contextlib import asynccontextmanager

logger = logging.getLogger(__name__)

# Global connection pool
_pool: Optional[asyncpg.Pool] = None


async def init_pool(
    host: str,
    port: int,
    database: str,
    user: str,
    password: str
) -> asyncpg.Pool:
    """
    Initialize database connection pool.

    This must be called before any database queries.
    Raises exception if connection fails.
    """
    global _pool

    if _pool is not None:
        logger.warning("Connection pool already initialized")
        return _pool

    try:
        _pool = await asyncpg.create_pool(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password,
            min_size=2,
            max_size=10,
            command_timeout=60,
            timeout=10
        )
        logger.info(f"Database connection pool initialized (host={host}, db={database})")
        return _pool
    except Exception as e:
        logger.error(f"Failed to initialize database pool: {e}")
        raise


async def close_pool():
    """Close database connection pool."""
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None
        logger.info("Database connection pool closed")


async def get_pool() -> asyncpg.Pool:
    """
    Get the database connection pool.

    Raises RuntimeError if pool not initialized.
    """
    if _pool is None:
        raise RuntimeError("Database pool not initialized. Call init_pool() first.")
    return _pool


@asynccontextmanager
async def get_connection():
    """Context manager for database connections."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        yield conn
