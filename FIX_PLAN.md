# Fix Plan: MCP Server Database Connection in GitHub Actions

## Problem Summary

The OpenRewrite MCP server fails to connect to PostgreSQL in GitHub Actions with error:
```
PostgreSQL database required but not found in environment
```

## Root Cause Analysis

### 1. **Missing Database Readiness Checks for External Database**

**File:** `plugin/mcp-server/scripts/startup.sh` (lines 90-92)

When `USE_EXTERNAL_DB=true` (GitHub Actions mode), the script **skips all database readiness checks**:

```bash
if [[ "$USE_EXTERNAL_DB" == "true" ]]; then
    echo "Using external database - skipping readiness checks" >&2
    echo "Assuming external database at $DB_HOST:$DB_PORT is already ready" >&2
else
    # Comprehensive readiness checks only run in local mode...
```

**Problem:** The script assumes the external database is ready, but in reality:
- GitHub Actions service container may still be initializing
- PostgreSQL might be accepting connections but not fully ready
- The `recipes` table may not exist yet
- Database initialization scripts may still be running

### 2. **No Retry Logic in MCP Server**

**File:** `plugin/mcp-server/src/server.py` (lines 188-200)

The server attempts database connection **once** and fails immediately:

```python
try:
    await init_pool(
        host=config.DB_HOST,
        port=config.DB_PORT,
        database=config.DB_NAME,
        user=config.DB_USER,
        password=config.DB_PASSWORD
    )
    logger.info("Database connection established")
except Exception as e:
    logger.error(f"Failed to connect to database: {e}")
    logger.error("Server cannot start without database connection")
    sys.exit(1)  # ❌ Immediate exit, no retry
```

**File:** `plugin/mcp-server/src/db/connection.py` (lines 33-42)

The `asyncpg.create_pool` has a `timeout=10` seconds, but this is **connection timeout**, not retry logic:

```python
_pool = await asyncpg.create_pool(
    host=host,
    port=port,
    database=database,
    user=user,
    password=password,
    min_size=2,
    max_size=10,
    command_timeout=60,
    timeout=10  # ❌ Connection timeout, NOT retry timeout
)
```

If the connection fails within 10 seconds, it raises an exception immediately.

### 3. **GitHub Actions Service Healthcheck Limitation**

**File:** `.github/workflows/rewrite-assist.yml` (lines 76-80)

The healthcheck uses `pg_isready`:

```yaml
options: >-
  --health-cmd "pg_isready -U mcp_user -d openrewrite_recipes"
  --health-interval 10s
  --health-timeout 5s
  --health-retries 5
```

**Problem:** `pg_isready` only checks if PostgreSQL is accepting connections, NOT if:
- The database is fully initialized
- Tables are created
- Data is loaded
- Initialization scripts have completed

## Timing Race Condition

```
Timeline (GitHub Actions):

T=0s:   Job starts, PostgreSQL service container starts
T=1s:   PostgreSQL accepting connections (pg_isready = true)
T=2s:   Container starts, entrypoint.sh begins
T=3s:   startup.sh executes, skips readiness checks
T=4s:   MCP server starts, tries to connect
T=5s:   Connection timeout OR database not fully ready
T=6s:   Server exits with code 1
        ❌ FAILURE: Database required but not found
```

The problem: The MCP server starts **before** the database is fully initialized.

## Fix Strategy

We need a **multi-layered approach**:

### Layer 1: Add Readiness Checks for External Database (startup.sh)

Add database readiness checks even when `USE_EXTERNAL_DB=true`:
- Check if PostgreSQL is accepting connections (`pg_isready` equivalent)
- Verify database initialization is complete (check if `recipes` table exists)
- Wait with retry logic and timeout

**Implementation:**
- Install `postgresql-client` tools in the Docker image for `psql` command
- Add connection test using `psql` to verify database is ready
- Add table existence check to verify initialization is complete
- Use retry logic (up to 60 seconds with 1-second intervals)

### Layer 2: Add Retry Logic to MCP Server (server.py)

Add exponential backoff retry logic when connecting to the database:
- Retry up to 5 times
- Exponential backoff: 2s, 4s, 8s, 16s, 32s (max ~62 seconds)
- Log each retry attempt
- Only fail after all retries exhausted

**Implementation:**
- Wrap `init_pool()` call in retry loop
- Use `asyncio.sleep()` for backoff delays
- Add detailed logging for debugging

### Layer 3: Improve GitHub Actions Healthcheck (optional)

Enhance the healthcheck to verify table existence:
- Use custom healthcheck script
- Check if `recipes` table exists
- Verify database is fully ready

**Implementation:**
- Create healthcheck script in the database Docker image
- Update workflow to use custom healthcheck

## Detailed Implementation Plan

### Step 1: Modify `startup.sh` to Add External Database Readiness Checks

**File:** `plugin/mcp-server/scripts/startup.sh`

**Changes:**

Replace lines 89-93 with comprehensive readiness checks for external database:

