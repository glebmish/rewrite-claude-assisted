# Option 1: Broad Migration Recipe Analysis

## Recipe Selection Strategy

**Approach**: Use comprehensive, ecosystem-wide migration recipes that handle entire transformation domains.

## Selected Recipes

### 1. org.openrewrite.java.migrate.UpgradeToJava17
**Purpose**: Comprehensive Java 11 → Java 17 migration
**Covers**:
- Java language feature adoption (var, text blocks, switch expressions where applicable)
- Deprecated API migrations
- JVM compatibility changes
- Library version updates compatible with Java 17

**Why chosen**: Single recipe handles the entire Java version upgrade, including:
- API modernization
- Deprecated method replacements
- Type inference improvements
- Standard library changes

### 2. org.openrewrite.java.testing.junit5.JUnit4to5Migration
**Purpose**: Complete JUnit 4 → JUnit 5 migration
**Covers**:
- Import statement updates (org.junit.* → org.junit.jupiter.api.*)
- Annotation migrations (@Before → @BeforeEach, @Test compatibility)
- Assertion API changes (Assert.* → Assertions.*)
- Test lifecycle method updates
- Parameterized test migrations
- Rule to Extension migrations

**Why chosen**: This is the canonical broad recipe for JUnit migrations. It handles:
- All annotation changes systematically
- Import reorganization
- Static import conversions
- Test configuration updates

### 3. org.openrewrite.gradle.UpdateGradleWrapper
**Purpose**: Update Gradle wrapper version
**Covers**:
- gradle-wrapper.properties modification
- Distribution URL update
- Version-specific compatibility

**Parameters**:
- version: 7.6.4 (target version from PR)
- distribution: bin (standard distribution type)

**Why chosen**: Direct, semantic recipe for Gradle wrapper upgrades.

### 4. org.openrewrite.gradle.plugins.UpgradePluginVersion
**Purpose**: Upgrade Shadow plugin to version compatible with Gradle 7.6.4
**Covers**:
- Plugin version update in build.gradle
- Compatibility verification

**Parameters**:
- pluginIdPattern: com.github.johnrengelman.shadow
- newVersion: 7.1.2

**Why chosen**: Type-aware Gradle plugin version upgrade.

### 5. org.openrewrite.java.migrate.gradle.UpdateJavaCompatibilityToToolchain
**Purpose**: Migrate from sourceCompatibility/targetCompatibility to toolchain API
**Covers**:
- Removal of sourceCompatibility/targetCompatibility
- Addition of java.toolchain block
- Modern Gradle Java configuration

**Parameters**:
- javaVersion: 17

**Why chosen**: This is the modern Gradle approach for Java version management, preferred over legacy compatibility settings.

### 6-7. org.openrewrite.gradle.UpdateJavaCompatibility (source & target)
**Purpose**: Fallback/complementary recipe for Java version updates
**Covers**:
- sourceCompatibility update to 17
- targetCompatibility update to 17

**Why chosen**: Ensures Java version is updated even if toolchain migration doesn't fully apply.

### 8. org.openrewrite.github.SetupJavaUpgradeJavaVersion
**Purpose**: Update GitHub Actions workflow Java version
**Covers**:
- setup-java action version parameter update
- Job name updates (if applicable)
- JDK version references in CI

**Parameters**:
- javaVersion: 17

**Why chosen**: Semantic YAML understanding of GitHub Actions structure, not text-based replacement.

## Coverage Assessment

### Intent Coverage Matrix

| Intent | Recipe Coverage | Status |
|--------|----------------|--------|
| Java 11 → 17 upgrade (build.gradle) | UpgradeToJava17 + UpdateJavaCompatibilityToToolchain | ✓ Complete |
| Java toolchain migration | UpdateJavaCompatibilityToToolchain | ✓ Complete |
| Gradle 6.9 → 7.6.4 wrapper | UpdateGradleWrapper | ✓ Complete |
| JUnit 4 → 5 dependencies | JUnit4to5Migration | ✓ Complete |
| JUnit 4 → 5 annotations | JUnit4to5Migration | ✓ Complete |
| JUnit 4 → 5 imports | JUnit4to5Migration | ✓ Complete |
| JUnit 4 → 5 assertions | JUnit4to5Migration | ✓ Complete |
| Test runner (useJUnit → useJUnitPlatform) | JUnit4to5Migration | ✓ Complete |
| Shadow plugin upgrade | UpgradePluginVersion | ✓ Complete |
| GitHub Actions Java 17 | SetupJavaUpgradeJavaVersion | ✓ Complete |
| mainClassName → mainClass | - | ✗ Gap |

