# Phase 4: Recipe Validation

## Validation Results

### Option 1 (Broad Approach)
| Metric | Value |
|--------|-------|
| Precision | 32.26% |
| Recall | 47.62% |
| F1 Score | 38.46% |
| Perfect Match | No |

**Issues:**
- Over-application: 21 false positives (Java code modernization, Guava upgrade, Gradle wrapper files)
- Under-coverage: 11 false negatives (toolchain DSL, wrapper block, step name, README formatting)
- `UpgradeToJava21` applies too many unrelated transformations

### Option 2 (Narrow/Targeted Approach)
| Metric | Value |
|--------|-------|
| Precision | 100% |
| Recall | 100% |
| F1 Score | 100% |
| Perfect Match | Yes |

**Result:** All 21 expected changes matched exactly with no false positives or negatives.

## Files Produced
- `option-1-recipe.diff` - 31 resulting changes (21 false positives)
- `option-1-stats.json` - F1: 0.3846
- `option-1-validation-analysis.md`
- `option-2-recipe.diff` - 21 resulting changes (perfect match)
- `option-2-stats.json` - F1: 1.0
- `option-2-validation-analysis.md`

## Conclusion
Option 2 significantly outperforms Option 1. The targeted approach achieves perfect precision and recall.
