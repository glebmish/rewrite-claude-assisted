# Phase 4: Recipe Validation

## Option 1 Validation Results (Broad Approach)

**Files Created**:
- option-1-recipe.diff (11K)
- option-1-stats.json
- option-1-validation-analysis.md

**Metrics**:
- Precision: 64.52%
- Recall: 64.52%
- F1 Score: 64.52%
- True Positives: 20
- False Positives: 11
- False Negatives: 11

**Critical Issues**:
1. JUnit dependency misconfiguration (wrong scope, wrong artifacts)
2. Missing Gradle property updates (mainClassName → mainClass)
3. Java toolchain gap (uses legacy sourceCompatibility)
4. Mockito major version jump (3.x → 4.x without migration)

**Strengths**:
- Successfully updated Gradle wrapper and shadow plugin
- Properly migrated JUnit annotations and assertions
- Applied modern Java API improvements

## Option 2 Validation Results (Narrow Approach)

**Files Created**:
- option-2-recipe.diff (9.5K)
- option-2-stats.json
- option-2-validation-analysis.md

**Metrics**:
- Precision: 76%
- Recall: 61.29%
- F1 Score: 67.86%
- True Positives: 19
- False Positives: 6
- False Negatives: 12

**Gaps**:
1. GitHub Actions step name not updated
2. Java toolchain syntax not used
3. JUnit dependencies wrong scope and version
4. Comments not updated
5. mainClassName migrations incomplete

**Over-applications**:
- Extensive gradle wrapper updates (acceptable)
- SHA256 sum added (security enhancement)

**Strengths**:
- Better precision (76% vs 64.52%)
- Fewer unwanted changes
- More controlled transformations

## Comparative Analysis

| Metric | Option 1 (Broad) | Option 2 (Narrow) | Winner |
|--------|------------------|-------------------|---------|
| Precision | 64.52% | 76% | Option 2 |
| Recall | 64.52% | 61.29% | Option 1 |
| F1 Score | 64.52% | 67.86% | Option 2 |
| False Positives | 11 | 6 | Option 2 |
| False Negatives | 11 | 12 | Option 1 |
| Critical Issues | 4 | 5 | Option 1 |

**Overall**: Option 2 shows better precision and fewer unwanted changes, though neither option achieves complete coverage.
