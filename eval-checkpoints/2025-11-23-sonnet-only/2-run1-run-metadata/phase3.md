# Phase 3: Recipe Mapping

## Recipe Discovery and Mapping Completed

Two recipe composition approaches have been created to address the transformation intents identified in Phase 2.

## Option 1: Broad Migration Recipe Approach

**Strategy**: Use comprehensive, battle-tested migration recipes that handle entire transformation domains

**Recipe File**: `option-1-recipe.yaml`
**Recipe Name**: `com.example.UserManagementServiceUpgradeOption1`
**Total Recipes**: 8 broad ecosystem recipes

**Key Recipes**:
1. `org.openrewrite.java.migrate.UpgradeToJava17` - Complete Java 11→17 migration
2. `org.openrewrite.java.testing.junit5.JUnit4to5Migration` - Complete JUnit 4→5 migration
3. `org.openrewrite.gradle.UpdateGradleWrapper` - Gradle wrapper upgrade
4. `org.openrewrite.gradle.plugins.UpgradePluginVersion` - Shadow plugin upgrade
5. `org.openrewrite.java.migrate.gradle.UpdateJavaCompatibilityToToolchain` - Toolchain migration
6. `org.openrewrite.gradle.UpdateJavaCompatibility` - Compatibility fallback
7. `org.openrewrite.github.SetupJavaUpgradeJavaVersion` - CI/CD update

**Coverage**: ~90% of identified intents
**Gap**: Deprecated mainClassName property replacement

## Option 2: Narrow Targeted Recipe Approach

**Strategy**: Use specific, surgical recipes for precise control over each transformation

**Recipe File**: `option-2-recipe.yaml`
**Recipe Name**: `com.example.usermanagement.PRRecipe3Option2`
**Total Recipes**: 12 narrow, targeted recipes

**Key Recipe Groups**:
- Java version migration (1 recipe)
- Gradle infrastructure (2 recipes)
- CI/CD updates (1 recipe)
- JUnit migration (7 recipes)
- Deprecated API fixes (1 recipe)

**Coverage**: 11 of 12 atomic intents (92%)
**Gap**: Shadow plugin backward compatibility workaround

## Comparison

| Aspect | Option 1 (Broad) | Option 2 (Narrow) |
|--------|------------------|-------------------|
| Recipe Count | 8 | 12 |
| Complexity | Low | Medium |
| Coverage | 90% | 92% |
| Transparency | Medium | High |
| Flexibility | Medium | High |
| Risk | Lower (proven recipes) | Medium (more compositions) |

## Analysis Files Created

1. `option-1-creation-analysis.md` - Detailed analysis of broad approach
2. `option-2-creation-analysis.md` - Detailed analysis of narrow approach

Both options are ready for validation in Phase 4.
