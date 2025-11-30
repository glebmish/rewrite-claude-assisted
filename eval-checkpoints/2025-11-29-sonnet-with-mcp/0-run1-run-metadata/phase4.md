# Phase 4: Recipe Validation

## Validation Results

### Option 1: Broad Approach
- **Precision**: 0.40 (40%)
- **Recall**: 0.67 (67%)
- **F1 Score**: 0.50 (50%)
- **Key Issue**: Used legacy sourceCompatibility/targetCompatibility instead of Java toolchain API
- **Over-applications**: 21 extra changes (dependency upgrades, API modernizations)

### Option 2: Narrow Approach
- **Precision**: 0.74 (74%)
- **Recall**: 0.67 (67%)
- **F1 Score**: 0.70 (70%)
- **Key Issue**: Updated sourceCompatibility/targetCompatibility to 21 instead of migrating to toolchain API
- **Missing**: README Gradle version reference not updated

## Comparison
- Option 2 has better precision (fewer unwanted changes)
- Both have same recall (same number of PR changes covered)
- Option 2 has better overall F1 score
- Both missed the Java toolchain API migration pattern

## Files Created
- option-1-recipe.diff, option-1-stats.json, option-1-validation-analysis.md
- option-2-recipe.diff, option-2-stats.json, option-2-validation-analysis.md

## Status
✓ Phase 4 completed successfully
