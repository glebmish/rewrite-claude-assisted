# Phase 3: Recipe Mapping

## Option 1: Broad Approach
**File**: `option-1-recipe.yaml`
**Recipe Name**: `com.weather.PR3Option1`

### Recipes Used:
1. `org.openrewrite.java.migrate.UpgradeToJava17` - Umbrella recipe for comprehensive Java 11→17 migration
2. `org.openrewrite.gradle.UpdateGradleWrapper` - Gradle wrapper 6.7→7.6
3. `org.openrewrite.text.FindAndReplace` (×2) - Docker image replacements

### Coverage: Prioritizes breadth, may include additional Java migration changes

---

## Option 2: Narrow Approach
**File**: `option-2-recipe.yaml`
**Recipe Name**: `com.weather.PR3Option2`

### Recipes Used:
1. `org.openrewrite.gradle.UpdateJavaCompatibility` - Targeted sourceCompatibility/targetCompatibility
2. `org.openrewrite.gradle.UpdateGradleWrapper` - Gradle wrapper 6.7→7.6
3. `org.openrewrite.text.FindAndReplace` (×2) - Docker image replacements

### Coverage: Prioritizes precision, only touches explicitly identified changes

---

## Known Gaps (Both Options)
- Authentication refactoring (too application-specific)
- User class modifications (custom logic)
- File deletions (JwtAuthFilter, JwtAuthenticator, ApiKeyAuthFilter)
- Test updates

## Status
Phase 3 completed. Two recipe options created for validation.
