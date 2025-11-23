# Option 2: Narrow Targeted Recipe Approach - Analysis

## Recipe Composition Strategy

**Approach**: Surgical precision using narrow, specific recipes for fine-grained control over each transformation

**Recipe Name**: `com.example.usermanagement.PRRecipe3Option2`

## Selected Recipes and Rationale

### 1. Java Version Migration (Intent 1)

**Recipe**: `org.openrewrite.gradle.UpdateJavaCompatibility`
- **Parameters**:
  - `version: 17`
  - `declarationStyle: TOOLCHAIN`
  - `compatibilityType: BOTH`
- **Rationale**: Targets Gradle build files specifically to migrate from sourceCompatibility/targetCompatibility to toolchain API
- **Coverage**: Updates build.gradle to use Java 17 toolchain configuration
- **Semantic approach**: Understands Gradle DSL structure and applies proper toolchain configuration

### 2. Gradle Wrapper Upgrade (Intent 2)

**Recipe**: `org.openrewrite.gradle.UpdateGradleWrapper`
- **Parameters**:
  - `version: 7.6.4`
  - `distribution: bin`
- **Rationale**: Precisely upgrades Gradle wrapper from 6.9 to 7.6.4
- **Coverage**: Updates gradle/wrapper/gradle-wrapper.properties
- **Semantic approach**: Understands Gradle wrapper properties file format and distribution mechanisms

### 3. Shadow Plugin Upgrade (Intent 5.1)

**Recipe**: `org.openrewrite.gradle.plugins.UpgradePluginVersion`
- **Parameters**:
  - `pluginIdPattern: com.github.johnrengelman.shadow`
  - `newVersion: 7.1.2`
- **Rationale**: Targets specific plugin upgrade without affecting other plugins
- **Coverage**: Updates shadow plugin from 6.1.0 to 7.1.2 in build.gradle
- **Semantic approach**: Understands Gradle plugin DSL and applies version updates correctly

### 4. GitHub Actions CI Update (Intent 3)

**Recipe**: `org.openrewrite.github.SetupJavaUpgradeJavaVersion`
- **Parameters**:
  - `minimumJavaMajorVersion: 17`
- **Rationale**: Targets GitHub Actions workflow files to update Java version
- **Coverage**: Updates .github/workflows/ci.yml setup-java action from Java 11 to 17
- **Semantic approach**: Understands GitHub Actions YAML structure and setup-java action syntax

### 5. JUnit 4 to JUnit 5 Migration (Intent 4)

**Seven targeted recipes for complete test migration**:

#### 5.1 `org.openrewrite.java.testing.junit5.UpdateTestAnnotation`
- **Coverage**: Migrates @Test annotation from org.junit.Test to org.junit.jupiter.api.Test
- **Semantic approach**: Type-aware Java refactoring that updates imports and annotations

#### 5.2 `org.openrewrite.java.testing.junit5.UpdateBeforeAfterAnnotations`
- **Coverage**: Converts @Before to @BeforeEach, @After to @AfterEach
- **Semantic approach**: Understands JUnit lifecycle annotations semantics

#### 5.3 `org.openrewrite.java.testing.junit5.AssertToAssertions`
- **Coverage**: Migrates org.junit.Assert.* to org.junit.jupiter.api.Assertions.*
- **Semantic approach**: Type-aware static import migration preserving assertion semantics

#### 5.4 `org.openrewrite.java.testing.junit5.CleanupJUnitImports`
- **Coverage**: Removes obsolete JUnit 4 imports after migration
- **Semantic approach**: Import management based on actual usage analysis

#### 5.5 `org.openrewrite.java.testing.junit5.AddJupiterDependencies`
- **Coverage**: Adds JUnit Jupiter API and Engine dependencies
- **Semantic approach**: Dependency management understanding Maven/Gradle dependency syntax

#### 5.6 `org.openrewrite.java.testing.junit5.GradleUseJunitJupiter`
- **Coverage**: Changes test { useJUnit() } to test { useJUnitPlatform() }
- **Semantic approach**: Understands Gradle test configuration DSL

