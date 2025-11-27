# Option 1: Comprehensive Java 21 Migration - Analysis

## Approach
Broad/comprehensive migration using `org.openrewrite.java.migrate.UpgradeToJava21` as foundation recipe.

## Recipe Composition

### 1. org.openrewrite.java.migrate.UpgradeToJava21
**Purpose**: Primary comprehensive Java 21 migration recipe

**What it covers**:
- Includes `org.openrewrite.java.migrate.UpgradeToJava17` (baseline migrations)
- Updates build files to Java 21 via `org.openrewrite.java.migrate.UpgradeBuildToJava21`
  - Wraps `org.openrewrite.java.migrate.UpgradeJavaVersion` with version=21
  - Handles `java.toolchain.languageVersion` in Gradle
  - Updates `sourceCompatibility`/`targetCompatibility` to toolchain approach
- Upgrades GitHub Actions via `org.openrewrite.github.SetupJavaUpgradeJavaVersion`
  - Updates `actions/setup-java` java-version to 21 in `.github/workflows/*.yml`
- Upgrades plugins via `org.openrewrite.java.migrate.UpgradePluginsForJava21`
- Applies Java 21 API migrations (deprecated APIs, pattern matching, etc.)

**Semantic transformations**:
- Gradle: Understands Gradle DSL structure, migrates from legacy sourceCompatibility to toolchain API
- YAML: Parses GitHub Actions workflow structure, updates java-version nodes semantically
- Java: Applies LST-based code transformations for language features

### 2. org.openrewrite.gradle.UpdateGradleWrapper
**Purpose**: Update Gradle wrapper from 8.1 to 8.5

**Configuration**:
- version: 8.5
- distribution: bin

**What it covers**:
- Updates `gradle/wrapper/gradle-wrapper.properties`
- Modifies `distributionUrl` to point to gradle-8.5-bin.zip
- Adds SHA-256 checksum for distribution verification

**Semantic transformation**: Understands properties file structure, updates specific keys

## Coverage Analysis

### Fully Covered (3/5)
1. **GitHub Actions CI** (.github/workflows/ci.yml)
   - Recipe: `org.openrewrite.github.SetupJavaUpgradeJavaVersion` (via UpgradeToJava21)
   - Change: java-version: '17' → '21'
   - Status: AUTOMATED

2. **Gradle Build** (build.gradle)
   - Recipe: `org.openrewrite.java.migrate.UpgradeJavaVersion` (via UpgradeBuildToJava21)
   - Changes:
     - sourceCompatibility = '17' → removed (replaced by toolchain)
     - targetCompatibility = '17' → removed (replaced by toolchain)
     - Adds: `java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }`
   - Status: AUTOMATED

3. **Gradle Wrapper** (gradle/wrapper/gradle-wrapper.properties)
   - Recipe: `org.openrewrite.gradle.UpdateGradleWrapper`
   - Change: gradle-8.1-bin.zip → gradle-8.5-bin.zip
   - Status: AUTOMATED

### Gaps Identified (2/5)

4. **Dockerfile**
   - Current:
     - Line 2: `FROM eclipse-temurin:17-jdk-alpine`
     - Line 18: `FROM eclipse-temurin:17-jre-alpine`
   - Required: Update to `:21-jdk-alpine` and `:21-jre-alpine`
   - Gap Reason: No semantic Dockerfile recipe exists in OpenRewrite ecosystem
   - Workaround Options:
     - Manual update
     - Custom visitor extending `org.openrewrite.docker.DockerVisitor`
     - Text-based recipe (last resort, non-semantic)

5. **README.md**
   - Current:
     - Line 17: "Java 17"
     - Line 143: "Java 17"
   - Required: Update to "Java 21"
   - Gap Reason: Documentation updates require text replacement in markdown
   - Workaround Options:
     - Manual update (preferred for docs)
     - Text-based recipe (non-semantic)

## Recipe Ordering

1. `UpgradeToJava21` runs first - handles core Java/build/CI changes
2. `UpdateGradleWrapper` runs second - updates build infrastructure

No ordering conflicts. Both recipes operate on different file types.

## Trade-offs

### Advantages
- **Comprehensive**: Single recipe handles multiple aspects (build, CI, APIs, plugins)
- **Simple**: Only 2 recipes needed
- **Well-tested**: Widely used in OpenRewrite community
- **Future-proof**: Includes modern Java 21 features adoption
- **Authoritative**: Official OpenRewrite migration path

### Disadvantages
- **Less control**: Cannot exclude specific sub-transformations
- **All-or-nothing**: Gets all Java 21 migrations bundled together
- **Gaps remain**: Dockerfile and README require separate handling

## Gap Resolution Recommendations

### Dockerfile (Lines 2, 18)
**Recommended approach**: Manual update
- Simple find-replace: `eclipse-temurin:17` → `eclipse-temurin:21`
- Only 2 occurrences
- Manual verification ensures correctness

**Alternative**: Custom recipe
```yaml
# Would require implementing custom visitor
- com.custom.UpdateDockerfileJavaVersion:
    fromVersion: 17
    toVersion: 21
    baseImage: eclipse-temurin
```

### README.md (Lines 17, 143)
**Recommended approach**: Manual update
- Documentation requires human review for context
- Only 2 occurrences
- Ensures other Java 17 references are contextually appropriate

**Alternative**: Text recipe (non-semantic, last resort)
```yaml
- org.openrewrite.text.FindAndReplace:
    find: "Java 17"
    replace: "Java 21"
    filePattern: "README.md"
```

## Testing Recommendations
1. Run recipe on copy of repository
2. Verify Gradle build succeeds with Java 21
3. Verify GitHub Actions workflow syntax
4. Manual testing:
   - Dockerfile builds successfully
   - Application runs in container
   - Documentation reflects changes
5. Review toolchain configuration in build.gradle

## Migration Phasing
Option 1 is suitable for:
- Full migration in single PR
- Teams ready to adopt Java 21 completely
- Projects with CI/CD validating changes
- When comprehensive coverage preferred over granular control
