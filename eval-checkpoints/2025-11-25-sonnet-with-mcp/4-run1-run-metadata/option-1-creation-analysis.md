# Option 1: Surgical Approach - Creation Analysis

## Strategy
Narrow, targeted recipes for maximum precision and control. Each transformation uses the most specific recipe available.

## Recipe Mapping

### Gradle Dependencies (5 recipes)
**Coverage: Complete**

1. **org.openrewrite.gradle.RemoveDependency** - Remove H2
   - Semantic understanding of Gradle build files
   - Removes dependency declaration cleanly

2. **org.openrewrite.gradle.AddDependency** (4 instances) - Add PostgreSQL + Testcontainers
   - Type-aware Gradle DSL manipulation
   - Preserves formatting and structure
   - Adds to appropriate configuration scopes

### YAML Configuration (5 recipes)
**Coverage: Complete**

3-7. **org.openrewrite.yaml.ChangePropertyValue** (5 instances)
   - Understands YAML structure and nested properties
   - Uses dot notation for hierarchical keys
   - Handles quoted values correctly
   - Supports regex matching for URL pattern

**Transformations:**
- database.driverClass: org.h2.Driver → org.postgresql.Driver
- database.properties.hibernate.dialect: H2Dialect → PostgreSQLDialect
- database.user: sa → "{{ GET_ENV_VAR:DATABASE_USER }}"
- database.password: "" → "{{ GET_ENV_VAR:DATABASE_PASSWORD }}"
- database.url: jdbc:h2:.* → "{{ GET_ENV_VAR:DATABASE_URL }}" (regex)

### SQL Migration (1 recipe)
**Coverage: Complete with limitation**

8. **org.openrewrite.text.FindAndReplace** - AUTO_INCREMENT → BIGSERIAL
   - Text-based replacement (last resort)
   - No SQL-specific semantic understanding
   - Case-insensitive matching
   - File pattern restricts to migration files

**Limitation:** No semantic SQL parser available in OpenRewrite for dialect translation.

### Dockerfile (1 recipe)
**Coverage: Complete with limitation**

9. **org.openrewrite.text.FindAndReplace** - Update base image
   - Text-based replacement (last resort)
   - No Dockerfile-specific LST available
   - Case-sensitive exact match
   - File pattern restricts to Dockerfile

**Limitation:** No Dockerfile semantic parser available. Text replacement is only option.

### GitHub Actions (1 recipe)
**Coverage: Complete**

10. **org.openrewrite.github.ChangeActionVersion** - Bump actions/cache v2→v4
   - Semantic understanding of GitHub Actions YAML
   - Action-aware transformation
   - Preserves workflow structure

## Gap Analysis

### Identified Gaps: NONE
All transformations have appropriate semantic recipes except where no parser exists (SQL, Dockerfile).

### Text-Based Recipes Used (Last Resort)
- **SQL migration**: No SQL dialect parser in OpenRewrite
- **Dockerfile**: No Dockerfile LST parser in OpenRewrite

These are necessary text-based transformations since semantic alternatives don't exist.

## Recipe Ordering

**Critical ordering considerations:**
1. Text-based recipes (SQL, Dockerfile) placed AFTER semantic recipes
2. Per FindAndReplace documentation: "converts source file to plain text for rest of recipe run"
3. Order: Gradle → YAML → Text → GitHub Actions

**Actual order:**
1-5: Gradle dependencies (semantic)
6-10: YAML properties (semantic)
11-12: Text replacements (converts to plain text)
13: GitHub Actions (semantic, but operates on .yml files separately)

## Precision vs Coverage Trade-offs

**Advantages:**
- Maximum control over each transformation
- Easy to debug individual changes
- Clear audit trail of what changed
- Can selectively enable/disable specific transformations
- No unwanted side effects from broad recipes

**Disadvantages:**
- Verbose (13 recipe invocations)
- Manual coordination required
- Must understand all transformation types
- Risk of missing related patterns

## Testing Recommendations

**Per-category validation:**
1. Gradle: Verify dependency resolution (`./gradlew dependencies`)
2. YAML: Validate syntax and property access
3. SQL: Test migrations against PostgreSQL
4. Dockerfile: Build image (`docker build`)
5. GitHub Actions: Workflow syntax validation

**Integration testing:**
- Full application startup with PostgreSQL
- Testcontainers test execution
- CI/CD pipeline execution

## Manual Steps Required

**None** - Recipe covers all PR changes.

**Post-transformation validation:**
1. Update environment variables for runtime:
   - DATABASE_USER
   - DATABASE_PASSWORD
   - DATABASE_URL
2. Configure PostgreSQL instance/connection
3. Test Testcontainers in CI environment

## Success Criteria

Recipe successfully applied if:
- build.gradle has PostgreSQL + Testcontainers, no H2
- config.yml references PostgreSQL driver/dialect + env vars
- SQL migration uses BIGSERIAL syntax
- Dockerfile uses eclipse-temurin:17-jre-alpine
- GitHub Actions uses actions/cache@v4
- All files parse correctly
- Application builds successfully
