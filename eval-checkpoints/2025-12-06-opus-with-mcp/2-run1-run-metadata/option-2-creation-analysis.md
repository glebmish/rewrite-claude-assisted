# Option 2 Recipe Creation Analysis - Narrow/Specific Approach

## Strategy Summary
- **Approach**: Multiple targeted, single-purpose recipes
- **Trade-off**: Maximum precision and control over transformations
- **Recipe Count**: 14 specific recipes

## Intent to Recipe Mapping

### 1. Java 11 to Java 17 Upgrade

| Intent | Recipe | Coverage |
|--------|--------|----------|
| 1.1.1 Migrate to Java Toolchain | `UpdateJavaCompatibility` (version: 17) | Partial - updates compatibility but may not convert to toolchain syntax |
| 1.1.2 Upgrade Shadow plugin 6.1.0 -> 7.1.2 | `UpgradePluginVersion` (pluginIdPattern: com.github.johnrengelman.shadow) | Complete |
| 1.1.3 mainClassName -> mainClass | None found | GAP |
| 1.2 Gradle wrapper 6.9 -> 7.6.4 | `UpdateGradleWrapper` (version: 7.6.4) | Complete |
| 1.3 CI java-version 11 -> 17 | `SetupJavaUpgradeJavaVersion` (minimumJavaMajorVersion: 17) | Complete |
| 1.3 CI step name change | `ChangeValue` with JsonPath | Complete |

### 2. JUnit 4 to JUnit 5 Migration

| Intent | Recipe | Coverage |
|--------|--------|----------|
| 2.1 Remove junit:junit dependency | `RemoveDependency` | Complete |
| 2.1 Add junit-jupiter-api:5.8.1 | `AddDependency` | Complete |
| 2.1 Add junit-jupiter-engine:5.8.1 | `AddDependency` | Complete |
| 2.2 useJUnit() -> useJUnitPlatform() | `GradleUseJunitJupiter` | Complete |
| 2.3.1 @Test import migration | `UpdateTestAnnotation` | Complete |
| 2.3.1 Assert -> Assertions | `AssertToAssertions` | Complete |
| 2.3.2 @Before -> @BeforeEach | `UpdateBeforeAfterAnnotations` | Complete |
| Cleanup unused imports | `CleanupJUnitImports` | Complete |

## Gap Analysis

### Identified Gaps

1. **mainClassName -> mainClass in application block**
   - No semantic recipe found for Gradle application plugin property rename
   - The `MigrateToGradle7` composite recipe does not include this transformation
   - Would require custom recipe or text-based approach (avoided per requirements)

2. **Toolchain block syntax**
   - `UpdateJavaCompatibility` updates version numbers but may not convert old-style `sourceCompatibility/targetCompatibility` to new toolchain block syntax
   - Actual behavior depends on recipe implementation

### Gap Mitigation
- The mainClassName -> mainClass change is a Gradle 7 deprecation
- Manual intervention or custom recipe development may be required

## Recipe Selection Rationale

### Why Narrow Approach Works Well Here

1. **Precise Version Control**
   - Exact JUnit 5.8.1 version specified (matching PR intent)
   - Exact Gradle 7.6.4 version specified
   - Exact Shadow plugin 7.1.2 version specified

2. **Predictable Transformations**
   - Each recipe does one thing well
   - No unexpected side effects from broad migrations
   - Easy to debug if issues arise

3. **Selective Application**
   - Can skip specific recipes if not needed
   - Can reorder recipes for different scenarios

### Recipe Dependencies & Ordering

```
1. UpdateGradleWrapper (7.6.4)       - Infrastructure first
2. UpdateJavaCompatibility (17)      - Build config
3. UpgradePluginVersion (shadow)     - Plugin updates
4. SetupJavaUpgradeJavaVersion       - CI config
5. ChangeValue (step name)           - CI config
6. RemoveDependency (junit)          - Dependencies
7. AddDependency (jupiter-api)       - Dependencies
8. AddDependency (jupiter-engine)    - Dependencies
9. GradleUseJunitJupiter             - Test config
10. UpdateTestAnnotation             - Source code
11. UpdateBeforeAfterAnnotations     - Source code
12. AssertToAssertions               - Source code
13. CleanupJUnitImports              - Cleanup last
```

## Comparison with Broad Approach

| Aspect | Option 2 (Narrow) | Broad Approach |
|--------|-------------------|----------------|
| Recipes used | 14 | 2-3 |
| Precision | High | Medium |
| Version control | Exact | Latest/managed |
| Complexity | Higher | Lower |
| Debugging | Easier | Harder |
| Unexpected changes | Minimal | Possible |

## Semantic Recipe Usage Justification

All recipes selected use OpenRewrite's LST capabilities:
- **Gradle recipes**: Understand Groovy DSL structure
- **JUnit recipes**: Parse Java AST for annotations/imports
- **YAML recipes**: Use JsonPath for structured navigation
- **GitHub Actions**: Understand workflow file structure

No text-based find/replace recipes used.
