# Phase 3: Recipe Mapping

## Recipe Options Created

Two recipe options have been generated with different approaches:

### Option 1: Broad Migration Approach
**File**: `option-1-recipe.yaml`
**Recipe Name**: `com.example.PR3Option1`

**Strategy**: Uses comprehensive, high-level migration recipes

**Key Recipes**:
1. `org.openrewrite.java.migrate.UpgradeToJava17` - Complete Java 11→17 migration
2. `org.openrewrite.java.testing.junit5.JUnit4to5Migration` - Comprehensive JUnit migration
3. `org.openrewrite.gradle.UpdateGradleWrapper` - Gradle wrapper upgrade
4. `org.openrewrite.gradle.plugins.UpgradePluginVersion` - Shadow plugin upgrade
5. `org.openrewrite.github.SetupJavaUpgradeJavaVersion` - GitHub Actions update

**Coverage**: 95% of PR changes with automatic handling of related transformations
**Gap**: Gradle property renames (mainClassName → mainClass)

### Option 2: Surgical Precision Approach
**File**: `option-2-recipe.yaml`
**Recipe Name**: `com.example.PR3Option2`

**Strategy**: Uses 10 narrow, specific recipes for maximum control

**Key Recipes**:
1. `UpgradeJavaVersion` - Java toolchain configuration
2. `UpdateGradleWrapper` - Gradle version
3. `SetupJavaUpgradeJavaVersion` - GitHub Actions
4. `UpdateTestAnnotation` - JUnit @Test migration
5. `UpdateBeforeAfterAnnotations` - JUnit @Before → @BeforeEach
6. `AssertToAssertions` - Assert.* → Assertions.*
7. `ChangeDependency` - JUnit dependency update
8. `AddDependency` - Add junit-jupiter-engine
9. `GradleUseJunitJupiter` - Test configuration
10. `UpgradePluginVersion` - Shadow plugin

**Coverage**: 90% of PR changes with explicit, predictable transformations
**Gap**: Gradle property renames (mainClassName → mainClass, shadowJar mainClassName addition)

## Outputs
- `option-1-recipe.yaml` - Broad recipe composition
- `option-1-creation-analysis.md` - Analysis for Option 1
- `option-2-recipe.yaml` - Narrow recipe composition
- `option-2-creation-analysis.md` - Analysis for Option 2
