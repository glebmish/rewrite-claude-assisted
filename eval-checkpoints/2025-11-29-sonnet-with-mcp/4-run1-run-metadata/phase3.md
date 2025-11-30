# Phase 3: Recipe Mapping

## Recipe Options Created

### Option 1: Semantic + Text Fallbacks
- **Recipe Name**: `com.example.H2ToPostgreSQLMigrationOption1`
- **File**: `option-1-recipe.yaml`
- **Approach**: 80% semantic recipes, 20% text-based fallbacks
- **Recipe Count**: 16 steps

**Composition**:
- Semantic recipes for GitHub Actions, Gradle dependencies, YAML configuration
- Text replacements for Dockerfile and SQL files (no semantic alternatives available)

**Strengths**:
- Robust to formatting variations
- Type-aware transformations
- Leverages OpenRewrite's semantic understanding

### Option 2: Pure Text-Based
- **Recipe Name**: `com.example.H2ToPostgreSQLMigrationOption2`
- **File**: `option-2-recipe.yaml`
- **Approach**: 100% text-based replacements
- **Recipe Count**: 12 steps

**Composition**:
- All transformations using `FindAndReplace` recipe
- Exact string matching for all file types

**Strengths**:
- Simpler recipe structure
- Predictable behavior
- Easier to understand

**Weaknesses**:
- Fragile to formatting variations
- Requires exact whitespace matching
- Less maintainable

## Status
✓ Phase 3 completed successfully - both recipe options created
