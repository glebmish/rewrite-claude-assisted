# Phase 3: Recipe Mapping

## Summary
Successfully created two recipe options for Dropwizard 2.1.12 → 3.0.0 migration.

## Key Finding
No dedicated OpenRewrite recipe exists for Dropwizard 3.0 migration. Composed recipes from:
- Java version upgrade recipes
- Gradle dependency upgrade recipes
- Type change recipes for package migrations

## Recipe Options Created

### Option 1: Broad Approach (11 recipes)
- **Strategy**: Comprehensive Java 17 migration + Dropwizard-specific changes
- **File**: `option-1-recipe.yaml`
- **Coverage**: Java toolchain, all dependencies, package relocations, @Override removal (too broad)
- **Pros**: Future-proof, comprehensive
- **Cons**: Scope beyond PR, extensive testing needed

### Option 2: Targeted Approach (10 recipes)
- **Strategy**: Surgical changes matching PR scope
- **File**: `option-2-recipe.yaml`
- **Coverage**: Java toolchain (minimal), all dependencies, package relocations
- **Gap**: @Override removal not covered (requires custom recipe)
- **Pros**: Minimal scope, predictable
- **Cons**: Manual @Override cleanup needed

## Coverage Analysis
Both options handle:
- ✓ Java version 11→17 in Gradle
- ✓ All 5 Dropwizard dependency upgrades
- ✓ All 4 package import migrations

Gap:
- @Override annotation removal requires custom recipe or manual intervention

## Output Files
- `option-1-recipe.yaml`, `option-1-creation-analysis.md`
- `option-2-recipe.yaml`, `option-2-creation-analysis.md`

## Status
✓ Phase 3 completed successfully
