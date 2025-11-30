# Option 2: Narrow Recipe Composition Analysis

## Strategy
Surgical, targeted migration using specific recipes that provide precise control over each transformation step.

## Recipe Composition

### 1. org.openrewrite.java.migrate.UpgradeJavaVersion
**Coverage**: Focused Java version update

**Configuration**:
- version: 17

**What it handles**:
- Updates Gradle java.toolchain.languageVersion
- Updates Maven compiler plugin configuration
- Updates gradle.properties Java version

**Why chosen**: Precise control over Java version upgrade without additional Java 17 API migrations. Handles the exact toolchain transformation in PR diff.

### 2. org.openrewrite.gradle.UpdateGradleWrapper
**Coverage**: 100% of Gradle wrapper update

**Configuration**:
- version: 7.6.4
- distribution: bin

**What it handles**: Same as Option 1

### 3. org.openrewrite.gradle.plugins.UpgradePluginVersion
**Coverage**: 100% of shadow plugin update

**Configuration**: Same as Option 1

### 4. org.openrewrite.java.testing.junit5.AddJupiterDependencies
**Coverage**: JUnit 5 dependency addition

**What it handles**:
- Adds junit-jupiter-api to testImplementation
- Adds junit-jupiter-engine to testRuntimeOnly
- Smart about existing dependencies

**Why chosen**: Precise dependency management, adds only JUnit Jupiter artifacts without removing JUnit 4 yet.

### 5. org.openrewrite.java.testing.junit5.GradleUseJunitJupiter
**Coverage**: Test configuration update

**What it handles**:
- Adds useJUnitPlatform() to test block
- Understands Gradle test DSL structure

**Why chosen**: Surgical change to test configuration matching PR diff exactly.

### 6. org.openrewrite.java.testing.junit5.UpdateBeforeAfterAnnotations
**Coverage**: JUnit lifecycle annotations

**What it handles**:
- @Before → @BeforeEach
- @After → @AfterEach
- @BeforeClass → @BeforeAll
- @AfterClass → @AfterAll

**Why chosen**: Focused annotation migration matching PR changes in UserResourceTest.java.

### 7. org.openrewrite.java.testing.junit5.UpdateTestAnnotation
**Coverage**: @Test annotation migration

**What it handles**:
- org.junit.Test → org.junit.jupiter.api.Test
- Preserves test method bodies

**Why chosen**: Precise @Test annotation migration as shown in PR.

### 8. org.openrewrite.java.testing.junit5.AssertToAssertions
**Coverage**: Assertion migration

**What it handles**:
- org.junit.Assert.* → org.junit.jupiter.api.Assertions.*
- Static import migration

**Why chosen**: Handles the static import change from PR diff.

### 9. org.openrewrite.java.testing.junit5.CleanupJUnitImports
**Coverage**: Import cleanup

**What it handles**:
- Removes unused JUnit 4 imports
- Organizes JUnit 5 imports

**Why chosen**: Ensures clean imports after annotation migrations.

### 10. org.openrewrite.java.dependencies.RemoveDependency
**Coverage**: JUnit 4 dependency removal

**Configuration**:
- groupId: junit
- artifactId: junit

**What it handles**:
- Removes junit:junit:4.13.2 from dependencies

**Why chosen**: Explicit removal of JUnit 4 dependency as shown in PR.

### 11. org.openrewrite.github.SetupJavaUpgradeJavaVersion
**Coverage**: GitHub Actions java-version

**Configuration**: Same as Option 1

## Coverage Analysis

### Fully Covered (95%)
- Java version in Gradle toolchain
- JUnit 5 dependencies (junit-jupiter-api, junit-jupiter-engine)
- Test configuration (useJUnitPlatform)
- JUnit annotations (@BeforeEach, @Test, Assertions)
- JUnit imports cleanup
- JUnit 4 dependency removal
- Gradle wrapper version
- Shadow plugin version
- GitHub Actions java-version

### Gaps (5%)
**GitHub Actions step name**: "Set up JDK 11" → "Set up JDK 17"
- Same gap as Option 1
- Requires custom text-based recipe or manual update

**Comment changes in build.gradle**: "Testing - JUnit 4" → "Testing - JUnit 5"
- Low-level text change
- Not covered by semantic recipes
- Low priority cosmetic change

## Trade-offs

### Advantages
- Precise control over each transformation
- Predictable, focused changes
- Easy to debug and understand
- Can exclude specific transformations
- Minimal unintended side effects

### Disadvantages
- More verbose recipe composition (11 recipes vs 5)
- Requires deeper understanding of recipe ecosystem
- May miss edge cases that broad recipes handle
- Higher maintenance burden
- Same GitHub Actions gap as Option 1

## Comparison with PR Diff

### Covered Changes
✓ Java toolchain configuration (via UpgradeJavaVersion)
✓ JUnit dependencies (via AddJupiterDependencies, RemoveDependency)
✓ Test configuration useJUnitPlatform (via GradleUseJunitJupiter)
✓ Annotation migrations (via UpdateBeforeAfterAnnotations, UpdateTestAnnotation)
✓ Import migrations (via AssertToAssertions, CleanupJUnitImports)
✓ Gradle wrapper (via UpdateGradleWrapper)
✓ Shadow plugin (via UpgradePluginVersion)
✓ GitHub Actions java-version (via SetupJavaUpgradeJavaVersion)

### Missing Changes
✗ Comment changes in build.gradle (low priority)
✗ GitHub Actions step name (cosmetic)

## Recommendation
**Use when**: Need precise control, incremental migration, custom requirements, specific pattern targeting.

**Complexity**: Medium
**Maintenance**: Medium
**Risk**: Low (each recipe independently tested)
**Coverage**: High (95%)
