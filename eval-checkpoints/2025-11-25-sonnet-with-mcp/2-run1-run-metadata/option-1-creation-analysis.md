# Option 1: Broad Migration Recipe - Creation Analysis

## Strategy Overview
Option 1 uses **broad, comprehensive migration recipes** that provide extensive automatic coverage. This approach favors high-level recipes that bundle multiple related transformations together.

## Recipe Selection Rationale

### 1. `org.openrewrite.java.migrate.UpgradeToJava17`
**Intent Coverage**: Java 11 → 17 upgrade

**Why Selected**:
- Comprehensive recipe that handles full Java version migration path (8→11→17)
- Automatically includes `Java8toJava11` and `UpgradeBuildToJava17` sub-recipes
- Updates build files (both Maven and Gradle) for Java 17
- Adopts modern Java 17 features (pattern matching, text blocks, etc.)
- Upgrades plugins to Java 17 compatible versions
- Migrates deprecated APIs with clear replacement strategies

**What It Covers**:
- Build configuration: sourceCompatibility/targetCompatibility OR java toolchain
- Plugin version upgrades
- Deprecated API replacements
- Modern language feature adoption
- Dependency updates for Java 17 compatibility

**Expected PR Coverage**:
- ✅ Java version change in build.gradle (toolchain configuration)
- ✅ Gradle plugin upgrades where needed
- ⚠️ May not handle Gradle-specific property renames (mainClassName→mainClass)

### 2. `org.openrewrite.java.testing.junit5.JUnit4to5Migration`
**Intent Coverage**: JUnit 4 → JUnit 5 migration

**Why Selected**:
- Most comprehensive JUnit migration recipe available
- Handles 50+ sub-transformations automatically
- Covers annotations, imports, assertions, and build configuration

**What It Covers**:
- ✅ `@Before` → `@BeforeEach` annotation changes
- ✅ `@Test` annotation package changes
- ✅ `org.junit.Assert.*` → `org.junit.jupiter.api.Assertions.*` imports
- ✅ JUnit 4 dependency removal and JUnit 5 dependency addition
- ✅ Gradle test configuration: `useJUnit()` → `useJUnitPlatform()`
- Additional coverage: @After, @BeforeClass, @AfterClass, ExpectedException, etc.

**Expected PR Coverage**:
- ✅ All test annotation migrations in UserResourceTest.java
- ✅ Import statement updates
- ✅ Test dependencies in build.gradle
- ✅ Test execution configuration change

### 3. `org.openrewrite.gradle.UpdateGradleWrapper`
**Intent Coverage**: Gradle 6.9 → 7.6.4 upgrade

**Configuration**: `version: 7.6.4, distribution: bin`

**Why Selected**:
- Targeted recipe specifically for Gradle wrapper version updates
- Automatically updates gradle-wrapper.properties distributionUrl
- Adds SHA-256 checksum for security

**Expected PR Coverage**:
- ✅ gradle/wrapper/gradle-wrapper.properties version change
- ⚠️ Does NOT handle Gradle 7 compatibility changes (handled by Java 17 recipe)

### 4. `org.openrewrite.gradle.plugins.UpgradePluginVersion`
**Intent Coverage**: Shadow plugin 6.1.0 → 7.1.2 upgrade

**Configuration**: `pluginIdPattern: com.github.johnrengelman.shadow, newVersion: 7.1.2`

**Why Selected**:
- Specific recipe for Gradle plugin version upgrades
- Updates plugin declaration in build.gradle

**Expected PR Coverage**:
- ✅ Shadow plugin version update in build.gradle
- ⚠️ Does NOT handle Shadow plugin 7.x configuration changes (mainClassName issue)

### 5. `org.openrewrite.github.SetupJavaUpgradeJavaVersion`
**Intent Coverage**: GitHub Actions Java version 11 → 17

**Configuration**: `minimumJavaMajorVersion: 17`

**Why Selected**:
- Semantic YAML-aware recipe for GitHub Actions workflows
- Updates `actions/setup-java` java-version parameter
- Can update step names that reference Java version