```bash
# Database readiness checks (both local and external modes)
echo "Verifying database connectivity..." >&2

if [[ "$USE_EXTERNAL_DB" == "true" ]]; then
    # External database mode: Use psql/pg_isready for checks
    echo "Checking external database at $DB_HOST:$DB_PORT..." >&2

    # Check if pg_isready is available
    if ! command -v pg_isready &> /dev/null; then
        echo "Warning: pg_isready not found, skipping connection check" >&2
        echo "Database readiness will be verified by MCP server" >&2
    else
        # Wait for database to accept connections
        MAX_RETRIES=60
        RETRY_COUNT=0

        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -q; then
                echo "✅ PostgreSQL is accepting connections" >&2
                break
            fi
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
                echo "Warning: Database not responding after ${MAX_RETRIES} seconds" >&2
                echo "MCP server will attempt connection with retry logic" >&2
                break
            fi
            sleep 1
        done

        # Verify table exists (initialization complete)
        if command -v psql &> /dev/null; then
            MAX_INIT_RETRIES=60
            INIT_RETRY_COUNT=0

            while [ $INIT_RETRY_COUNT -lt $MAX_INIT_RETRIES ]; do
                export PGPASSWORD="$DB_PASSWORD"
                if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
                    -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'recipes');" 2>/dev/null | grep -q "t"; then
                    echo "✅ Database initialization complete (recipes table exists)" >&2
                    unset PGPASSWORD
                    break
                fi
                unset PGPASSWORD
                INIT_RETRY_COUNT=$((INIT_RETRY_COUNT + 1))
                if [ $INIT_RETRY_COUNT -eq $MAX_INIT_RETRIES ]; then
                    echo "Warning: Could not verify database initialization after ${MAX_INIT_RETRIES} seconds" >&2
                    echo "MCP server will attempt connection anyway" >&2
                    break
                fi
                sleep 1
            done
        else
            echo "Warning: psql not found, skipping initialization verification" >&2
        fi
    fi
else
    # Local mode: existing comprehensive checks (unchanged)
    # ... existing code ...
fi
```

**Key features:**
- Non-blocking: Warnings instead of errors (allows MCP server retry to handle failures)
- Comprehensive: Checks both connectivity and initialization
- Graceful degradation: Falls back to MCP server retry if tools unavailable
- Informative logging: Clear status messages

### Step 2: Add Retry Logic to `server.py`

**File:** `plugin/mcp-server/src/server.py`

**Changes:**

Replace lines 187-200 with retry logic:

```python
async def main():
    """Run the MCP server."""
    logger.info(f"Starting {config.SERVER_NAME} v{config.SERVER_VERSION}")

    # Initialize database connection pool with retry logic
    MAX_RETRIES = 5
    RETRY_DELAYS = [2, 4, 8, 16, 32]  # Exponential backoff in seconds

    for attempt in range(MAX_RETRIES):
        try:
            logger.info(f"Database connection attempt {attempt + 1}/{MAX_RETRIES}")
            await init_pool(
                host=config.DB_HOST,
                port=config.DB_PORT,
                database=config.DB_NAME,
                user=config.DB_USER,
                password=config.DB_PASSWORD
            )
            logger.info("Database connection established")
            break  # Success, exit retry loop

        except Exception as e:
            logger.warning(f"Database connection attempt {attempt + 1} failed: {e}")

            if attempt < MAX_RETRIES - 1:
                delay = RETRY_DELAYS[attempt]
                logger.info(f"Retrying in {delay} seconds...")
                await asyncio.sleep(delay)
            else:
                logger.error("Failed to connect to database after all retry attempts")
                logger.error("Server cannot start without database connection")
                sys.exit(1)

    logger.info("Server ready to accept connections via stdio")

    try:
        async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
            await app.run(
                read_stream,
                write_stream,
                app.create_initialization_options()
            )
    finally:
        # Cleanup on shutdown
        await close_pool()
        logger.info("Server shutdown complete")
```

**Key features:**
- 5 retry attempts with exponential backoff (2, 4, 8, 16, 32 seconds)
- Total maximum wait time: ~62 seconds
- Clear logging for each attempt
- Only fails after all retries exhausted

### Step 3: Ensure PostgreSQL Client Tools in Docker Image

**File:** `eval/Dockerfile` (assuming this exists)

**Required change:**

Add PostgreSQL client tools installation:

```dockerfile
# Install PostgreSQL client tools for database readiness checks
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*
```

**Why:** The `pg_isready` and `psql` commands are needed for startup.sh checks.

### Step 4: Add Missing `asyncio` Import to `server.py`

**File:** `plugin/mcp-server/src/server.py`

**Change:** Ensure `asyncio` is imported at the top (currently imported only at bottom)

```python
#!/usr/bin/env python3
"""OpenRewrite MCP Server - Main server implementation."""
import sys
import logging
import json
import asyncio  # ← Add this import
from typing import Optional
```

## Expected Behavior After Fix

### Successful Scenario (Database Ready Quickly)

