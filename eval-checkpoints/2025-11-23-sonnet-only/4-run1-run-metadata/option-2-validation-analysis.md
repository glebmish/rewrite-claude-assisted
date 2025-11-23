# Option 2 Recipe Validation Analysis

## Setup Summary

**Repository**: simple-blog-platform
**PR**: #3 (H2 to PostgreSQL migration)
**Recipe**: com.example.simpleblog.MigrateH2ToPostgreSQLTargeted
**Approach**: Targeted surgical recipe with 14 explicit recipe steps
**Java Version**: 17
**Execution Time**: 1m 51s

## Execution Results

**Status**: SUCCESS

The recipe executed successfully with the following changes reported:
- Modified: src/main/resources/config.yml (5 property changes)
- Modified: src/main/resources/db/migration/V1__Create_posts_table.sql (SQL syntax change)
- Modified: build.gradle (dependency removal)
- Modified: .github/workflows/ci.yml (GitHub Actions cache update)
- Modified: Dockerfile (base image update)

**Note**: Gradle reported "There were problems parsing helm/simple-blog-platform/templates/deployment.yaml" but this did not affect recipe execution.

## Coverage Analysis

### Complete Matches (5 files)
Files where recipe output exactly matches PR diff:
1. `.github/workflows/ci.yml` - Cache action upgrade v2→v4
2. `Dockerfile` - Base image change to eclipse-temurin:17-jre-alpine
3. `src/main/resources/db/migration/V1__Create_posts_table.sql` - AUTO_INCREMENT→BIGSERIAL conversion

### Partial Matches with Gaps (1 file)
**File**: `build.gradle`

**Covered**:
- H2 dependency removal
- Comment removal ("// H2 Database")

**Gaps**:
- Missing PostgreSQL dependency addition: `implementation 'org.postgresql:postgresql:42.6.0'`
- Missing comment addition: `// PostgreSQL`
- Missing 3 Testcontainers dependencies:
  - `testImplementation 'org.testcontainers:testcontainers:1.17.6'`
  - `testImplementation 'org.testcontainers:postgresql:1.17.6'`
  - `testImplementation 'org.testcontainers:junit-jupiter:1.17.6'`

**File**: `src/main/resources/config.yml`

**Covered**:
- All 5 property value changes correctly applied

**Minor Formatting Difference**:
- Recipe output: `user: {{ GET_ENV_VAR:DATABASE_USER }}` (no quotes)
- PR diff: `user: "{{ GET_ENV_VAR:DATABASE_USER }}"` (with quotes)
- Recipe output: `url: {{ GET_ENV_VAR:DATABASE_URL }}` (no quotes)
- PR diff: `url: "{{ GET_ENV_VAR:DATABASE_URL }}"` (with quotes)

This is a cosmetic difference in YAML formatting; both are functionally equivalent.

## Accuracy Assessment

### Precision
**100%** - No over-applications. All changes are required and match PR intent.

### Recall by Category

**Database Migration (Goal 1)**:
- Driver configuration: 100%
- Hibernate dialect: 100%
- Credentials: 100%
- Connection URL: 100%
- SQL schema: 100%
- Dependency removal: 100%
- **PostgreSQL dependency addition: 0%** (CRITICAL GAP)
- **Testcontainers dependencies: 0%** (CRITICAL GAP)
- Build comment: 50% (removed old, missing new)

**Infrastructure Updates (Goal 2)**:
- GitHub Actions cache: 100%
- Docker base image: 100%

**Overall Recall**: ~71% (10/14 changes complete)

## Identified Gaps

### Critical Gaps

1. **PostgreSQL Driver Dependency Missing**
   - Expected: `implementation 'org.postgresql:postgresql:42.6.0'`
   - Root Cause: `org.openrewrite.gradle.AddDependency` with `onlyIfUsing: org.h2.Driver` failed
   - The `onlyIfUsing` condition requires the Driver class to be present in the codebase, but it's only referenced in config.yml, not in Java code
   - This causes the recipe to skip adding PostgreSQL dependency

