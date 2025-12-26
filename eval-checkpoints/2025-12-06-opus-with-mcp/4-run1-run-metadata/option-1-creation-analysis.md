# Option 1 Recipe Analysis - Broad Approach

## Strategy
Prioritizes **semantic, structure-aware recipes** over text manipulation. Uses broader recipes where available.

## Intent Coverage

### Gradle Dependencies (100% covered)
| Intent | Recipe | Semantic? |
|--------|--------|-----------|
| Remove H2 | `org.openrewrite.gradle.RemoveDependency` | Yes - understands Gradle DSL |
| Add PostgreSQL | `org.openrewrite.gradle.AddDependency` | Yes - adds to correct config |
| Add 3x Testcontainers | `org.openrewrite.gradle.AddDependency` (x3) | Yes |

**Rationale**: Gradle-specific recipes understand build file structure, handle both Groovy and Kotlin DSL.

### YAML Configuration (100% covered)
| Intent | Recipe | Semantic? |
|--------|--------|-----------|
| Change driverClass | `org.openrewrite.yaml.ChangeValue` | Yes - JsonPath navigation |
| Change user | `org.openrewrite.yaml.ChangeValue` | Yes |
| Change password | `org.openrewrite.yaml.ChangeValue` | Yes |
| Change url | `org.openrewrite.yaml.ChangeValue` | Yes |
| Change hibernate.dialect | `org.openrewrite.yaml.ChangeValue` | Yes |

**Rationale**: `ChangeValue` with JsonPath (`$.database.driverClass`) is semantic - it navigates YAML structure rather than doing text replacement.

### SQL Migration (partial coverage)
| Intent | Recipe | Semantic? |
|--------|--------|-----------|
| BIGINT AUTO_INCREMENT -> BIGSERIAL | `org.openrewrite.text.FindAndReplace` | No |

**Gap Analysis**: No H2-to-PostgreSQL SQL migration recipe exists. Searched for:
- "migrate H2 to PostgreSQL" - returned Oracle/SQLServer converters only
- "convert SQL data type" - `org.openrewrite.sql.ConvertDataType` exists but doesn't have H2 mappings

**Justification for text recipe**: This is a specific syntax difference between H2 and PostgreSQL. The `AUTO_INCREMENT` keyword is H2-specific and `BIGSERIAL` is PostgreSQL-specific. No semantic SQL recipe covers this conversion.

### Dockerfile (partial coverage)
| Intent | Recipe | Semantic? |
|--------|--------|-----------|
| Update base image | `org.openrewrite.text.FindAndReplace` | No |

**Gap Analysis**: Searched for Docker image recipes:
- `org.openrewrite.docker.search.FindDockerImageUses` - search only, no modification
- `org.openrewrite.kubernetes.UpdateContainerImageName` - Kubernetes-specific

**Justification for text recipe**: No semantic Dockerfile recipe exists for changing `FROM` instruction. The text replacement is exact and safe for this use case.

### GitHub Actions (100% covered)
| Intent | Recipe | Semantic? |
|--------|--------|-----------|
| actions/cache@v2 -> v4 | `org.openrewrite.github.ChangeActionVersion` | Yes - GH Actions aware |

**Rationale**: This recipe understands GitHub Actions workflow structure and correctly updates version tags.

## Coverage Summary

| Category | Semantic | Text-based | Notes |
|----------|----------|------------|-------|
| Gradle | 5/5 | 0 | Full semantic coverage |
| YAML | 5/5 | 0 | JsonPath-based navigation |
| SQL | 0/1 | 1 | No H2->PG recipe exists |
| Dockerfile | 0/1 | 1 | No FROM update recipe |
| GitHub Actions | 1/1 | 0 | Full semantic coverage |
| **Total** | **11/13** | **2/13** | **85% semantic** |

## Gaps Identified

1. **No H2 to PostgreSQL SQL migration recipe** - Would need custom recipe or text replacement
2. **No Dockerfile FROM instruction update recipe** - Docker recipes are search-only

## Considerations

- Recipe order matters: Gradle changes first, then config changes
- The `ChangeValue` recipe preserves YAML formatting and structure
- Text replacements are scoped to specific file patterns to avoid unintended changes
- GitHub Actions recipe will update all workflow files matching the pattern
