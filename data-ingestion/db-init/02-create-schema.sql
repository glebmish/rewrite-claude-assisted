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

-- Table for embeddings (Phase 3)
CREATE TABLE IF NOT EXISTS recipe_embeddings (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    embedding vector(384),
    embedding_model VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index for vector similarity search (Phase 3)
CREATE INDEX IF NOT EXISTS idx_recipe_embeddings_vector
ON recipe_embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
