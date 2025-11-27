# Phase 3: Recipe Mapping

## Approach
Used specialized openrewrite-expert agents to discover and compose two recipe options:
- **Option 1**: Broad/comprehensive migration approach
- **Option 2**: Narrow/targeted specific recipes approach

## Option 1: Comprehensive Approach
**Recipe**: option-1-recipe.yaml
**Name**: com.example.PRRecipe2Option1

### Composition
1. org.openrewrite.java.migrate.UpgradeToJava21 - Primary migration
2. org.openrewrite.gradle.UpdateGradleWrapper - Gradle 8.1 → 8.5

### Coverage
- ✅ GitHub Actions CI: java-version 17→21 (automated)
- ✅ Gradle build: sourceCompatibility/targetCompatibility → toolchain with Java 21 (automated)
- ✅ Gradle wrapper: 8.1 → 8.5 (automated)
- ❌ Dockerfile: eclipse-temurin:17 → eclipse-temurin:21 (gap - no semantic recipe)
- ❌ README.md: Documentation updates (gap - manual preferred)

### Advantages
- Simplicity: Only 2 recipes
- Well-tested official migration path
- Semantic transformations using LST
- Handles additional Java 21 features beyond scope

## Option 2: Surgical Precision Approach
**Recipe**: option-2-recipe.yaml
**Name**: com.example.PRRecipe2Option2

### Composition
1. SetupJavaUpgradeJavaVersion - GitHub Actions
2. UpdateJavaCompatibility (source) - Gradle source compatibility
3. UpdateJavaCompatibility (target) - Gradle target compatibility
4. UpdateGradleWrapper - Gradle wrapper
5. FindAndReplace - Dockerfile JDK image
6. FindAndReplace - Dockerfile JRE image
7. FindAndReplace - README Java version
8. FindAndReplace - README Gradle version

### Coverage
- ✅ GitHub Actions CI: java-version 17→21 (semantic)
- ✅ Gradle build: sourceCompatibility/targetCompatibility with Java 21 (semantic, no toolchain migration)
- ✅ Gradle wrapper: 8.1 → 8.5 (semantic)
- ✅ Dockerfile: eclipse-temurin:17 → eclipse-temurin:21 (text-based)
- ✅ README.md: Documentation updates (text-based)

### Advantages
- Maximum precision and control
- Complete coverage of all PR changes
- Each recipe does exactly one transformation
- Easy to debug

### Limitations
- More verbose (8 recipes)
- Text-based replacements for Dockerfile and README
- Does not migrate to toolchain (different from PR)

## Key Differences
1. **Coverage**: Option 2 covers all changes; Option 1 has gaps
2. **Gradle toolchain**: Option 1 migrates to toolchain (matches PR); Option 2 keeps sourceCompatibility
3. **Text files**: Option 2 handles Dockerfile/README; Option 1 does not
4. **Complexity**: Option 1 is simpler; Option 2 is more granular

## Files Created
- .output/2025-11-24-22-42/option-1-recipe.yaml
- .output/2025-11-24-22-42/option-1-creation-analysis.md
- .output/2025-11-24-22-42/option-2-recipe.yaml
- .output/2025-11-24-22-42/option-2-creation-analysis.md
