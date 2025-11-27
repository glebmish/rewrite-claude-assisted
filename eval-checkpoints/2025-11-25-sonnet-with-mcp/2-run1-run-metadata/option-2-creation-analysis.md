# Option 2: Surgical Recipe Composition - Creation Analysis

## Strategy Overview

Option 2 uses **narrow, specific recipes** for surgical precision and predictable outcomes. Each recipe targets a single concern, providing maximum control and transparency over what changes will be applied.

## Recipe Selection and Mapping

### 1. Java Version Upgrade (Build Configuration)

**Recipe**: `org.openrewrite.java.migrate.UpgradeJavaVersion` (version: 17)

**Intent Coverage**:
- Changes `sourceCompatibility` and `targetCompatibility` to Java 17
- Migrates to modern `java.toolchain.languageVersion` configuration
- Updates Gradle project Java compatibility

**Why This Recipe**:
- Specifically targets Gradle build configuration for Java version
- Handles both legacy (sourceCompatibility/targetCompatibility) and modern (toolchain) approaches
- Type-aware transformation that understands Gradle DSL structure
- Won't downgrade if version is already newer

**PR Intent Mapping**:
- ✓ Remove sourceCompatibility/targetCompatibility (lines 34-35)
- ✓ Add java toolchain with languageVersion = 17 (lines 36-38)

### 2. Gradle Wrapper Update

**Recipe**: `org.openrewrite.gradle.UpdateGradleWrapper` (version: 7.6.4)

**Intent Coverage**:
- Updates `gradle-wrapper.properties` distributionUrl
- Changes from gradle-6.9-bin.zip to gradle-7.6.4-bin.zip

**Why This Recipe**:
- Direct, targeted update of wrapper version
- Understands Gradle wrapper properties file structure
- Validates version availability from services.gradle.org

**PR Intent Mapping**:
- ✓ Update distributionUrl in gradle-wrapper.properties (line 79)

### 3. GitHub Actions Java Version

**Recipe**: `org.openrewrite.github.SetupJavaUpgradeJavaVersion` (minimumJavaMajorVersion: 17)

**Intent Coverage**:
- Updates `actions/setup-java` java-version parameter
- Modifies workflow step names referencing Java version

**Why This Recipe**:
- YAML-aware transformation using YAML LST
- Specifically targets GitHub Actions setup-java configuration
- Updates both version values and descriptive step names

**PR Intent Mapping**:
- ✓ Change java-version from '11' to '17' in .github/workflows/ci.yml
- ✓ Update step name from "Set up JDK 11" to "Set up JDK 17"

### 4. JUnit Test Annotation Migration

**Recipe**: `org.openrewrite.java.testing.junit5.UpdateTestAnnotation`

**Intent Coverage**:
- Converts `@org.junit.Test` to `@org.junit.jupiter.api.Test`
- Updates imports from `org.junit.Test` to `org.junit.jupiter.api.Test`

**Why This Recipe**:
- Semantically understands Java annotations
- Preserves test logic while updating framework
- Type-aware: uses Java LST for accurate transformations

**PR Intent Mapping**:
- ✓ Replace import org.junit.Test with org.junit.jupiter.api.Test (lines 93-95)

### 5. JUnit Lifecycle Annotations

**Recipe**: `org.openrewrite.java.testing.junit5.UpdateBeforeAfterAnnotations`

**Intent Coverage**:
- Converts `@Before` to `@BeforeEach`
- Converts `@After` to `@AfterEach`
- Converts `@BeforeClass` to `@BeforeAll`
- Converts `@AfterClass` to `@AfterAll`
- Updates corresponding imports

**Why This Recipe**:
- Targets specific annotation transformations
- Understands semantic differences between JUnit 4 and 5 lifecycle
- Preserves method signatures and logic

**PR Intent Mapping**:
- ✓ Replace import org.junit.Before with org.junit.jupiter.api.BeforeEach (lines 92-94)
- ✓ Replace @Before with @BeforeEach annotation (lines 104-105)

### 6. JUnit Assertions Migration

**Recipe**: `org.openrewrite.java.testing.junit5.AssertToAssertions`

**Intent Coverage**:
- Changes `org.junit.Assert.*` to `org.junit.jupiter.api.Assertions.*`
- Updates static imports
- Adjusts assertion method parameter order (JUnit 5 uses different convention)

**Why This Recipe**:
- Semantic understanding of assertion API differences
- Handles parameter order changes between frameworks
- Preserves assertion logic correctness

**PR Intent Mapping**:
- ✓ Replace import static org.junit.Assert.* with org.junit.jupiter.api.Assertions.* (lines 97-98)

