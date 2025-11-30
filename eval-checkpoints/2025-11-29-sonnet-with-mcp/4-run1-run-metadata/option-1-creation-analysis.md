# Option 1 Recipe Analysis: Semantic + Text Fallbacks

## Approach
Maximize use of semantic OpenRewrite recipes for type-aware transformations, supplementing with text-based replacements only where semantic recipes don't exist.

## Recipe Coverage Mapping

### 1. GitHub Actions - actions/cache v2 → v4
**Recipe**: `org.openrewrite.github.ChangeActionVersion`
- **Coverage**: Complete
- **Type**: Semantic (YAML-aware)
- **Rationale**: Understands GitHub Actions workflow structure, updates version while preserving YAML formatting

### 2. Dockerfile - openjdk:17-jre-slim → eclipse-temurin:17-jre-alpine
**Recipe**: `org.openrewrite.text.FindAndReplace`
- **Coverage**: Complete
- **Type**: Text-based fallback
- **Rationale**: No semantic Dockerfile recipe found for base image replacement. Text replacement is appropriate here as it's a simple string substitution in a single location.
- **Gap**: No `org.openrewrite.docker.ChangeBaseImage` or similar semantic recipe exists

### 3. Gradle Dependencies
**Recipes**:
- `org.openrewrite.gradle.RemoveDependency` (Remove H2)
- `org.openrewrite.gradle.AddDependency` (Add PostgreSQL + 3x Testcontainers)

- **Coverage**: Complete
- **Type**: Semantic (Gradle DSL-aware)
- **Rationale**: These recipes understand Gradle build file structure, handle various dependency declaration syntaxes (string notation vs map notation), and place dependencies in correct configuration blocks

### 4. YAML Configuration (config.yml)
**Recipe**: `org.openrewrite.yaml.ChangePropertyValue` (5 instances)
- **Coverage**: Complete
- **Type**: Semantic (YAML-aware)
- **Rationale**: Uses dot notation for nested properties, preserves YAML structure and formatting
- **Changes**:
  - `database.driverClass`: org.h2.Driver → org.postgresql.Driver
  - `database.user`: sa → {{ GET_ENV_VAR:DATABASE_USER }}
  - `database.password`: "" → {{ GET_ENV_VAR:DATABASE_PASSWORD }}
  - `database.url`: jdbc:h2:... → {{ GET_ENV_VAR:DATABASE_URL }}
  - `database.properties.hibernate.dialect`: H2Dialect → PostgreSQLDialect

### 5. SQL Migration - AUTO_INCREMENT → BIGSERIAL
**Recipe**: `org.openrewrite.text.FindAndReplace`
- **Coverage**: Complete
- **Type**: Text-based fallback
- **Rationale**: No H2-to-PostgreSQL SQL migration recipe found. While `org.openrewrite.sql.ConvertDataType` exists, it doesn't specifically handle H2's `BIGINT AUTO_INCREMENT` to PostgreSQL's `BIGSERIAL` conversion pattern
- **Gap**: Generic SQL conversion recipes don't cover this specific H2→PostgreSQL syntax transformation

## Gap Analysis

### Covered by Semantic Recipes (80%)
- GitHub Actions workflow modifications
- Gradle dependency management (removal + addition)
- YAML configuration property updates

### Covered by Text Fallbacks (20%)
- Dockerfile base image replacement
- SQL migration syntax conversion

### True Gaps (None for this migration)
All required transformations have appropriate recipes, though 2 out of 7 file types require text-based approaches.

## Alternative Recipes Considered

### For SQL Migration
- `org.openrewrite.sql.ConvertDataType`: Too generic, requires exact type mappings
- `org.openrewrite.sql.MigrateOracleToPostgres`: Oracle-specific, doesn't cover H2
- Custom recipe: Would require parsing SQL DDL and understanding auto-increment semantics

### For Dockerfile
- No semantic alternatives exist in OpenRewrite ecosystem
- Text replacement is standard approach for Dockerfiles

## Recipe Ordering

1. **GitHub Actions** (independent)
2. **Dockerfile** (independent)
3. **Gradle dependencies** (independent)
4. **YAML config** (independent)
5. **SQL migration** (must be last to avoid LST conversion)

**CRITICAL**: `org.openrewrite.text.FindAndReplace` converts files to plain text, making them unavailable for subsequent semantic processing. SQL files are already plain text, so ordering doesn't affect them. Dockerfile text replacement is also safe as Dockerfiles aren't parsed as LST.

## Strengths
- Maximizes semantic understanding (GitHub Actions YAML, Gradle DSL, config YAML)
- Precise targeting with file patterns
- Preserves formatting and structure
- Type-safe dependency management

## Limitations
- Text replacement for Dockerfile is brittle (exact string match required)
- SQL transformation doesn't validate syntax correctness
- No validation that PostgreSQL dependency is compatible with Dropwizard version
- Environment variable template syntax `{{ GET_ENV_VAR:... }}` assumed but not validated

## Testing Recommendations
- Verify Gradle dependency resolution completes successfully
- Confirm config.yml environment variable substitution works with Dropwizard
- Test PostgreSQL connection with actual database
- Validate SQL migration runs successfully with Flyway/Liquibase
- Confirm GitHub Actions workflow runs without errors
- Verify Docker image builds and runs