2. **Testcontainers Dependencies Missing**
   - Expected: 3 testcontainers dependencies
   - Root Cause: Same as above - `onlyIfUsing: org.h2.Driver` condition not satisfied
   - The H2 Driver is never directly imported in Java source files, only referenced via configuration

3. **Build Comment Incomplete**
   - Recipe removed "// H2 Database" but didn't add "// PostgreSQL"
   - Root Cause: Recipe only has FindAndReplace for removal, not addition
   - The recipe step at line 82-85 only replaces the comment, but the actual diff shows removal of old line + addition of new line with PostgreSQL dependency

### Minor Formatting Differences

**YAML Quote Inconsistency**
- Recipe produces unquoted template variables
- PR diff shows quoted template variables
- Impact: Cosmetic only, functionally equivalent in YAML

## Root Cause Analysis

The primary failure mode is the **`onlyIfUsing` precondition** in AddDependency recipes:

```yaml
- org.openrewrite.gradle.AddDependency:
    groupId: org.postgresql
    artifactId: postgresql
    version: 42.6.0
    onlyIfUsing: org.h2.Driver  # ← This fails
    configuration: implementation
```

**Why it fails**:
- `onlyIfUsing` searches for class usage in Java source code
- `org.h2.Driver` is only referenced in YAML config file, not in Java files
- The Dropwizard application loads the driver via configuration, not via direct Java imports
- OpenRewrite's AddDependency doesn't detect YAML-based driver references

## Recommendations

### Immediate Fix Required

**Remove `onlyIfUsing` precondition** from all AddDependency steps:

```yaml
# Instead of:
- org.openrewrite.gradle.AddDependency:
    groupId: org.postgresql
    artifactId: postgresql
    version: 42.6.0
    onlyIfUsing: org.h2.Driver  # Remove this
    configuration: implementation

# Use:
- org.openrewrite.gradle.AddDependency:
    groupId: org.postgresql
    artifactId: postgresql
    version: 42.6.0
    configuration: implementation
```

Apply this fix to:
1. PostgreSQL dependency (line 14-19)
2. All 3 Testcontainers dependencies (lines 22-39)

### Build Comment Fix

Replace the single FindAndReplace with a more comprehensive approach:

**Option A**: Use two separate operations:
```yaml
# Remove H2 section
- org.openrewrite.text.FindAndReplace:
    find: "    // H2 Database\n    implementation 'com.h2database:h2:2.1.214'\n    \n"
    replace: ""
    filePattern: "**/build.gradle"

# Add PostgreSQL section (after removal is complete)
- org.openrewrite.gradle.AddDependency:
    groupId: org.postgresql
    artifactId: postgresql
    version: 42.6.0
    configuration: implementation
```

**Option B**: Use single multi-line replacement:
```yaml
- org.openrewrite.text.FindAndReplace:
    find: "    // H2 Database\n    implementation 'com.h2database:h2:2.1.214'"
    replace: "    // PostgreSQL\n    implementation 'org.postgresql:postgresql:42.6.0'"
    filePattern: "**/build.gradle"
```

### YAML Formatting (Optional)

If exact quote matching is required:
```yaml
- org.openrewrite.yaml.ChangePropertyValue:
    propertyKey: database.user
    newValue: '"{{ GET_ENV_VAR:DATABASE_USER }}"'  # Include quotes in value
    oldValue: sa
    fileMatcher: "**/config.yml"
```

However, this is cosmetic and not functionally important.

## Summary

**Option 2 Recipe Performance**:
- Successfully executed: 10/14 recipe steps (71%)
- Critical failures: 4 dependency additions
- Root cause: Incorrect use of `onlyIfUsing` precondition
- Fix complexity: Simple - remove 4 precondition lines

**Strengths**:
- All configuration file changes successful
- All infrastructure changes successful
- No over-applications
- Clear, targeted recipe structure

**Weaknesses**:
- Dependency management failure due to precondition logic
- Recipe would leave build.gradle in broken state (missing PostgreSQL driver)
- Application would fail to start without manual intervention

**Recommendation**: Fix by removing `onlyIfUsing` preconditions, then re-validate.