### 7. JUnit Dependency Update

**Recipe**: `org.openrewrite.gradle.ChangeDependency`

**Configuration**:
- oldGroupId: junit, oldArtifactId: junit
- newGroupId: org.junit.jupiter, newArtifactId: junit-jupiter-api
- newVersion: 5.8.1

**Intent Coverage**:
- Replaces `junit:junit:4.13.2` with `junit-jupiter-api:5.8.1`
- Understands Gradle dependency DSL structure

**Why This Recipe**:
- Groovy/Gradle LST-aware transformation
- Precisely targets dependency coordinates
- Preserves dependency configuration (testImplementation)

**PR Intent Mapping**:
- ✓ Remove testImplementation 'junit:junit:4.13.2' (line 47)
- ✓ Add testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.1' (line 49)

### 8. JUnit 5 Runtime Engine

**Recipe**: `org.openrewrite.gradle.AddDependency`

**Configuration**:
- groupId: org.junit.jupiter
- artifactId: junit-jupiter-engine
- version: 5.8.1
- configuration: testRuntimeOnly
- onlyIfUsing: org.junit.jupiter.api.Test

**Intent Coverage**:
- Adds JUnit 5 runtime engine dependency
- Conditional: only adds if JUnit 5 tests are present

**Why This Recipe**:
- Smart dependency addition with preconditions
- Uses correct configuration (testRuntimeOnly)
- Semantic understanding: checks for actual JUnit 5 usage

**PR Intent Mapping**:
- ✓ Add testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.1' (line 50)

### 9. Gradle Test Configuration

**Recipe**: `org.openrewrite.java.testing.junit5.GradleUseJunitJupiter`

**Intent Coverage**:
- Replaces `test { useJUnit() }` with `useJUnitPlatform()`
- Adds configuration block if missing

**Why This Recipe**:
- Understands Gradle build script structure
- Precisely targets test task configuration
- Semantic transformation: knows this is required for JUnit 5

**PR Intent Mapping**:
- ✓ Replace useJUnit() with useJUnitPlatform() (lines 67-69)

### 10. Shadow Plugin Upgrade

**Recipe**: `org.openrewrite.gradle.plugins.UpgradePluginVersion`

**Configuration**:
- pluginId: com.github.johnrengelman.shadow
- newVersion: 7.1.2

**Intent Coverage**:
- Updates Shadow plugin version in plugins block
- Changes from version 6.1.0 to 7.1.2

**Why This Recipe**:
- Targets plugin version specifically
- Understands Gradle plugins DSL
- Semantic transformation of plugin configuration

**PR Intent Mapping**:
- ✓ Update Shadow plugin from 6.1.0 to 7.1.2 (line 26)

## Coverage Analysis

### Fully Covered Intents

**Java Version Upgrade**:
- ✓ Gradle build configuration (toolchain migration)
- ✓ GitHub Actions CI configuration
- ✓ Gradle wrapper version

**JUnit Migration**:
- ✓ Test annotations (@Test)
- ✓ Lifecycle annotations (@Before -> @BeforeEach)
- ✓ Assertion imports and methods
- ✓ Dependencies (junit 4 -> jupiter)
- ✓ Test configuration (useJUnit -> useJUnitPlatform)

**Build Configuration**:
- ✓ Shadow plugin version upgrade

### Gaps and Limitations

**Gap 1: Gradle Application Plugin mainClassName Property**

**Intent**: Replace deprecated `mainClassName` with `mainClass` in application block (lines 57-58)

**Why No Recipe**:
- No standard OpenRewrite recipe exists for this specific Gradle property deprecation
- The transformation is Gradle 7.x-specific for application plugin
- This is a relatively new deprecation not yet covered by standard recipes

**Semantic Challenge**:
- The property rename is straightforward, but proper semantic recipe would need to:
  - Understand Gradle DSL structure for `application` block
  - Recognize the deprecation pattern specific to application plugin
  - Handle both Groovy and Kotlin DSL variants
  - Preserve the string value format

**Recommended Custom Recipe**:
```yaml
# Custom recipe needed
- org.openrewrite.gradle.ChangePropertyKey:
    oldPropertyKey: mainClassName
    newPropertyKey: mainClass
    scope: application
```

**Alternative Approaches**:
1. Manual fix after recipe execution
2. Custom Groovy visitor targeting `application` configuration block
3. Text-based recipe as last resort (not recommended - would be plain text replacement)

**Gap 2: Shadow Plugin mainClassName in shadowJar Block**

**Intent**: Add `mainClassName` property to shadowJar block for compatibility with Shadow 7.1.2 (line 64)