### Identified Gaps

**Gap 1: Deprecated Gradle property replacement (mainClassName → mainClass)**
- **Missing transformation**: Replace deprecated `mainClassName` with `mainClass` in application block
- **Why no recipe**: This is a Gradle DSL-specific deprecation that may require custom recipe
- **Impact**: Medium - build will work but with deprecation warnings
- **Workaround**: May need manual fix or custom recipe using `org.openrewrite.gradle.ChangeDependency` pattern

**Gap 2: Shadow plugin mainClassName backward compatibility**
- **Missing transformation**: PR adds `mainClassName = 'com.example.usermanagement.UserManagementApplication'` to shadowJar block
- **Why no recipe**: This is project-specific backward compatibility workaround
- **Impact**: Low - likely handled by Shadow plugin upgrade recipe or not needed
- **Workaround**: Manual verification after migration

## Recipe Ordering Rationale

1. **Java migration first**: UpgradeToJava17 handles language-level changes
2. **Test framework second**: JUnit4to5Migration updates test code to match new Java version
3. **Gradle wrapper third**: UpdateGradleWrapper ensures build tool compatibility
4. **Plugin upgrades fourth**: UpgradePluginVersion updates plugins for Gradle 7.6.4
5. **Toolchain migration fifth**: UpdateJavaCompatibilityToToolchain modernizes Java config
6. **Compatibility updates sixth**: UpdateJavaCompatibility as fallback
7. **CI update last**: SetupJavaUpgradeJavaVersion aligns CI with local build

## Expected Transformations

### build.gradle
- JUnit 4 dependency replaced with JUnit 5 jupiter-api and jupiter-engine
- Shadow plugin version 6.1.0 → 7.1.2
- sourceCompatibility/targetCompatibility removed
- java.toolchain block added with languageVersion 17
- test block: useJUnit() → useJUnitPlatform()

### gradle/wrapper/gradle-wrapper.properties
- distributionUrl: gradle-6.9-bin.zip → gradle-7.6.4-bin.zip

### .github/workflows/ci.yml
- setup-java action: java-version '11' → '17'
- Job name: "Set up JDK 11" → "Set up JDK 17"

### Test Files (*.java)
- Imports: org.junit.Before → org.junit.jupiter.api.BeforeEach
- Imports: org.junit.Test → org.junit.jupiter.api.Test
- Imports: org.junit.Assert.* → org.junit.jupiter.api.Assertions.*
- Annotations: @Before → @BeforeEach
- Methods: Assert.assertEquals() → Assertions.assertEquals()

## Limitations

1. **mainClassName deprecation**: Not covered by broad recipes, may require manual fix
2. **Project-specific configurations**: Shadow plugin backward compatibility may need verification
3. **Single test file scope**: Recipe will process all test files, but project only has one
4. **Dependency version alignment**: JUnit 5 version (5.8.1 in PR) may differ from recipe defaults

## Testing Recommendations

1. **Build verification**: Run `./gradlew clean build` after migration
2. **Test execution**: Verify all tests pass with `./gradlew test`
3. **Shadow JAR**: Verify fat JAR builds correctly with `./gradlew shadowJar`
4. **CI validation**: Run GitHub Actions workflow to confirm Java 17 compatibility
5. **Deprecation check**: Review build output for remaining deprecation warnings

## Advantages of Broad Approach

- **Comprehensive**: Handles entire migration domains systematically
- **Battle-tested**: Uses well-maintained, widely-adopted recipes
- **Future-proof**: Includes best practices and modern patterns
- **Less maintenance**: Fewer recipes to manage and compose
- **Consistency**: Uniform transformation patterns across codebase

## Trade-offs

- **Less granular control**: Cannot exclude specific sub-transformations easily
- **Potential over-transformation**: May apply changes beyond PR scope
- **Version flexibility**: Recipe defaults may differ from PR's specific versions
- **Gap handling**: Broad recipes may miss project-specific edge cases
