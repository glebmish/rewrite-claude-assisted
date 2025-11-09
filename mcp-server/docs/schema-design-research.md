# OpenRewrite MCP Database Schema - Research & Future Enhancements

## Current Implementation (Phase 2 - Simple)

**Single table design:**
```sql
CREATE TABLE recipes (
    id SERIAL PRIMARY KEY,
    recipe_name VARCHAR(500) UNIQUE NOT NULL,
    markdown_doc TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Rationale:**
- Store full markdown documentation from rewrite-docs
- Recipe name is the fully qualified name (e.g., `org.openrewrite.java.ChangeType`)
- All metadata, examples, options embedded in markdown
- Simple to implement and maintain
- Can extract structured data later if needed

---

## Future Enhancement Opportunities

### Discovered Data Model

From analyzing three OpenRewrite repositories:
- `rewrite-gradle-plugin` - Shows programmatic recipe discovery
- `rewrite-docs` - Contains actual markdown documentation
- `rewrite-recipe-markdown-generator` - Code that generates docs

### Key Findings

**1. RecipeDescriptor API**
OpenRewrite provides programmatic access to recipe metadata:
```java
Environment env = Environment.builder()
    .scanJar(jarPath, dependencies, classloader)
    .build();
Collection<RecipeDescriptor> recipes = env.listRecipeDescriptors();
```

**2. Rich Metadata Available**
Each RecipeDescriptor contains:
- Core: name, displayName, description, source URI
- Configuration: options (type, description, example, required, valid values)
- Composition: recipeList (child recipes for composite recipes)
- Metadata: tags, examples, dataTables

**3. Recipe Relationships**
- Recipes can contain other recipes
- Parent-child composition tracked
- "Used by" reverse mapping for discovery

**4. Artifact Metadata**
From JAR manifests:
- Maven coordinates (groupId:artifactId:version)
- License information
- Repository URLs (GitHub)
- Issue tracker URLs

---

## Enhanced Schema Design (Future Phase)

### Core Tables

**`recipes`** - Main recipe information
```sql
CREATE TABLE recipes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(500) UNIQUE NOT NULL,
    display_name VARCHAR(500) NOT NULL,
    description TEXT,
    source_type VARCHAR(50),  -- 'imperative' or 'declarative'
    source_uri TEXT,
    artifact_id INTEGER REFERENCES artifacts(id),
    markdown_doc TEXT,  -- Full documentation
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**`recipe_options`** - Configuration parameters
```sql
CREATE TABLE recipe_options (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(100),
    description TEXT,
    example TEXT,
    is_required BOOLEAN DEFAULT false,
    valid_values JSONB,
    display_order INTEGER,
    UNIQUE(recipe_id, name)
);
```

**`recipe_relationships`** - Parent-child composition
```sql
CREATE TABLE recipe_relationships (
    id SERIAL PRIMARY KEY,
    parent_recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    child_recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    display_order INTEGER,
    configuration JSONB,
    UNIQUE(parent_recipe_id, child_recipe_id, display_order)
);
```

**`recipe_tags`** - Classification
```sql
CREATE TABLE recipe_tags (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    tag VARCHAR(200) NOT NULL,
    UNIQUE(recipe_id, tag)
);
```

**`artifacts`** - Maven artifacts
```sql
CREATE TABLE artifacts (
    id SERIAL PRIMARY KEY,
    group_id VARCHAR(200) NOT NULL,
    artifact_id VARCHAR(200) NOT NULL,
    version VARCHAR(100) NOT NULL,
    license VARCHAR(200),
    license_url TEXT,
    repository_url TEXT,
    issue_tracker_url TEXT,
    UNIQUE(group_id, artifact_id, version)
);
```

**`recipe_examples`** - Code examples
```sql
CREATE TABLE recipe_examples (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    file_name VARCHAR(200),
    language VARCHAR(50),
    code_before TEXT,
    code_after TEXT,
    diff TEXT,
    parameters JSONB,
    display_order INTEGER
);
```

**`categories`** - Package organization
```sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    package_name VARCHAR(500) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    description TEXT,
    parent_category_id INTEGER REFERENCES categories(id)
);
```

**`recipe_data_tables`** - Tables produced by recipes
```sql
CREATE TABLE recipe_data_tables (
    id SERIAL PRIMARY KEY,
    recipe_id INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    table_class VARCHAR(500) NOT NULL,
    table_name VARCHAR(200),
    description TEXT,
    UNIQUE(recipe_id, table_class)
);
```

**`data_table_columns`** - Column definitions
```sql
CREATE TABLE data_table_columns (
    id SERIAL PRIMARY KEY,
    data_table_id INTEGER REFERENCES recipe_data_tables(id) ON DELETE CASCADE,
    column_name VARCHAR(200) NOT NULL,
    description TEXT,
    display_order INTEGER
);
```

### Views for Common Queries

**Recipe with full metadata:**
```sql
CREATE VIEW v_recipes_full AS
SELECT
    r.id,
    r.name,
    r.display_name,
    r.description,
    a.group_id,
    a.artifact_id,
    a.version,
    a.license,
    (SELECT COUNT(*) FROM recipe_relationships WHERE parent_recipe_id = r.id) as child_count,
    (SELECT COUNT(*) FROM recipe_relationships WHERE child_recipe_id = r.id) as parent_count,
    (SELECT json_agg(tag ORDER BY tag) FROM recipe_tags WHERE recipe_id = r.id) as tags
FROM recipes r
LEFT JOIN artifacts a ON r.artifact_id = a.id;
```

