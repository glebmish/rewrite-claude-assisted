# Phase 2: Intent Analysis

## PR Information
- **URL**: https://github.com/openrewrite-assist-testing-dataset/ecommerce-catalog/pull/2
- **Title**: Update Dockerfile and Github Actions to Eclipse Temurin 21
- **Branch**: feature/dockerfile-temurin-upgrade-pr

## OpenRewrite Best Practices - Key Insights
- Language version upgrades require coordinated changes across multiple file types
- Multi-file transformations should use appropriate language-specific visitors (YAML for GitHub Actions, text for Dockerfile, Groovy for Gradle)
- Recipe composition should be layered: structural changes → API updates → cleanup → formatting
- Use narrow/specific recipes for surgical precision when requirements are clear

## PR Description Analysis
The PR explicitly states:
- Changed base image from Eclipse Temurin 17 to Eclipse Temurin 21
- Changed GitHub Actions from Eclipse Temurin 17 to Eclipse Temurin 21

## Code Changes Analysis

### Files Modified
1. **.github/workflows/ci.yml** (YAML)
   - Line 9: Step name: "Set up JDK 17" → "Set up JDK 21"
   - Line 13: java-version: '17' → '21'

2. **Dockerfile** (text)
   - Line 2: FROM eclipse-temurin:17-jdk-alpine → eclipse-temurin:21-jdk-alpine
   - Line 18: FROM eclipse-temurin:17-jre-alpine → eclipse-temurin:21-jre-alpine

3. **README.md** (markdown)
   - Line 17: "Java 17" → "Java 21" (Technology Stack section)
   - Line 56: "Java 17" → "Java 21" (Prerequisites section)

4. **build.gradle** (Groovy)
   - Lines 11-13: Removed `sourceCompatibility = '17'` and `targetCompatibility = '17'`
   - Lines 11-15: Added java toolchain configuration with languageVersion = JavaLanguageVersion.of(21)
   - Line 83: gradleVersion = '8.1' → '8.5'

## Transformation Patterns Identified

### Pattern 1: String replacement (17 → 21)
- All occurrences of "17" related to Java version are replaced with "21"
- Applies to: YAML values, Docker image tags, markdown text, Gradle configurations

### Pattern 2: Gradle configuration modernization
- Migration from deprecated `sourceCompatibility`/`targetCompatibility` to modern toolchain API
- This is not just version change but structural transformation

### Pattern 3: Gradle wrapper version upgrade
- Version 8.1 → 8.5 (required for Java 21 support)

## Edge Cases and Exceptions
- No exceptions identified - changes are systematic
- All Java 17 references updated to Java 21
- Gradle modernization follows current best practices

## Intents Tree

### Strategic Goal: Upgrade Java 17 to Java 21
**Confidence**: High
**Type**: Language Version Upgrade

#### 1. Update GitHub Actions CI Configuration
**Confidence**: High
- Change Java version in actions/setup-java step
  - Update step name from "Set up JDK 17" to "Set up JDK 21" in .github/workflows/ci.yml
  - Update java-version parameter from '17' to '21' in .github/workflows/ci.yml

#### 2. Update Docker Configuration
**Confidence**: High
- Change Eclipse Temurin base images from version 17 to 21
  - Update builder stage: FROM eclipse-temurin:17-jdk-alpine to eclipse-temurin:21-jdk-alpine in Dockerfile
  - Update runtime stage: FROM eclipse-temurin:17-jre-alpine to eclipse-temurin:21-jre-alpine in Dockerfile

#### 3. Update Gradle Build Configuration
**Confidence**: High
- Migrate to Java toolchain configuration
  - Remove sourceCompatibility = '17' from build.gradle
  - Remove targetCompatibility = '17' from build.gradle
  - Add java toolchain block with languageVersion = JavaLanguageVersion.of(21) in build.gradle
- Update Gradle wrapper version
  - Change gradleVersion from '8.1' to '8.5' in build.gradle

#### 4. Update Documentation
**Confidence**: High
- Update Java version references in README.md
  - Change "Java 17" to "Java 21" in Technology Stack section
  - Change "Java 17" to "Java 21" in Prerequisites section

## Preconditions Analysis
No specific preconditions required beyond:
- Files exist (.github/workflows/ci.yml, Dockerfile, README.md, build.gradle)
- Project uses Eclipse Temurin distribution
- Project uses Gradle build system

## Potential Automation Challenges
- **Dockerfile transformations**: Not standard Java code, requires text-based or specialized visitor
- **GitHub Actions YAML**: Requires YAML visitor
- **Gradle build.gradle**: Requires Groovy visitor and understanding of toolchain migration pattern
- **README.md**: Documentation file, text-based transformation
- **Version coordination**: All files must be updated together for consistency

## Recommendations for Recipe Mapping
1. Use existing Java migration recipes as foundation if available
2. Compose specific recipes for each file type:
   - YAML visitor for GitHub Actions
   - Text/regex for Dockerfile
   - Groovy visitor for build.gradle with toolchain migration
   - Text/regex for README.md
3. Ensure atomic execution - all changes must succeed together
4. Consider search recipes to identify all Java 17 references before transformation
