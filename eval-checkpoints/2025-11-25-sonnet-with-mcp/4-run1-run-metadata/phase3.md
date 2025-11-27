# Phase 3: Recipe Mapping

## Approach
Used specialized openrewrite-expert agents in parallel to create two distinct recipe options.

## Option 1: Surgical Approach
- **Recipe**: `option-1-recipe.yaml`
- **Strategy**: Narrow, targeted recipes for maximum precision
- **Recipe count**: 13 individual steps
- **Focus**: Granular control, easy debugging

### Coverage
- Gradle: 5 recipes (1 remove + 4 add dependencies)
- YAML: 5 recipes (property changes)
- GitHub Actions: 1 recipe (version bump)
- SQL: 1 text-based recipe (syntax translation)
- Dockerfile: 1 text-based recipe (base image)

## Option 2: Comprehensive Declarative Approach
- **Recipe**: `option-2-recipe.yaml`
- **Strategy**: Broader, standard recipes with explicit transformations
- **Recipe count**: 13 recipe steps
- **Focus**: Transparency and maintainability

### Coverage
- Gradle: 6 recipes (dependency management)
- YAML: 5 recipes (configuration updates)
- GitHub Actions: 1 recipe (action version)
- SQL: 1 text-based recipe (dialect conversion)
- Dockerfile: 1 text-based recipe (image update)

## Analysis
Both options provide complete coverage of PR transformations. Main differences:
- Similar structure and count
- Both use semantic recipes where available
- Both fall back to text replacement for SQL/Dockerfile
- Option 1 emphasizes surgical precision
- Option 2 emphasizes explicit, traceable changes

## Files Created
✓ option-1-recipe.yaml
✓ option-1-creation-analysis.md
✓ option-2-recipe.yaml
✓ option-2-creation-analysis.md
