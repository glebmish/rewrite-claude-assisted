# Option 1: Comprehensive Java 17 Migration

## Approach
Broad/comprehensive strategy using official OpenRewrite migration recipes.

## Recipe Selection

### Primary Recipe: org.openrewrite.java.migrate.UpgradeToJava17
**Rationale**: Comprehensive migration recipe that includes:
- `Java8toJava11` migration (base layer)
- `UpgradeBuildToJava17` (updates sourceCompatibility/targetCompatibility via `UpgradeJavaVersion`)
- Java 17 language features (instanceof patterns, text blocks, String.formatted)
- Deprecated API replacements
- Plugin compatibility upgrades
- Dependency version updates for Java 17 compatibility

**Coverage**:
- Changes sourceCompatibility from '11' to '17' in build.gradle
- Changes targetCompatibility from '11' to '17' in build.gradle
- Applies modern Java 17 code patterns
- Upgrades incompatible dependencies

### Complementary Recipe: org.openrewrite.gradle.UpdateGradleWrapper
**Parameters**: `version: 7.6`

**Rationale**: Updates Gradle wrapper to version 7.6 (Java 17 compatible)

**Coverage**:
- Changes distributionUrl from gradle-6.7-all.zip to gradle-7.6-all.zip
- Adds SHA-256 checksum for security

## Gap Analysis

### Covered Transformations
- Java version in build.gradle (sourceCompatibility/targetCompatibility)
- Gradle wrapper version upgrade
- Java API migrations and modernization
- Plugin compatibility

### Uncovered Transformations
**Dockerfile base image updates**: No semantic Dockerfile recipes exist for changing FROM statements
- Change FROM openjdk:11-jdk-slim to eclipse-temurin:17-jdk-alpine
- Change FROM openjdk:11-jre-slim to eclipse-temurin:17-jre-alpine

**Authentication refactoring**: Application-specific business logic, not automatable

## Trade-offs

**Advantages**:
- Simple, single comprehensive recipe
- Handles many edge cases automatically
- Applies Java 17 best practices
- Future-proof for subsequent migrations
- Well-tested across many projects

**Disadvantages**:
- May apply more changes than PR shows (e.g., code modernization)
- Less granular control over specific transformations
- Could introduce unintended changes beyond scope
- Dockerfile changes require manual intervention or custom recipe

## Expected Coverage
- Build configuration: 100% (both recipes handle this)
- Gradle wrapper: 100%
- Dockerfile: 0% (requires custom solution)
- Authentication: 0% (application-specific, not in scope)

## Recommended Next Steps
For complete PR automation, would need custom Dockerfile recipe or text-based transformation.
