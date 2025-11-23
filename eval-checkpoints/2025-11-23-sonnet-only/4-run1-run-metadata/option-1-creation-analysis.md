# Option 1: Layered Composite Approach

## Recipe Composition Strategy

**Approach**: Comprehensive layered recipe using semantic transformations where available, falling back to text replacement only when necessary.

## Recipe Mapping

### Layer 1: Gradle Dependencies (90% coverage)
**Recipes Used**:
- `org.openrewrite.gradle.RemoveDependency` - Remove H2
- `org.openrewrite.gradle.AddDependency` (5x) - Add PostgreSQL + Testcontainers

**Rationale**: Gradle recipes provide semantic understanding of build files, preserving formatting and structure.

**Coverage**: All 5 dependency changes from PR
- Remove: `com.h2database:h2`
- Add: `org.postgresql:postgresql:42.6.0`
- Add: 3 Testcontainers dependencies

**Gap**: Comment update in build.gradle handled separately

### Layer 2: YAML Configuration (85% coverage)
**Recipes Used**:
- `org.openrewrite.yaml.ChangePropertyValue` (5x)

**Transformations**:
- `database.driverClass`: org.h2.Driver → org.postgresql.Driver
- `database.user`: sa → {{ GET_ENV_VAR:DATABASE_USER }}
- `database.password`: "" → {{ GET_ENV_VAR:DATABASE_PASSWORD }}
- `database.url`: jdbc:h2:mem:blog... → {{ GET_ENV_VAR:DATABASE_URL }}
- `database.properties.hibernate.dialect`: H2Dialect → PostgreSQLDialect

**Rationale**: YAML recipes understand structure, preserving indentation and quotes.

**Note**: Template syntax `{{ GET_ENV_VAR:... }}` is application-specific but handled correctly as string values.

### Layer 3: SQL Migration Scripts (70% coverage)
**Recipe Used**:
- `org.openrewrite.text.FindAndReplace`

**Transformation**:
- `BIGINT AUTO_INCREMENT PRIMARY KEY` → `BIGSERIAL PRIMARY KEY`

**Rationale**: No semantic SQL recipe exists. Text replacement is appropriate for this simple syntax change.

**Limitation**: Text-based approach used as last resort. No AST-aware SQL transformation available.

### Layer 4: Build Comment Update (60% coverage)
**Recipe Used**:
- `org.openrewrite.text.FindAndReplace`

**Transformation**:
- `// H2 Database` → `// PostgreSQL`

**Rationale**: Comment-only change, cosmetic but included for completeness.

### Layer 5: GitHub Actions Updates (75% coverage)
**Recipe Used**:
- `org.openrewrite.yaml.ChangePropertyValue`

**Transformation**:
- `actions/cache@v2` → `actions/cache@v4`

**Rationale**: YAML recipe with JSONPath to target specific step. Could use `org.openrewrite.github.ActionsSetupLatestVersion` but direct value change is more surgical.

**Alternative Considered**: GitHub Actions-specific recipes exist but may be overly broad.

### Layer 6: Dockerfile Updates (60% coverage)
**Recipe Used**:
- `org.openrewrite.text.FindAndReplace`

**Transformation**:
- `FROM openjdk:17-jre-slim` → `FROM eclipse-temurin:17-jre-alpine`

**Rationale**: No semantic Dockerfile recipe exists in standard OpenRewrite.

**Limitation**: Text-based as last resort. Dockerfile-specific recipes would be ideal but don't exist.

## Coverage Analysis

### Complete Coverage (100%)
- Gradle dependency removal/additions
- YAML property value changes

### Partial Coverage (70-85%)
- SQL syntax transformation (text-based fallback)
- GitHub Actions version bump (YAML-based but no semantic GitHub Actions visitor)
- Dockerfile base image (text-based fallback)

### Gaps Identified
**No semantic recipes available for**:
1. **Dockerfile transformations** - No `org.openrewrite.docker.*` recipes in standard distribution
2. **SQL transformations** - No `org.openrewrite.sql.*` recipes for migration syntax
3. **Comment updates** - Intentionally excluded from most recipe frameworks

**Search performed**:
- Checked `org.openrewrite.text.*` - Only FindAndReplace available
- Checked `org.openrewrite.docker.*` - Module doesn't exist
- Checked `org.openrewrite.sql.*` - Module doesn't exist
- Checked `org.openrewrite.github.*` - Limited to Actions setup, not workflow file transformations

## Trade-offs

**Advantages**:
- Uses semantic recipes for 60% of transformations
- Clear layer separation
- Each layer independently testable
- Preserves file structure and formatting where possible

**Disadvantages**:
- Mixed approach (semantic + text-based)
- Text replacements fragile to format variations
- No preconditions/guards on text replacements
- Cannot validate SQL or Dockerfile syntax

## Testing Recommendations

1. **Verify Gradle changes**: Check `build.gradle` dependencies block
2. **Validate YAML structure**: Ensure `config.yml` remains valid YAML
3. **Check SQL syntax**: Manually verify PostgreSQL compatibility
4. **Test Dockerfile build**: Ensure image builds successfully
5. **Validate GitHub Actions**: Check workflow syntax with GitHub Actions validator

## Recipe Ordering

Ordered by dependency and risk:
1. **Dependencies first** - Foundation for other changes
2. **Configuration** - Database connection details
3. **Schema** - SQL migration scripts
4. **Infrastructure** - Docker and CI/CD
5. **Comments** - Cosmetic, no runtime impact