#### 5.7 `org.openrewrite.java.testing.junit5.ExcludeJUnit4UnlessUsingTestcontainers`
- **Coverage**: Removes JUnit 4 dependencies from build files
- **Semantic approach**: Dependency analysis to safely remove obsolete dependencies

### 6. Deprecated Gradle API Migration (Intent 6.1)

**Recipe**: `org.openrewrite.text.FindAndReplace`
- **Parameters**:
  - `find: mainClassName`
  - `replace: mainClass`
  - `filePattern: "**/build.gradle"`
- **Rationale**: No semantic Gradle recipe exists for this specific deprecation
- **Coverage**: Replaces mainClassName with mainClass in application block
- **Limitation**: Text-based replacement, last resort approach
- **Risk**: May replace in shadowJar block where backward compatibility is needed (see Gap Analysis below)

## Coverage Assessment

### Complete Coverage

| Intent ID | Description | Recipe(s) |
|-----------|-------------|-----------|
| 1.1.1 | Remove sourceCompatibility/targetCompatibility | UpdateJavaCompatibility |
| 1.1.2 | Add Java toolchain section | UpdateJavaCompatibility |
| 2.1.1 | Update Gradle wrapper to 7.6.4 | UpdateGradleWrapper |
| 3.1.1 | Update GitHub Actions Java version | SetupJavaUpgradeJavaVersion |
| 4.1.1 | Replace JUnit 4 deps with JUnit 5 | AddJupiterDependencies + ExcludeJUnit4 |
| 4.2.1 | Change useJUnit to useJUnitPlatform | GradleUseJunitJupiter |
| 4.3.1 | Replace JUnit 4 imports | UpdateTestAnnotation + CleanupJUnitImports |
| 4.3.2 | Replace @Before with @BeforeEach | UpdateBeforeAfterAnnotations |
| 4.3.1 | Migrate Assert to Assertions | AssertToAssertions |
| 5.1.1 | Upgrade shadow plugin to 7.1.2 | UpgradePluginVersion |
| 6.1.1 | Replace mainClassName with mainClass | FindAndReplace |

### Partial Coverage

| Intent ID | Description | Issue |
|-----------|-------------|-------|
| 6.1.2 | Add mainClassName to shadowJar block | Not covered - requires custom recipe |

## Gap Analysis

### Identified Gaps

**Gap 1: Shadow Plugin Backward Compatibility**

**Intent 6.1.2**: "Add mainClassName to shadowJar block for backward compatibility"

**Issue**:
- Text-based FindAndReplace will replace ALL occurrences of mainClassName
- PR shows mainClassName should be removed from application block but ADDED to shadowJar block
- No semantic recipe exists for this plugin-specific configuration nuance

**Impact**: Medium - Recipe will correctly rename in application block, but won't add the property to shadowJar block

**Recommendation**:
- Custom recipe needed to:
  1. Remove mainClassName from application block and replace with mainClass
  2. Add mainClassName to shadowJar block with correct value
  3. Understand shadow plugin DSL structure semantically

**Alternative workaround**:
- Manual post-migration fix
- Or remove FindAndReplace recipe and handle mainClassName migration manually

### Why Narrow Recipes Were Chosen

**Granular Control**: Each recipe targets a specific transformation pattern, allowing precise control over what changes

**Explicit Dependencies**: Clear understanding of what each recipe does, easier to debug if issues arise

**Selective Application**: Can easily disable specific recipes if they cause conflicts in your environment

**Composability**: Recipes can be reordered or removed based on specific project needs

**Risk Mitigation**: Smaller, focused transformations reduce risk of unintended side effects

## Recipe Ordering Rationale

1. **Build configuration first** (UpdateJavaCompatibility) - Foundation for other changes
2. **Gradle wrapper** (UpdateGradleWrapper) - Ensure compatible Gradle version for other transformations
3. **Plugin upgrades** (UpgradePluginVersion) - Update plugins before code changes
4. **CI/CD updates** (SetupJavaUpgradeJavaVersion) - Infrastructure alignment
5. **Test framework migration** (JUnit recipes) - Code-level transformations
6. **Deprecated API cleanup** (FindAndReplace) - Final cleanup step

