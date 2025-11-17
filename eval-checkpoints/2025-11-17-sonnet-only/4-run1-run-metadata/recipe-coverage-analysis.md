# Recipe Coverage Analysis for PR #3

**Date**: 2025-11-16
**Session ID**: a0288115-2a67-4c55-b32e-dd2fd2f7a2b6
**Phase**: 3 - Recipe Mapping

## Transformation Intents vs Available Recipes

### Intent 1: Replace H2 dependency with PostgreSQL in build.gradle

**Required Changes**:
- Remove: `implementation 'com.h2database:h2:2.1.214'`
- Add: `implementation 'org.postgresql:postgresql:42.6.0'`

**Available Recipes**:
1. `org.openrewrite.gradle.RemoveDependency` - ✓ Can remove H2
   - Parameters: `groupId: com.h2database`, `artifactId: h2`
   - Coverage: COMPLETE for removal

2. `org.openrewrite.gradle.AddDependency` - ✓ Can add PostgreSQL
   - Parameters: `groupId: org.postgresql`, `artifactId: postgresql`, `version: 42.6.0`, `configuration: implementation`
   - Coverage: COMPLETE for addition

**Assessment**: COMPLETE coverage with 2 semantic recipes

---

### Intent 2: Add Testcontainers dependencies to build.gradle

**Required Changes**:
- Add: `testImplementation 'org.testcontainers:testcontainers:1.17.6'`
- Add: `testImplementation 'org.testcontainers:postgresql:1.17.6'`
- Add: `testImplementation 'org.testcontainers:junit-jupiter:1.17.6'`

**Available Recipes**:
1. `org.openrewrite.gradle.AddDependency` (3 instances) - ✓ Can add all three
   - Coverage: COMPLETE for all three dependencies

**Assessment**: COMPLETE coverage with 3 semantic recipes

---

### Intent 3: Update database configuration in config.yml

**Required Changes**:
- `driverClass: org.h2.Driver` → `driverClass: org.postgresql.Driver`
- `user: sa` → `user: "{{ GET_ENV_VAR:DATABASE_USER }}"`
- `password: ""` → `password: "{{ GET_ENV_VAR:DATABASE_PASSWORD }}"`
- `url: jdbc:h2:mem:blog;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE` → `url: "{{ GET_ENV_VAR:DATABASE_URL }}"`
- `hibernate.dialect: org.hibernate.dialect.H2Dialect` → `hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect`

**Available Recipes**:
1. `org.openrewrite.yaml.ChangePropertyValue` - ✓ Can change property values
   - Coverage: COMPLETE for structured property changes
   - Parameters: `propertyKey`, `newValue`
   - Need 5 instances for each property change

**Why Semantic Recipe is Appropriate**:
- YAML has a structured syntax (key-value pairs, nesting)
- OpenRewrite's YAML LST parser understands this structure
- `ChangePropertyValue` navigates the YAML tree semantically using dot notation
- Preserves YAML formatting and structure
- Handles nested properties correctly

**Assessment**: COMPLETE coverage with 5 semantic YAML recipes

---

### Intent 4: Update SQL migration script syntax (V1__Create_posts_table.sql)

**Required Changes**:
- `id BIGINT AUTO_INCREMENT PRIMARY KEY` → `id BIGSERIAL PRIMARY KEY`

**Available Recipes**:
1. `org.openrewrite.text.FindAndReplace` - ✓ Can perform text replacement
   - Parameters: `find: "BIGINT AUTO_INCREMENT"`, `replace: "BIGSERIAL"`, `filePattern: "**/V*__*.sql"`
   - Coverage: COMPLETE for SQL syntax change

**Why Text-Based Recipe is Appropriate**:
- SQL files are NOT parsed into LST by OpenRewrite (no SQL parser in core)
- Text-based approach is the ONLY option for SQL transformations
- This is a legitimate use case for `FindAndReplace` since SQL is treated as plain text
- No semantic SQL recipes exist in OpenRewrite catalog
- Safe to use text recipe because SQL files won't be followed by LST-based recipes on same files

**Assessment**: COMPLETE coverage with text-based recipe (legitimate use case)

---

### Intent 5: Upgrade GitHub Actions cache action

**Required Changes**:
- `uses: actions/cache@v2` → `uses: actions/cache@v4`

**Available Recipes**:
1. `org.openrewrite.github.ChangeActionVersion` - ✓ Can update action version
   - Parameters: `action: actions/cache`, `version: v4`
   - Coverage: COMPLETE for GitHub Actions updates

