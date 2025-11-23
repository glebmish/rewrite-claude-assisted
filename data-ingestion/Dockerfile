FROM pgvector/pgvector:pg16

# Copy the database dump
# Note: pg_dump includes everything: CREATE EXTENSION, schema (CREATE TABLE), and data
# The dump is self-contained and doesn't need additional init scripts
COPY recipes-dump.sql /docker-entrypoint-initdb.d/01-load-data.sql

# Set default environment variables
ENV POSTGRES_DB=openrewrite_recipes \
    POSTGRES_USER=mcp_user \
    POSTGRES_PASSWORD=changeme