## Expected Transformations

### build.gradle
```diff
- java {
-     sourceCompatibility = JavaVersion.VERSION_11
-     targetCompatibility = JavaVersion.VERSION_11
- }
+ java {
+     toolchain {
+         languageVersion = JavaLanguageVersion.of(17)
+     }
+ }

- id 'com.github.johnrengelman.shadow' version '6.1.0'
+ id 'com.github.johnrengelman.shadow' version '7.1.2'

- testImplementation 'junit:junit:4.13.2'
+ testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.1'
+ testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.1'

- test {
-     useJUnit()
- }
+ test {
+     useJUnitPlatform()
+ }

- application {
-     mainClassName = 'com.example.usermanagement.UserManagementApplication'
- }
+ application {
+     mainClass = 'com.example.usermanagement.UserManagementApplication'
+ }
```

### gradle/wrapper/gradle-wrapper.properties
```diff
- distributionUrl=https\://services.gradle.org/distributions/gradle-6.9-bin.zip
+ distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.4-bin.zip
```

### .github/workflows/ci.yml
```diff
-     - name: Set up JDK 11
        uses: actions/setup-java@v3
        with:
-         java-version: '11'
+         java-version: '17'
          distribution: 'temurin'
```

### src/test/java/com/example/usermanagement/UserResourceTest.java
```diff
- import org.junit.Before;
- import org.junit.Test;
- import static org.junit.Assert.*;
+ import org.junit.jupiter.api.BeforeEach;
+ import org.junit.jupiter.api.Test;
+ import static org.junit.jupiter.api.Assertions.*;

- @Before
+ @BeforeEach
  public void setUp() {
```

## Testing Recommendations

### Phase 1: Build Verification
1. Run `./gradlew clean build` to verify Gradle 7.6.4 compatibility
2. Confirm Java 17 toolchain is recognized and applied
3. Verify shadow plugin 7.1.2 creates fat jar correctly

### Phase 2: Test Execution
1. Run `./gradlew test` to ensure JUnit 5 tests execute
2. Verify all test assertions pass with JUnit Jupiter
3. Check test lifecycle methods (@BeforeEach) work correctly

### Phase 3: CI/CD Validation
1. Push changes and verify GitHub Actions workflow uses Java 17
2. Confirm CI build and test steps succeed
3. Validate Docker image builds with Java 17

### Phase 4: Manual Verification
1. Review mainClassName changes in both application and shadowJar blocks
2. Add missing mainClassName to shadowJar block if needed (Gap 1)
3. Verify application starts correctly with new configuration

## Advantages of Option 2

**Precision**: Each transformation is explicitly defined and controlled

**Transparency**: Easy to understand what each recipe does and why it's included

**Flexibility**: Can easily add, remove, or reorder recipes based on needs

**Debugging**: If one recipe fails, others can still succeed independently

**Learning**: Clear mapping between intents and specific recipes aids understanding

## Disadvantages of Option 2

**Verbosity**: More recipes to manage compared to a single broad recipe

**Maintenance**: Need to keep track of multiple individual recipes

**Completeness**: Risk of missing edge cases that broad recipes might catch

**Gap in Coverage**: mainClassName/shadowJar backward compatibility requires manual intervention or custom recipe

## Comparison to Broad Recipe Approach

**Narrow (Option 2)**:
- Uses 14 specific recipes
- Each recipe targets one transformation pattern
- Explicit control over each change
- Gap: Shadow plugin backward compatibility

**Broad Alternative** (e.g., UpgradeToJava17 + JUnit4to5Migration):
- Would use 2 composite recipes
- Potentially includes transformations not needed
- Less explicit control
- May include additional changes beyond PR scope
- Unknown coverage of shadow plugin specifics

## Conclusion

Option 2 provides surgical precision for the identified intents with explicit control over each transformation. The narrow approach offers transparency and flexibility at the cost of verbosity. One gap exists for shadow plugin backward compatibility that requires either a custom recipe or manual post-migration fix.
