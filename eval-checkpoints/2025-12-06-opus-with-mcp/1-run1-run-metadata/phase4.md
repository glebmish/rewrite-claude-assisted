# Phase 4: Recipe Validation

## Option 1 Results (Broad Approach)
| Metric | Value |
|--------|-------|
| Precision | 76.92% |
| Recall | 3.39% |
| F1 Score | 6.49% |

**Findings**:
- Correctly updated: build.gradle, Dockerfile, gradle-wrapper.properties
- Over-applications: ci.yml, gradlew script, wrapper JAR, added distributionSha256Sum

## Option 2 Results (Narrow Approach)
| Metric | Value |
|--------|-------|
| Precision | 90.91% |
| Recall | 3.39% |
| F1 Score | 6.54% |

**Findings**:
- Correctly updated: build.gradle, Dockerfile, gradle-wrapper.properties
- More precise than Option 1 (fewer false positives)

## Comparison
- **Precision**: Option 2 > Option 1 (90.91% vs 76.92%)
- **Recall**: Equal (3.39% - both miss auth refactoring)
- **F1 Score**: Slightly better for Option 2

## Common Gaps (Not Automatable)
- Authentication refactoring (ChainedAuthFilter → BasicCredentialAuthFilter)
- File deletions (JwtAuthFilter, JwtAuthenticator, ApiKeyAuthFilter)
- User class modifications
- Test updates

## Status
Phase 4 completed. Both recipes validated with output diffs and stats.
