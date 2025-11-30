# Option 1: Broad Recipe Composition Analysis

## Strategy
Comprehensive migration using broad, framework-provided recipes that automatically handle multiple transformation aspects.

## Recipe Composition

### 1. org.openrewrite.java.migrate.UpgradeToJava17
**Coverage**: 90%+ of Java 11→17 migration needs

**What it handles**:
- Updates Gradle toolchain configuration (sourceCompatibility/targetCompatibility → toolchain)
- Migrates Java 8→11→17 language features
- Updates build plugins to Java 17 compatible versions
- Handles deprecated API replacements
- Adds J2EE library dependencies no longer bundled with JDK

**Gap**: Does not update GitHub Actions CI workflow - requires separate recipe

**Why chosen**: Single comprehensive recipe that handles the complex multi-step Java version migration, including the toolchain configuration change evident in the PR diff.

### 2. org.openrewrite.java.testing.junit5.JUnit4to5Migration
**Coverage**: 95%+ of JUnit 4→5 migration needs

**What it handles**:
- Updates JUnit dependencies (removes junit:junit, adds junit-jupiter-api and junit-jupiter-engine)
- Changes test configuration (useJUnit() → useJUnitPlatform())
- Migrates annotations (@Before → @BeforeEach, @Test imports, @Assert imports)
- Converts assertion methods
- Updates test runners and rules
- Adds Mockito extension support
- Upgrades Surefire/Failsafe plugins

**Gap**: None for this PR's requirements

**Why chosen**: Comprehensive JUnit migration recipe that handles all annotation and dependency changes shown in PR diff.

### 3. org.openrewrite.gradle.UpdateGradleWrapper
**Coverage**: 100% of Gradle wrapper update

**Configuration**:
- version: 7.6.4 (exact match to PR)
- distribution: bin

**What it handles**:
- Updates gradle-wrapper.properties distributionUrl
- Adds SHA-256 checksum for verification

**Why chosen**: Direct semantic transformation of Gradle wrapper properties file, understanding Gradle's wrapper structure.

### 4. org.openrewrite.gradle.plugins.UpgradePluginVersion
**Coverage**: 100% of shadow plugin update

**Configuration**:
- pluginIdPattern: com.github.johnrengelman.shadow
- newVersion: 7.1.2

**What it handles**:
- Updates shadow plugin version in plugins block
- Handles both inline and property-based version declarations

**Why chosen**: Semantic Gradle DSL transformation that understands plugin declarations.

### 5. org.openrewrite.github.SetupJavaUpgradeJavaVersion
**Coverage**: 100% of GitHub Actions Java version update

**Configuration**:
- minimumJavaMajorVersion: 17

**What it handles**:
- Updates java-version in actions/setup-java steps
- Updates step names referencing Java version

**Gap**: Does not update step names - requires text-based fallback

**Why chosen**: Semantic YAML transformation understanding GitHub Actions workflow structure.

## Coverage Analysis

### Fully Covered (95%)
- Java toolchain configuration migration
- JUnit dependencies update
- JUnit test configuration (useJUnitPlatform)
- JUnit annotations migration
- Gradle wrapper version
- Shadow plugin version
- GitHub Actions java-version parameter

### Gaps (5%)
**GitHub Actions step name**: "Set up JDK 11" → "Set up JDK 17"
- Not covered by SetupJavaUpgradeJavaVersion recipe
- Would require custom text-based recipe or manual update
- Low risk gap - cosmetic change only

## Trade-offs

### Advantages
- Simple, maintainable recipe composition (5 recipes)
- Comprehensive coverage from battle-tested recipes
- Handles edge cases and variations automatically
- Future-proof (broad recipes updated by community)
- Minimal configuration needed

### Disadvantages
- May apply unwanted transformations from broad recipes
- Less control over specific changes
- Potential for larger diff than strictly necessary
- GitHub Actions step name gap requires additional handling

## Recommendation
**Use when**: Starting fresh migration, trust framework defaults, want comprehensive coverage with minimal configuration.

**Complexity**: Low
**Maintenance**: Low
**Risk**: Low (well-tested recipes)
**Coverage**: High (95%)
