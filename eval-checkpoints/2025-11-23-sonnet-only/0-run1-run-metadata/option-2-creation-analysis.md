# Option 2: Surgical Targeted Approach - Analysis

## Strategy
Avoid broad migration recipe. Use only specific, narrow recipes targeting exact PR requirements without additional transformations.

## Intent Categorization

**Java Version Upgrade**: Java 17 → Java 21
**Build System**: Gradle toolchain migration, wrapper update
**Infrastructure**: Docker image updates
**CI/CD**: GitHub Actions Java version + step name
**Documentation**: README updates

## Recipe Discovery & Mapping

### Transformation 1: Gradle Build Configuration

**Required Changes**:
- Remove sourceCompatibility = '17'
- Remove targetCompatibility = '17'
- Add java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }

**Recipe Search**:
- org.openrewrite.gradle.UpdateJavaCompatibility - Only updates VERSION, not structure
- org.openrewrite.java.migrate.UpgradeJavaVersion - Calls UpdateJavaCompatibility
- No semantic recipe exists for toolchain structure migration

**Selected Recipe**: org.openrewrite.text.FindAndReplace
- Rationale: Structural change requires text replacement
- No LST-aware Gradle recipe handles toolchain migration
- Alternative would require custom recipe implementation

**Coverage**: Complete

### Transformation 2: Gradle Wrapper Update

**Required**: 8.1 → 8.5

**Recipe**: org.openrewrite.gradle.UpdateGradleWrapper
- Parameter: version: 8.5
- LST-aware, updates gradle-wrapper.properties semantically
- Includes SHA256 checksum verification

**Coverage**: Complete

### Transformation 3: Docker Configuration

**Required Changes**:
- eclipse-temurin:17-jdk-alpine → eclipse-temurin:21-jdk-alpine
- eclipse-temurin:17-jre-alpine → eclipse-temurin:21-jre-alpine

**Recipe Search**:
- No OpenRewrite Docker parser exists
- org.openrewrite.kubernetes.UpdateContainerImageName - Only for K8s YAML
- Text-based approach is recommended for Dockerfiles

**Selected Recipe**: org.openrewrite.text.FindAndReplace (2 instances)
- Rationale: No semantic alternative available
- FROM statement structure update

**Coverage**: Complete

### Transformation 4: GitHub Actions CI

**Required Changes**:
- Step name: "Set up JDK 17" → "Set up JDK 21"
- java-version: '17' → '21'

**Recipe Search**:
- org.openrewrite.github.SetupJavaUpgradeJavaVersion - Only updates java-version parameter
- No recipe updates step names

**Selected Recipes**:
1. org.openrewrite.text.FindAndReplace - For step name (no semantic alternative)
2. org.openrewrite.github.SetupJavaUpgradeJavaVersion - For java-version (LST-aware YAML)

**Coverage**: Complete

### Transformation 5: Documentation

**Required**: Java 17 → Java 21, Gradle 8.1 → 8.5 in README.md

**Recipe Search**: No documentation-specific recipes exist

**Selected Recipe**: org.openrewrite.text.FindAndReplace (2 instances)
- Rationale: Markdown documentation changes are content-based
- No semantic structure to preserve

**Coverage**: Complete

## Gap Analysis Summary

**True Gaps** (no semantic recipe exists):
- Gradle toolchain structure migration
- Docker FROM statement updates
- GitHub Actions step name updates
- Markdown documentation updates

**Available Semantic Recipes Used**:
- org.openrewrite.gradle.UpdateGradleWrapper
- org.openrewrite.github.SetupJavaUpgradeJavaVersion

## Composition Strategy: Surgical Precision

All recipes target exact PR requirements:

**Semantic Recipes** (2):
- UpdateGradleWrapper
- SetupJavaUpgradeJavaVersion

**Text Recipes** (6):
- build.gradle toolchain migration
- Dockerfile JDK image
- Dockerfile JRE image
- GitHub Actions step name
- README Java version
- README Gradle version

**Recipe Ordering**: Text recipes placed strategically to minimize LST impact. UpdateGradleWrapper remains semantic.

## Trade-offs

**Advantages**:
- Exact control over every transformation
- No unwanted code changes (switch expressions, API migrations)
- Clear 1:1 mapping between PR changes and recipes
- Minimal risk of unexpected transformations
- Easier to debug individual recipe failures

**Disadvantages**:
- More verbose recipe list
- No automatic Java 21 API adoption
- No automatic plugin compatibility upgrades
- Heavy reliance on text-based recipes (6 of 8)
- Text recipes fragile to exact string variations
- Misses potential code improvements

## Validation Recommendations

- Verify exact string matching for all FindAndReplace recipes
- Confirm toolchain block indentation matches Gradle conventions
- Test Gradle build with toolchain configuration
- Verify Docker multi-stage build still works
- Check GitHub Actions workflow syntax

## Comparison to Option 1

**When to prefer Option 2**:
- Want minimal changes only
- Concerned about UpgradeToJava21 side effects
- Need exact reproducibility of PR changes
- Don't want automatic code modernization

**When to prefer Option 1**:
- Want comprehensive Java 21 feature adoption
- Trust OpenRewrite's migration expertise
- Willing to review/accept code improvements
- Want plugin compatibility handled automatically