**Why Semantic Recipe is Appropriate**:
- GitHub Actions workflow files (.yml) have structured syntax
- OpenRewrite has a dedicated GitHub Actions parser/LST
- `ChangeActionVersion` understands workflow structure (steps, uses, with, etc.)
- Semantic understanding of action references
- Preserves workflow formatting and structure

**Assessment**: COMPLETE coverage with 1 semantic recipe

---

### Intent 6: Modernize Docker base image

**Required Changes**:
- `FROM openjdk:17-jre-slim` → `FROM eclipse-temurin:17-jre-alpine`

**Available Recipes**:
1. `org.openrewrite.text.FindAndReplace` - ✓ Can replace base image
   - Parameters: `find: "FROM openjdk:17-jre-slim"`, `replace: "FROM eclipse-temurin:17-jre-alpine"`, `filePattern: "Dockerfile"`
   - Coverage: COMPLETE for Dockerfile changes

**Why Text-Based Recipe is Appropriate**:
- Dockerfiles are NOT parsed into LST by OpenRewrite (no Dockerfile parser in core)
- Text-based approach is the ONLY option for Dockerfile transformations
- This is a legitimate use case for `FindAndReplace` since Dockerfiles are treated as plain text
- No semantic Dockerfile recipes exist in OpenRewrite catalog
- Safe to use text recipe because Dockerfiles won't be followed by LST-based recipes

**Assessment**: COMPLETE coverage with text-based recipe (legitimate use case)

---

## Recipe Coverage Summary

| Intent Category | Coverage Level | Recipe Type | Count |
|----------------|---------------|-------------|-------|
| Gradle dependencies (remove H2) | COMPLETE | Semantic (LST) | 1 |
| Gradle dependencies (add PostgreSQL) | COMPLETE | Semantic (LST) | 1 |
| Gradle dependencies (add Testcontainers) | COMPLETE | Semantic (LST) | 3 |
| YAML configuration changes | COMPLETE | Semantic (LST) | 5 |
| SQL syntax migration | COMPLETE | Text-based | 1 |
| GitHub Actions upgrade | COMPLETE | Semantic (LST) | 1 |
| Dockerfile base image | COMPLETE | Text-based | 1 |

**Total Recipes Required**: 13

**Semantic (LST-based)**: 11 recipes (85%)
**Text-based**: 2 recipes (15%)

---

## Rationale for Text-Based Recipes

**Only 2 out of 13 transformations require text-based recipes**, and both are **legitimate use cases**:

1. **SQL Files**: OpenRewrite does not have a SQL parser. SQL files cannot be converted to LST. Text-based transformation is the ONLY option.

2. **Dockerfiles**: OpenRewrite does not have a Dockerfile parser. Dockerfiles cannot be converted to LST. Text-based transformation is the ONLY option.

**Important Note**: According to OpenRewrite documentation, text-based recipes should be placed LAST in the recipe list when combined with LST-based recipes, because they convert files to plain text. However, in our case:
- SQL files are never parsed as LST (no parser exists)
- Dockerfiles are never parsed as LST (no parser exists)
- Therefore, ordering doesn't matter for these files

---

## Coverage Gaps Identified

**NO GAPS** - All transformation intents can be covered by existing OpenRewrite recipes.

---

## Recipe Ordering Considerations

**Recommended Execution Order**:
1. Gradle dependency changes (LST-based, affects build files)
2. YAML configuration changes (LST-based, affects config files)
3. GitHub Actions updates (LST-based, affects workflow files)
4. SQL syntax changes (text-based, but operates on separate file type)
5. Dockerfile changes (text-based, but operates on separate file type)

**Rationale for Ordering**:
- Group all LST-based recipes together
- SQL and Dockerfile text recipes operate on different files, so can be in any order
- No interdependencies between recipes (each operates on different files)

---

## Recipe Composition Strategy

I will create **2 recipe options** as required:

### Option 1: Narrow Targeted Recipes (Granular Control)
- Individual recipe for each specific transformation
- Maximum transparency and control
- 13 individual recipes in composition
- Best for: Understanding exactly what changes, incremental rollout, selective application
- Trade-off: More verbose configuration

### Option 2: Simplified Grouped Recipes (Reduced Verbosity)
- Group related transformations where possible
- Still maintains semantic approach where available
- Fewer recipe entries through parameterization
- Best for: Cleaner configuration, easier maintenance
- Trade-off: Slightly less granular control

**Note**: I initially considered a "broad approach" option using composite recipes like database migration suites, but my research confirms that OpenRewrite does NOT provide high-level composite recipes for database migrations (H2 → PostgreSQL). The available recipes are all low-level transformation primitives. Therefore, both options will use narrow, targeted recipes - the difference is in grouping and presentation.