```
T=0s:   PostgreSQL service starts
T=1s:   PostgreSQL ready, tables initialized
T=2s:   Container starts, entrypoint.sh runs
T=3s:   startup.sh checks database connectivity
T=4s:   ✅ PostgreSQL is accepting connections
T=5s:   ✅ Database initialization complete
T=6s:   MCP server starts
T=7s:   MCP server connects on first attempt
T=8s:   ✅ Workflow proceeds successfully
```

### Delayed Initialization Scenario

```
T=0s:   PostgreSQL service starts
T=1s:   PostgreSQL accepting connections (not initialized)
T=2s:   Container starts, entrypoint.sh runs
T=3s:   startup.sh checks database connectivity
T=4s:   ✅ PostgreSQL is accepting connections
T=5s:   Checking for recipes table...
T=10s:  Checking for recipes table...
T=15s:  ✅ Database initialization complete
T=16s:  MCP server starts
T=17s:  MCP server connects on first attempt
T=18s:  ✅ Workflow proceeds successfully
```

### PostgreSQL Slow Start Scenario

```
T=0s:   PostgreSQL service starts (slow initialization)
T=5s:   Container starts, entrypoint.sh runs
T=6s:   startup.sh checks database connectivity
T=10s:  PostgreSQL not ready yet...
T=20s:  PostgreSQL not ready yet...
T=30s:  ✅ PostgreSQL is accepting connections
T=35s:  ✅ Database initialization complete
T=36s:  MCP server starts
T=37s:  MCP server connects on first attempt
T=38s:  ✅ Workflow proceeds successfully
```

### Failure Scenario (Database Never Ready)

```
T=0s:   PostgreSQL service starts
T=60s:  startup.sh timeout warning (database not ready)
T=61s:  MCP server starts anyway (retry logic)
T=62s:  MCP server attempt 1 failed, retry in 2s
T=64s:  MCP server attempt 2 failed, retry in 4s
T=68s:  MCP server attempt 3 failed, retry in 8s
T=76s:  MCP server attempt 4 failed, retry in 16s
T=92s:  MCP server attempt 5 failed
T=93s:  ❌ Server exits with code 1
```

## Testing Plan

### Test 1: Local Development (Existing Behavior)
- Start MCP server locally: `cd plugin/mcp-server && ./scripts/startup.sh`
- Verify local docker-compose mode still works
- Confirm no regression

### Test 2: GitHub Actions with Healthy Database
- Trigger workflow with test PR
- Verify successful connection
- Check logs for retry attempts (should be 0 or 1)

### Test 3: GitHub Actions with Delayed Database
- Simulate delay by using larger database image
- Verify retry logic works correctly
- Confirm workflow succeeds after retries

### Test 4: GitHub Actions with Failed Database
- Simulate complete failure (wrong credentials)
- Verify workflow fails gracefully after all retries
- Check error messages are clear

## Risk Assessment

### Low Risk Changes
✅ Adding retry logic to server.py (isolated change, clear benefit)
✅ Improving logging (information only, no behavior change)

### Medium Risk Changes
⚠️ Adding readiness checks to startup.sh for external mode:
- Risk: Could slow down startup unnecessarily
- Mitigation: Use warnings instead of errors, allow MCP server to retry

### No Risk Changes
✅ Adding asyncio import (already used at bottom of file)
✅ Adding PostgreSQL client tools to Docker image (utility only)

## Rollback Plan

If the fix causes issues:

1. **Immediate rollback:** Revert startup.sh changes only
   - Keep server.py retry logic (benign improvement)
   - Database checks will be skipped, server retry will handle

2. **Full rollback:** Revert all changes
   - Restore original startup.sh (lines 89-93)
   - Restore original server.py (lines 187-200)

## Success Criteria

✅ MCP server connects successfully in GitHub Actions
✅ No regression in local development mode
✅ Clear logging shows retry attempts
✅ Workflow completes without database connection errors
✅ Total startup time < 2 minutes (even with retries)

## Implementation Priority

1. **HIGH:** Add retry logic to server.py (Step 2)
   - Most critical fix
   - Handles all retry scenarios
   - Independent of other changes

2. **HIGH:** Add asyncio import (Step 4)
   - Required for retry logic
   - Trivial change

3. **MEDIUM:** Add readiness checks to startup.sh (Step 1)
   - Reduces startup time in success cases
   - Provides better diagnostics
   - Depends on PostgreSQL client tools

4. **MEDIUM:** Add PostgreSQL client tools to Docker (Step 3)
   - Required for startup.sh checks
   - May already be installed

## Files to Modify

1. `plugin/mcp-server/src/server.py` - Add retry logic
2. `plugin/mcp-server/scripts/startup.sh` - Add external DB checks
3. `eval/Dockerfile` (or relevant Dockerfile) - Add postgresql-client
4. (Optional) `.github/workflows/rewrite-assist.yml` - Enhanced healthcheck

## Estimated Implementation Time

- Step 1 (startup.sh): 15 minutes
- Step 2 (server.py): 10 minutes
- Step 3 (Dockerfile): 5 minutes
- Step 4 (import): 1 minute
- Testing: 30 minutes
- **Total: ~1 hour**