**Expected PR Coverage**:
- ✅ java-version parameter change in .github/workflows/ci.yml
- ⚠️ May not update step name "Set up JDK 11" → "Set up JDK 17"

### 6. Code Cleanup Phase
**Recipes**: `OrderImports`, `RemoveUnusedImports`, `AutoFormat`

**Why Included**:
- Post-migration cleanup to maintain code quality
- Removes artifacts from transformation process
- Ensures consistent formatting

## Coverage Analysis

### ✅ Fully Covered Intents

1. **Java Version Upgrade**
   - Java 11 → 17 in build configuration
   - Plugin compatibility updates
   - API migrations

2. **JUnit 4 → 5 Migration**
   - All annotation changes
   - Import statement updates
   - Assertion method changes
   - Test dependencies
   - Gradle test configuration

3. **Gradle Wrapper Upgrade**
   - Version update in gradle-wrapper.properties

4. **Shadow Plugin Version**
   - Plugin version update

5. **GitHub Actions Java Version**
   - java-version parameter update

### ⚠️ Partially Covered / Gap Areas

1. **Gradle Toolchain Configuration**
   - Gap: `UpgradeToJava17` typically uses sourceCompatibility/targetCompatibility
   - PR shows: Modern toolchain configuration with `java.toolchain.languageVersion`
   - Impact: Recipe may not produce exact match, but result is semantically equivalent

2. **Shadow Plugin Configuration Changes**
   - Gap: `mainClassName` → `mainClass` property rename in application block
   - Gap: Addition of `mainClassName` to shadowJar block
   - Reason: These are Shadow plugin 7.x-specific configuration changes
   - Mitigation: Not covered by existing recipes, may require manual adjustment

3. **GitHub Actions Step Name**
   - Gap: Step name "Set up JDK 11" → "Set up JDK 17"
   - Impact: Cosmetic only, does not affect functionality

## Advantages of Broad Approach

1. **Comprehensive Coverage**: Single recipes handle multiple related transformations
2. **Simplicity**: Fewer recipes to configure and maintain
3. **Tested Combinations**: Broad recipes are battle-tested on many codebases
4. **Future-Proof**: Includes best practices and modern patterns
5. **Low Maintenance**: Less likely to miss related changes

## Limitations

1. **Less Precision**: May make additional changes beyond PR scope
2. **Configuration Gaps**: Gradle-specific property renames not covered
3. **All-or-Nothing**: Cannot exclude specific sub-transformations easily
4. **Less Control**: Cannot fine-tune individual transformation aspects

## Expected Behavior

### Changes Matching PR
- Java 17 in build configuration
- JUnit 5 annotations and imports
- JUnit 5 dependencies
- useJUnitPlatform() test configuration
- Gradle wrapper 7.6.4
- Shadow plugin 7.1.2
- GitHub Actions Java 17

### Additional Changes (Beyond PR Scope)
- Modern Java features adoption (text blocks, pattern matching where applicable)
- Additional deprecated API replacements
- Import organization
- Code formatting standardization
- Checksum addition to gradle-wrapper.properties

### Likely Manual Adjustments Needed
1. Gradle application block: `mainClassName` → `mainClass` property rename
2. Shadow plugin: `mainClassName` addition to shadowJar block
3. GitHub Actions: Step name update (optional, cosmetic)

## Risk Assessment

**Risk Level**: Low-Medium

**Risks**:
- Broad recipes may introduce changes developers didn't intend
- Modern Java feature adoption might change code style
- Requires review of all changes, not just intended transformations

**Mitigations**:
- All OpenRewrite recipes are type-safe and preserve compilation
- Changes can be reviewed before commit
- Recipe composition allows excluding specific sub-recipes if needed

## Recommendation

Option 1 is ideal when:
- Starting comprehensive modernization effort
- Team wants to adopt modern Java practices
- Trust in framework-provided migration paths
- Accepting OpenRewrite best practices

This approach minimizes custom recipe development and leverages well-tested migration recipes used across thousands of projects.
