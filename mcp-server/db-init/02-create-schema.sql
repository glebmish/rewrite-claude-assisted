-- Main recipes table
CREATE TABLE IF NOT EXISTS recipes (
    id SERIAL PRIMARY KEY,
    recipe_id VARCHAR(500) UNIQUE NOT NULL,
    name VARCHAR(500) NOT NULL,
    description TEXT,
    full_documentation TEXT,
    usage_instructions TEXT,
    source_url TEXT,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Examples table (1-to-many with recipes)
CREATE TABLE IF NOT EXISTS recipe_examples (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    title VARCHAR(500),
    before_code TEXT,
    after_code TEXT,
    display_order INTEGER DEFAULT 0
);

-- Configuration options table (1-to-many with recipes)
CREATE TABLE IF NOT EXISTS recipe_options (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    name VARCHAR(200),
    type VARCHAR(50),
    description TEXT,
    default_value TEXT,
    display_order INTEGER DEFAULT 0
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_recipes_tags ON recipes USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_recipes_recipe_id ON recipes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipes_name ON recipes(name);

-- Table for embeddings (Phase 3)
-- Will be populated when Phase 3 is implemented
CREATE TABLE IF NOT EXISTS recipe_embeddings (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    embedding vector(384),
    embedding_model VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index for vector similarity search (Phase 3)
-- Note: This will be slow until we have enough data to benefit from IVFFlat
CREATE INDEX IF NOT EXISTS idx_recipe_embeddings_vector
ON recipe_embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
