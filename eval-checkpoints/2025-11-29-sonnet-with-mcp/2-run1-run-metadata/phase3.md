# Phase 3: Recipe Mapping

## Recipe Discovery Results

### Option 1: Broad/Comprehensive Approach
**Strategy**: Use framework-provided migration recipes for comprehensive coverage
**Recipe Count**: 5
**Coverage**: 95%
**Files**: option-1-recipe.yaml, option-1-creation-analysis.md

**Key Recipes**:
- UpgradeToJava17 (handles Java version, toolchain migration)
- JUnit4to5Migration (complete JUnit migration)
- UpdateGradleWrapper (Gradle 7.6.4)
- UpgradePluginVersion (shadow plugin 7.1.2)
- SetupJavaUpgradeJavaVersion (GitHub Actions)

### Option 2: Narrow/Specific Approach
**Strategy**: Compose specific recipes for surgical precision
**Recipe Count**: 11
**Coverage**: 95%
**Files**: option-2-recipe.yaml, option-2-creation-analysis.md

**Key Recipes**:
- UpgradeJavaVersion (focused Java update)
- UpdateGradleWrapper (Gradle upgrade)
- UpgradePluginVersion (shadow plugin)
- AddJupiterDependencies (JUnit 5 deps)
- GradleUseJunitJupiter (test config)
- UpdateBeforeAfterAnnotations (@Before → @BeforeEach)
- UpdateTestAnnotation (@Test migration)
- AssertToAssertions (assertion imports)
- CleanupJUnitImports (import cleanup)
- RemoveDependency (remove JUnit 4)
- SetupJavaUpgradeJavaVersion (GitHub Actions)

## Coverage Gap Analysis

Both options have identical 5% coverage gap consisting of:
1. **GitHub Actions step name change** ("Set up JDK 11" → "Set up JDK 17") - cosmetic
2. **Comment updates in build.gradle** ("JUnit 4" → "JUnit 5") - cosmetic

These gaps do not affect functionality and are acceptable for automated refactoring.

## Recipe Mapping Insights

- Both approaches achieve same functional coverage (95%)
- Option 1: Lower complexity, easier maintenance
- Option 2: More granular control, better for incremental migrations
- All recipes validated and ready for testing