**Why No Recipe**:
- This is a Shadow plugin 7.x-specific requirement
- No standard recipe for adding plugin-specific configurations
- Requires understanding Shadow plugin DSL structure

**Semantic Challenge**:
- Not just adding a property - requires:
  - Detecting shadowJar configuration block
  - Understanding Shadow plugin conventions
  - Extracting mainClassName value from application block
  - Properly formatting in Gradle DSL

**Recommended Custom Recipe**:
A custom visitor would need to:
1. Scan for `application { mainClass = 'X' }` configuration
2. Locate or create `shadowJar { }` block
3. Add `mainClassName = 'X'` property with correct Groovy/Kotlin syntax
4. Only execute if Shadow plugin version >= 7.0

**Alternative Approaches**:
1. Post-recipe manual addition
2. Shadow plugin upgrade guide documentation
3. Custom ScanningRecipe to coordinate between application and shadowJar blocks

## Rationale for Narrow Recipe Approach

### Advantages

**1. Predictability**
- Each recipe has a single, well-defined purpose
- Easier to understand what will change
- Less risk of unexpected transformations

**2. Control**
- Can exclude specific recipes if certain changes aren't desired
- Clear mapping between intent and recipe
- Fine-grained error isolation

**3. Testability**
- Each transformation can be validated independently
- Easier to debug issues with specific recipes
- Clear success/failure attribution

**4. Transparency**
- Team can see exactly which transformations are applied
- Better for compliance and audit requirements
- Educational value: understanding each migration step

**5. Incremental Migration**
- Can apply recipes in phases
- Test after each set of changes
- Rollback specific transformations if needed

### Trade-offs

**1. Verbosity**
- More recipe entries in configuration
- Requires more detailed recipe knowledge
- Longer recipe list to maintain

**2. Coordination**
- Must ensure recipes are ordered correctly
- Some recipes may have dependencies on others
- Need to understand recipe interactions

**3. Completeness**
- May miss transformations that broad recipes include
- Requires thorough intent analysis
- Gaps more visible (but this is also an advantage)

## Expected Transformation Results

### Files Modified

**1. build.gradle**
- Java version configuration (toolchain)
- Shadow plugin version
- JUnit dependencies (4 -> 5)
- Test task configuration (useJUnitPlatform)

**2. gradle/wrapper/gradle-wrapper.properties**
- Gradle version (6.9 -> 7.6.4)

**3. .github/workflows/ci.yml**
- Java version in setup-java action
- Step name referencing Java version

**4. src/test/java/com/example/usermanagement/UserResourceTest.java**
- Test annotation imports
- Lifecycle annotation imports
- Assertion imports
- Annotation usage in test methods

### Manual Follow-up Required

**1. Application Block Property**
- Change `mainClassName = '...'` to `mainClass = '...'`
- Location: build.gradle, application block

**2. Shadow Jar Configuration**
- Add `mainClassName` property to shadowJar block
- Location: build.gradle, shadowJar configuration

## Recipe Execution Order

The recipes are ordered to ensure proper dependency flow:

1. **Java version upgrades** (build + CI) - Foundation changes
2. **Gradle wrapper** - Build tool compatibility
3. **JUnit annotations** - Code transformations before dependency changes
4. **JUnit dependencies** - After code is ready
5. **Test configuration** - After dependencies are in place
6. **Plugin upgrades** - Last, after all other changes

## Validation Recommendations

**After Recipe Execution**:
1. Verify build.gradle compiles: `./gradlew build --dry-run`
2. Run tests: `./gradlew test`
3. Check for manual fixes needed (mainClassName properties)
4. Review Git diff for unexpected changes
5. Ensure CI workflow syntax is valid

## Comparison to Option 1

Option 2 provides:
- **More granular control** vs. Option 1's comprehensive approach
- **Easier troubleshooting** - specific recipe failures are isolated
- **Better documentation** - explicit list of what changes
- **Requires more expertise** - need to know available recipes
- **May miss edge cases** that broad recipes would catch
- **More gaps visible** - manual work is explicit, not hidden

## Conclusion

Option 2 demonstrates a **surgical, precise approach** to migration using targeted recipes. It provides maximum control and transparency, making it ideal for:

- Teams that want to understand each transformation
- Gradual migration strategies
- Environments requiring change approval and audit trails
- Situations where only specific migrations are desired

The identified gaps (Gradle property deprecations) represent areas where:
1. Standard recipes don't yet exist
2. Custom recipe development would be valuable
3. Manual intervention is acceptable and explicit

This approach trades convenience for control, making it suitable for teams prioritizing predictability and understanding over comprehensive automation.
