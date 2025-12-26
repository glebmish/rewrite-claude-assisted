# Option 1: Broad/Composite Recipe Approach Analysis

## Strategy
Uses comprehensive framework-level recipes that handle multiple transformations, prioritizing coverage over precision.

## Recipe Mapping

| Intent | Recipe | Coverage |
|--------|--------|----------|
| Java 11->17 migration | `org.openrewrite.java.migrate.UpgradeToJava17` | Complete |
| Gradle toolchain setup | Included in UpgradeToJava17 via UpgradeBuildToJava17 | Complete |
| Gradle 6.9->7.6.4 | `org.openrewrite.gradle.UpdateGradleWrapper` | Complete |
| Shadow plugin 6.1.0->7.1.2 | `org.openrewrite.gradle.plugins.UpgradePluginVersion` | Complete |
| mainClassName->mainClass | **GAP** - No semantic recipe exists | Not covered |
| shadowJar mainClassName | **GAP** - No semantic recipe exists | Not covered |
| JUnit 4->5 migration | `org.openrewrite.java.testing.junit5.JUnit4to5Migration` | Complete |
| JUnit dependencies | Included in JUnit4to5Migration | Complete |
| useJUnitPlatform() | Included via GradleUseJunitJupiter | Complete |
| Test annotations | Included in JUnit4to5Migration | Complete |
| Test imports | Included in JUnit4to5Migration | Complete |
| GitHub Actions java-version | `org.openrewrite.github.SetupJavaUpgradeJavaVersion` | Complete |
| GitHub Actions step name | `org.openrewrite.yaml.ChangeValue` | Complete |

## Detailed Recipe Analysis

### 1. UpgradeToJava17
- **Covers**: Build file Java version updates, deprecated API replacements, plugin upgrades
- **Includes**: Java8toJava11 + UpgradeBuildToJava17 + many modernization recipes
- **Note**: May apply additional code modernizations (text blocks, instanceof patterns)

### 2. JUnit4to5Migration
- **Covers**: 40+ sub-recipes for comprehensive JUnit migration
- **Key sub-recipes**:
  - `UpdateBeforeAfterAnnotations`: @Before -> @BeforeEach
  - `UpdateTestAnnotation`: @Test migration
  - `AssertToAssertions`: Assert -> Assertions
  - `GradleUseJunitJupiter`: Adds useJUnitPlatform()
  - `AddJupiterDependencies`: Adds junit-jupiter dependencies
  - `RemoveDependency`: Removes junit:junit

### 3. SetupJavaUpgradeJavaVersion
- **Semantic**: Understands GitHub Actions YAML structure
- **Behavior**: Updates java-version if below minimum
- **Limitation**: Does not update step name text

### 4. ChangeValue (Gap Filler)
- **Semantic**: Uses JsonPath for YAML navigation
- **Purpose**: Update step name "Set up JDK 11" -> "Set up JDK 17"

## Identified Gaps

### 1. Application Plugin mainClassName -> mainClass
- **Issue**: Gradle 7 deprecated `mainClassName` in favor of `mainClass.set()`
- **No recipe found**: This is a Gradle DSL change not covered by existing recipes
- **Manual fix required**: Change `mainClassName = '...'` to `mainClass.set('...')`

### 2. ShadowJar mainClassName Configuration
- **Issue**: Adding `mainClassName` to shadowJar block
- **No recipe found**: Shadow plugin configuration changes not covered
- **Manual fix required**: Add shadowJar block with mainClassName

## Coverage Assessment
- **Estimated coverage**: ~85%
- **Automated transformations**: 12/14 intents
- **Manual intervention needed**: 2 Gradle DSL changes

## Trade-offs

### Pros
- Maximum coverage with minimal configuration
- Battle-tested recipes handling edge cases
- Includes many bonus improvements (code modernization)

### Cons
- May apply unwanted changes (e.g., text blocks, String.formatted)
- Less control over individual transformations
- Cannot handle application plugin mainClassName deprecation
- Cannot handle shadowJar configuration changes

## Recommendations
1. Review generated changes carefully for unwanted modernizations
2. Manually apply mainClassName -> mainClass.set() change
3. Manually add shadowJar { mainClassName = '...' } block
