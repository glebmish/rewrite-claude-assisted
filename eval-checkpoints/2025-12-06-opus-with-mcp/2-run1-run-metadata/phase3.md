# Phase 3: Recipe Mapping

## Recipe Options Created

### Option 1: Broad Approach (`option-1-recipe.yaml`)
- **Strategy**: Use comprehensive composite recipes
- **Recipe Count**: 6 recipes
- **Key Recipes**:
  - `org.openrewrite.java.migrate.UpgradeToJava17` (comprehensive Java migration)
  - `org.openrewrite.java.testing.junit5.JUnit4to5Migration` (complete JUnit migration)
  - `org.openrewrite.gradle.UpdateGradleWrapper` (7.6.4)
  - `org.openrewrite.gradle.plugins.UpgradePluginVersion` (shadow 7.1.2)
  - `org.openrewrite.github.SetupJavaUpgradeJavaVersion` (17)
  - `org.openrewrite.yaml.ChangeValue` (step name)

### Option 2: Narrow Approach (`option-2-recipe.yaml`)
- **Strategy**: Use targeted single-purpose recipes
- **Recipe Count**: 12 recipes
- **Key Recipes**:
  - `org.openrewrite.gradle.UpdateJavaCompatibility` (17)
  - `org.openrewrite.gradle.RemoveDependency` / `AddDependency` (JUnit)
  - `org.openrewrite.java.testing.junit5.UpdateTestAnnotation`
  - `org.openrewrite.java.testing.junit5.UpdateBeforeAfterAnnotations`
  - `org.openrewrite.java.testing.junit5.AssertToAssertions`
  - `org.openrewrite.java.testing.junit5.GradleUseJunitJupiter`

## Coverage Comparison

| Intent | Option 1 | Option 2 |
|--------|----------|----------|
| Java toolchain migration | ✅ | ✅ |
| Gradle wrapper 7.6.4 | ✅ | ✅ |
| Shadow plugin 7.1.2 | ✅ | ✅ |
| JUnit dependencies | ✅ | ✅ |
| JUnit annotations | ✅ | ✅ |
| useJUnitPlatform() | ✅ | ✅ |
| GitHub Actions JDK 17 | ✅ | ✅ |
| mainClassName → mainClass | ❌ | ❌ |

## Identified Gaps
Both options lack semantic recipe for `mainClassName` → `mainClass` in application plugin.

## Status: ✅ Complete
