# Phase 3: Recipe Mapping

## Recipe Discovery
Searched OpenRewrite recipe catalog for Dropwizard-related recipes.

**Key Finding**: No comprehensive Dropwizard 2.x → 3.x migration recipe exists in the OpenRewrite ecosystem.

## Alternative Approaches Created

### Option 1: Broad/General Approach
- **Recipe file**: option-1-recipe.yaml
- **Analysis file**: option-1-creation-analysis.md
- **Strategy**: Use composite recipes and wildcard patterns
- **Recipe count**: 4 steps
- **Key recipes**:
  - Java 11→17 migration composite
  - Wildcard dependency upgrade (io.dropwizard:*)
  - Package migration using ChangePackage
  - Semantic @Override analysis

### Option 2: Surgical/Specific Approach
- **Recipe file**: option-2-recipe.yaml
- **Analysis file**: option-2-creation-analysis.md
- **Strategy**: Explicit individual transformations
- **Recipe count**: 14 steps
- **Key recipes**:
  - Direct Gradle Java version change
  - 5 individual dependency upgrades
  - 4 precise ChangeType recipes for imports
  - Broad @Override removal

## Recipe Comparison

| Aspect | Option 1 | Option 2 |
|--------|----------|----------|
| Approach | Broad patterns | Explicit steps |
| Complexity | Simpler (4 recipes) | More verbose (14 recipes) |
| Java upgrade | Composite migration | Direct version change |
| Dependencies | Wildcard matching | Individual upgrades |
| Package migration | ChangePackage (risky) | ChangeType (precise) |
| Maintainability | Higher | Lower |

## Coverage Analysis

### Fully Covered
✓ Java version upgrade (11→17)
✓ Dropwizard dependency updates (2.1.12→3.0.0)
✓ Core package import migration (io.dropwizard → io.dropwizard.core)

### Partially Covered
⚠ @Override annotation removal
- Option 1: Uses semantic analysis (may not detect non-override methods)
- Option 2: Uses blanket removal (too aggressive)

## Identified Gaps
Both options may have precision issues with @Override removal:
- Need type hierarchy analysis to detect which methods no longer override in Dropwizard 3.0
- Generic removal recipes may be too broad or too narrow

## Files Created
- option-1-recipe.yaml
- option-1-creation-analysis.md
- option-2-recipe.yaml
- option-2-creation-analysis.md

## Status
✓ Phase 3 completed successfully
- Two alternative recipe compositions created
- Both recipes are valid YAML and executable
- Ready for validation phase
