FROM pgvector/pgvector:pg16

# Copy schema initialization scripts (run in alphabetical order)
COPY db-init/01-create-extensions.sql /docker-entrypoint-initdb.d/01-create-extensions.sql
COPY db-init/02-create-schema.sql /docker-entrypoint-initdb.d/02-create-schema.sql

# Copy database dump (loaded after schema)
COPY recipes-dump.sql /docker-entrypoint-initdb.d/03-load-data.sql

# Set default environment variables
ENV POSTGRES_DB=openrewrite_recipes \
    POSTGRES_USER=mcp_user \
    POSTGRES_PASSWORD=changeme

# Metadata labels (populated during build with --build-arg)
ARG RECIPE_COUNT=0
ARG BUILD_DATE=unknown
ARG DB_SIZE=unknown

LABEL org.openrewrite.recipes.count="${RECIPE_COUNT}" \
      org.openrewrite.recipes.date="${BUILD_DATE}" \
      org.openrewrite.recipes.size="${DB_SIZE}"
