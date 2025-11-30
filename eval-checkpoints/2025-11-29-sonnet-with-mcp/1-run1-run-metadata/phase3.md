# Phase 3: Recipe Mapping

## Approach
Created two recipe alternatives using openrewrite-expert agent:
- **Option 1**: Broad migration approach using `UpgradeToJava17`
- **Option 2**: Targeted hybrid approach with explicit recipe composition

## Option 1: Broad Migration
**Strategy**: Leverage comprehensive framework recipe + supplements
- Recipe: `org.openrewrite.java.migrate.UpgradeToJava17`
- Coverage: ~70% automation
- Philosophy: Trust battle-tested migration recipe

**Automated**:
- Java version in build.gradle
- Gradle wrapper upgrade
- File deletions
- Potential Java 17 API migrations

## Option 2: Enhanced Hybrid
**Strategy**: Surgical semantic + text-based transformations
- 10 explicit recipes including Dockerfile text replacement
- Coverage: ~55% automation
- Philosophy: Maximum transparency and control

**Automated**:
- Gradle compatibility changes
- Gradle wrapper upgrade
- Dockerfile base image changes
- File deletions
- Import cleanup

## Common Gaps (Both Options)
Cannot automate without custom recipes:
- Authentication framework refactoring
- ApiKeyAuthenticator signature changes
- User class structural modifications
- Test updates for BasicCredentials

## Files Generated
- `.output/2025-11-28-19-03/option-1-recipe.yaml` (com.weather.api.PRRecipe3Option1)
- `.output/2025-11-28-19-03/option-2-recipe.yaml` (com.weather.api.PRRecipe3Option2)
- `.output/2025-11-28-19-03/option-1-creation-analysis.md`
- `.output/2025-11-28-19-03/option-2-creation-analysis.md`
