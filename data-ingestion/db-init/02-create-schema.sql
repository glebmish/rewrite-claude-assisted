-- Simple schema: recipe name + full markdown documentation
CREATE TABLE IF NOT EXISTS recipes (
    id SERIAL PRIMARY KEY,
    recipe_name VARCHAR(500) UNIQUE NOT NULL,
    markdown_doc TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for recipe name lookups
CREATE INDEX IF NOT EXISTS idx_recipes_name ON recipes(recipe_name);

-- Table for recipe structured metadata (Phase 3)
-- Stores structured information extracted from recipes for better search and display
CREATE TABLE IF NOT EXISTS recipe_metadata (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE UNIQUE,
    display_name VARCHAR(500),
    description TEXT,
    tags TEXT[],  -- Array of tags for filtering
    is_composite BOOLEAN DEFAULT FALSE,
    recipe_count INTEGER DEFAULT 0,  -- Number of sub-recipes
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for recipe_id lookups
CREATE INDEX IF NOT EXISTS idx_recipe_metadata_recipe_id ON recipe_metadata(recipe_id);

-- Index for tag searches using GIN (Generalized Inverted Index)
CREATE INDEX IF NOT EXISTS idx_recipe_metadata_tags ON recipe_metadata USING GIN(tags);

-- Table for embeddings (Phase 3)
-- Dimension: 384 for sentence-transformers (development), 1024 for Voyage AI (production)
CREATE TABLE IF NOT EXISTS recipe_embeddings (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    embedding vector(384),  -- Change to vector(1024) when using Voyage AI
    embedding_model VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(recipe_id, embedding_model)  -- Allow multiple embeddings per recipe (different models)
);

-- Index for recipe_id lookups
CREATE INDEX IF NOT EXISTS idx_recipe_embeddings_recipe_id ON recipe_embeddings(recipe_id);

-- Index for vector similarity search (Phase 3)
-- Using HNSW (Hierarchical Navigable Small World) for better performance than IVFFlat
-- Parameters:
--   m = 16: Number of connections per node (higher = better recall, larger index)
--   ef_construction = 64: Build-time search breadth (higher = better quality, slower build)
CREATE INDEX IF NOT EXISTS idx_recipe_embeddings_vector
ON recipe_embeddings USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