**Recipe dependencies (used by):**
```sql
CREATE VIEW v_recipe_used_by AS
SELECT
    r_child.name as recipe_name,
    r_parent.name as used_by_recipe_name,
    r_parent.display_name as used_by_display_name
FROM recipe_relationships rr
JOIN recipes r_child ON rr.child_recipe_id = r_child.id
JOIN recipes r_parent ON rr.parent_recipe_id = r_parent.id;
```

---

## Data Extraction Strategy

### Option 1: Use OpenRewrite Environment API (Recommended)

**Advantages:**
- Programmatic access to structured metadata
- No HTML parsing or web scraping
- Maintained by OpenRewrite team
- Comprehensive data extraction

**Implementation:**
```java
Environment env = Environment.builder()
    .scanJar(jarPath, dependencies, classloader)
    .build();

for (RecipeDescriptor recipe : env.listRecipeDescriptors()) {
    // Extract all metadata
    String name = recipe.getName();
    String displayName = recipe.getDisplayName();
    String description = recipe.getDescription();
    List<OptionDescriptor> options = recipe.getOptions();
    List<RecipeDescriptor> children = recipe.getRecipeList();
    Set<String> tags = recipe.getTags();

    // Store in database
}
```

**Workflow:**
1. Download all OpenRewrite recipe JARs
2. Load via Environment.scanJar()
3. Extract RecipeDescriptor metadata
4. Parse JAR manifests for artifact info
5. Store in database

### Option 2: Parse Markdown Documentation

**Advantages:**
- Already available in rewrite-docs
- Includes hand-written examples and details
- No Java dependencies needed

**Disadvantages:**
- Markdown parsing can be fragile
- May miss programmatic metadata
- Requires keeping docs in sync

**Implementation:**
- Parse markdown frontmatter (YAML)
- Extract sections (options, examples, usage)
- Store structured data or full markdown

### Option 3: Hybrid Approach

Use both sources:
- RecipeDescriptor for structured metadata
- Markdown for rich documentation and examples
- Combine for comprehensive coverage

---

## Implementation Phases

### Phase 1: Simple (Current)
- Single table with recipe_name + markdown_doc
- Direct storage of documentation
- Quick to implement

### Phase 2: Add Embeddings
- Add embeddings table
- Generate vectors for semantic search
- Keep simple recipe storage

### Phase 3: Structured Metadata
- Add recipe_options, recipe_tags tables
- Parse markdown or use RecipeDescriptor
- Enable advanced queries

### Phase 4: Full Relational Model
- Add all tables (relationships, artifacts, examples)
- Programmatic extraction from JARs
- Complete metadata coverage

### Phase 5: Automation
- Scheduled updates from OpenRewrite releases
- Version tracking
- Change detection

---

## Benefits of Enhanced Schema

**Better Search:**
- Filter by tags
- Search by option names
- Find recipes by framework/category

**Relationship Queries:**
- "What recipes use this recipe?"
- "Show me all child recipes"
- Recipe composition trees

**Metadata Extraction:**
- Structured option data
- Typed parameters
- Example extraction

**Source Tracking:**
- Know which JAR contains each recipe
- License compliance
- GitHub links

**Advanced Features:**
- Recipe recommendation
- Popularity tracking
- Usage analytics

---

## Migration Path

**From Simple to Enhanced:**

1. Add new tables alongside existing recipes table
2. Keep markdown_doc column for backward compatibility
3. Gradually populate structured tables
4. Update queries to use new tables
5. Eventually deprecate markdown_doc column

**Data Preservation:**
- Markdown can be regenerated from structured data
- Or keep both for redundancy
- Markdown useful for display, structured data for queries

---

## File Locations (for reference)

**Analysis Source:**
- `/home/user/rewrite-claude-assisted/.scratchpad/2025-11-08-13-21/recipe-data-structure-analysis.md`

**Cloned Repositories:**
- `.workspace/rewrite-gradle-plugin` - Recipe discovery
- `.workspace/rewrite-docs` - Documentation
- `.workspace/rewrite-recipe-markdown-generator` - Doc generation

**Key Files:**
- `rewrite-gradle-plugin/.../DefaultProjectParser.java` - Environment usage
- `rewrite-docs/docs/recipes/...` - Markdown documentation
- `rewrite-recipe-markdown-generator/.../RecipeLoader.kt` - JAR scanning

---

## Recommendations

**For Phase 2/3 (Current Focus):**
- Keep simple schema (name + markdown)
- Add embeddings for semantic search
- Focus on RAG quality over schema complexity

**For Phase 4+ (Future):**
- Implement programmatic extraction
- Build Java tool using Environment API
- Populate structured tables
- Enable advanced queries

**Don't Over-Engineer:**
- Simple schema works well for RAG
- Embeddings work on any text (markdown is fine)
- Can always enhance later
- Focus on user experience first

---

## References

- OpenRewrite Environment API: `org.openrewrite.config.Environment`
- RecipeDescriptor: `org.openrewrite.config.RecipeDescriptor`
- Documentation: https://docs.openrewrite.org
- Recipe Catalog: https://docs.openrewrite.org/recipes

---

*Last updated: 2025-11-08*
*Status: Research document - Not currently implemented*
