# Option 2: Targeted Java 17 Migration

## Approach
Narrow/surgical strategy using specific recipes for exact PR transformations.

## Recipe Selection

### Recipe 1 & 2: org.openrewrite.gradle.UpdateJavaCompatibility
**Parameters**:
- First instance: `version: 17, compatibilityType: source`
- Second instance: `version: 17, compatibilityType: target`

**Rationale**: Precisely targets the two specific changes in build.gradle:
- Line 29: `sourceCompatibility = '11'` → `sourceCompatibility = '17'`
- Line 30: `targetCompatibility = '11'` → `targetCompatibility = '17'`

Uses Gradle LST to understand build file structure, not text replacement.

**Coverage**: Only the specific Java version declarations in build.gradle

### Recipe 3: org.openrewrite.gradle.UpdateGradleWrapper
**Parameters**: `version: 7.6`

**Rationale**: Targets exact Gradle wrapper version change
- Updates gradle/wrapper/gradle-wrapper.properties
- Changes version 6.7 to 7.6

**Coverage**: Gradle wrapper properties file

## Gap Analysis

### Covered Transformations
- sourceCompatibility: 11 → 17 in build.gradle
- targetCompatibility: 11 → 17 in build.gradle
- Gradle wrapper: 6.7 → 7.6

### Uncovered Transformations
**Dockerfile base image updates**: No semantic Dockerfile recipes available
- Builder stage: openjdk:11-jdk-slim → eclipse-temurin:17-jdk-alpine
- Runtime stage: openjdk:11-jre-slim → eclipse-temurin:17-jre-alpine

**Authentication refactoring**: Application-specific, not automatable via recipes

## Trade-offs

**Advantages**:
- Minimal scope - only changes what PR shows
- Predictable, no surprise transformations
- Easy to understand and verify
- Fast execution (fewer sub-recipes)
- Precise control

**Disadvantages**:
- Misses Java 17 code modernization opportunities
- No deprecated API replacements
- No plugin compatibility checks
- Dockerfile still requires manual work or custom recipe
- May miss compatibility issues that broad recipe catches

## Expected Coverage
- Build configuration: 100% (sourceCompatibility/targetCompatibility)
- Gradle wrapper: 100%
- Dockerfile: 0% (requires custom solution)
- Authentication: 0% (application-specific, not in scope)
- Java code modernization: 0% (not included in narrow approach)

## Recommended Next Steps
For complete PR automation, would need custom Dockerfile recipe. Consider whether Java 17 modernization features are desired.
