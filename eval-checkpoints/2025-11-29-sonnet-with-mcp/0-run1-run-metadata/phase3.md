# Phase 3: Recipe Mapping

## Recipe Discovery Strategy

Two approaches used:
1. **Option 1**: Broad/general recipes for comprehensive coverage
2. **Option 2**: Narrow/specific recipes for surgical precision

## Option 1: Broad Approach
- **Core Recipe**: org.openrewrite.java.migrate.UpgradeToJava21
- **Additional**: Gradle wrapper update, text replacements for Docker/README
- **Strategy**: Use official migration recipes for maximum coverage
- **Files Created**:
  - option-1-recipe.yaml
  - option-1-creation-analysis.md

## Option 2: Narrow Approach
- **Core Recipes**: Targeted semantic recipes for each change type
- **Strategy**: Surgical precision with minimal side effects
- **Files Created**:
  - option-2-recipe.yaml
  - option-2-creation-analysis.md

## Coverage
Both options provide 100% coverage of the intent tree requirements

## Status
✓ Phase 3 completed successfully
