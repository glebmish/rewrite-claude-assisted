# Option 2: Comprehensive Recipe Composition Analysis

## Strategy Overview
Broader, more declarative approach using comprehensive recipes with multiple individual transformations. Emphasizes simplicity and standard OpenRewrite patterns.

## Recipe Mapping

### 1. Gradle Dependency Management
**Pattern**: Remove + Add approach
- `org.openrewrite.gradle.RemoveDependency` - Remove H2
- `org.openrewrite.gradle.AddDependency` (5 instances) - Add PostgreSQL and Testcontainers dependencies

**Rationale**: Simple, atomic operations. Each dependency change is explicit and declarative. Uses standard Gradle recipes with full LST understanding.

**Coverage**: 100% of Gradle dependency changes

### 2. YAML Configuration Updates
**Pattern**: Property-by-property updates using ChangePropertyValue
- 5 instances of `org.openrewrite.yaml.ChangePropertyValue`
- Targets: driverClass, hibernate.dialect, user, password, url

**Rationale**:
- Uses YAML-aware semantic recipes (not text replacement)
- Supports dot notation for nested properties
- filePattern restricts to config files only
- Each property change is explicit and traceable

**Coverage**: 100% of YAML config changes. Handles:
- Driver class: H2 → PostgreSQL
- Dialect: H2Dialect → PostgreSQLDialect
- Credentials externalization to environment variables
- URL replacement with regex matching

### 3. GitHub Actions Update
**Pattern**: Dedicated GitHub Actions recipe
- `org.openrewrite.github.ChangeActionVersion`

**Rationale**:
- GitHub Actions-specific recipe understands workflow YAML structure
- Semantic understanding of action references
- Automatically handles version syntax

**Coverage**: 100% of GitHub Actions version bumps

### 4. SQL Migration Syntax
**Pattern**: FindAndReplace for dialect translation
- `org.openrewrite.FindAndReplace` for AUTO_INCREMENT → BIGSERIAL

**Rationale**:
- SQL-specific recipes (like org.openrewrite.sql.ConvertDataType) require Moderne proprietary license
- FindAndReplace is acceptable here as it's a simple, unambiguous syntax transformation
- Pattern "BIGINT AUTO_INCREMENT" is unique and safe to replace globally

**Limitation**: This is text-based replacement, not SQL-aware transformation

**Coverage**: 100% of visible SQL dialect changes

### 5. Dockerfile Base Image Update
**Pattern**: FindAndReplace for base image
- `org.openrewrite.FindAndReplace` for openjdk:17-jre-slim → eclipse-temurin:17-jre-alpine

**Rationale**:
- No Dockerfile-aware semantic recipes found in OpenRewrite ecosystem
- Base image reference is simple string replacement
- Pattern is unique within Dockerfile

**Limitation**: Text-based, not Dockerfile LST-aware

**Coverage**: 100% of Dockerfile changes

## Gap Analysis

### Semantic Recipe Availability

| Transformation | Semantic Recipe | Used Recipe | Notes |
|----------------|----------------|-------------|-------|
| Gradle dependencies | ✅ Yes | AddDependency, RemoveDependency | Full LST support |
| YAML properties | ✅ Yes | ChangePropertyValue | Understands YAML structure |
| GitHub Actions | ✅ Yes | ChangeActionVersion | Workflow-aware |
| SQL syntax | ⚠️ Proprietary | FindAndReplace | sql.ConvertDataType requires Moderne license |
| Dockerfile | ❌ No | FindAndReplace | No Dockerfile LST recipes found |

### Coverage Gaps
None identified. All transformations from the PR are covered.

### Risk Areas

1. **Environment variable template syntax**: The `{{ GET_ENV_VAR:VAR_NAME }}` syntax appears application-specific. Recipe assumes this is the correct format.

2. **SQL completeness**: Only V1__Create_posts_table.sql visible in diff. If additional migrations exist with AUTO_INCREMENT, they will also be transformed (which is desired).

3. **Dockerfile text replacement**: Using FindAndReplace for Dockerfile changes is not semantic. If base image appears in comments or other contexts, it will also be replaced.

## Advantages of Option 2

1. **Simple composition**: Straightforward list of transformations
2. **High granularity**: Each change is explicit and auditable
3. **Standard recipes**: Uses well-established OpenRewrite recipes
4. **No custom code**: No need to write custom recipes
5. **Predictable**: Each step has clear, documented behavior

## Disadvantages of Option 2

1. **Verbose**: 11 separate recipe invocations
2. **Non-semantic fallbacks**: Uses FindAndReplace for SQL and Dockerfile (no better alternative available)
3. **No grouping**: Related changes (e.g., all YAML properties) not grouped conceptually
4. **Manual coordination**: User must ensure recipe order is correct

## Trade-offs vs Option 1

| Aspect | Option 2 | Expected Option 1 |
|--------|----------|-------------------|
| Complexity | Lower - standard recipes | Higher - likely custom recipes |
| Maintainability | Higher - uses stable APIs | Lower - custom code to maintain |
| Semantic understanding | Mixed - good for Gradle/YAML, limited for SQL/Docker | Likely better for SQL/Docker |
| Verbosity | More verbose (11 steps) | Likely more concise (fewer steps) |
| Flexibility | Less flexible - standard behavior | More flexible - custom logic possible |

## Manual Steps Required

**None for core migration**, but consider:

1. **Testing**: Verify application works with PostgreSQL after migration
2. **Environment variables**: Ensure DATABASE_USER, DATABASE_PASSWORD, DATABASE_URL are set in deployment environments
3. **SQL validation**: Review all SQL migration files for additional H2-specific syntax not visible in this PR
4. **Testcontainers setup**: May need additional test configuration to use Testcontainers

## Execution Notes

Run with OpenRewrite Gradle plugin:
```bash
./gradlew rewriteRun -Drewrite.activeRecipe=com.example.PR3Option2
```

Dependencies needed in build.gradle:
```groovy
dependencies {
    rewrite("org.openrewrite:rewrite-gradle")
    rewrite("org.openrewrite:rewrite-yaml")
    rewrite("org.openrewrite.recipe:rewrite-github-actions:latest.release")
}
```

## Conclusion

Option 2 provides a safe, explicit, and maintainable approach using standard OpenRewrite recipes. It prioritizes transparency and uses semantic recipes where available, falling back to text replacement only where no alternative exists (SQL, Dockerfile). Suitable for teams that prefer explicit, traceable transformations over custom recipe development.
