# Phase 2: Intent Analysis

## PR Information

**PR URL:** https://github.com/openrewrite-assist-testing-dataset/ecommerce-catalog/pull/2
**Title:** Update Dockerfile and Github Actions to Eclipse Temurin 21
**Branch:** feature/dockerfile-temurin-upgrade-pr

## OpenRewrite Best Practices Analysis

Key patterns identified:
- Multi-file transformation across different file types (Java build config, Docker, CI/CD, documentation)
- Language version upgrade intent requiring coordinated changes
- Java toolchain migration pattern (sourceCompatibility → toolchain)
- Gradle wrapper version update needed for Java 21 compatibility

## Intent Extraction

### Strategic Goal
**Upgrade Java runtime from 17 to 21**
- Intent Type: Language Version Upgrade
- Confidence: High
- Scope: Project-wide transformation

### Specific Goals by File Type

#### 1. Upgrade Java version in Gradle build configuration
**Confidence:** High
**Pattern:** Migrate from legacy sourceCompatibility/targetCompatibility to modern toolchain configuration

**Tactical Intents:**
* Migrate to java toolchain configuration
  * Remove `sourceCompatibility = '17'` from build.gradle:11
  * Remove `targetCompatibility = '17'` from build.gradle:12
  * Add java toolchain block with languageVersion set to 21 in build.gradle:11-14
* Upgrade Gradle wrapper version
  * Change gradleVersion from '8.1' to '8.5' in build.gradle:83

#### 2. Upgrade Java version in Docker configuration
**Confidence:** High
**Pattern:** Update base image versions for both build and runtime stages

**Tactical Intents:**
* Update builder stage base image
  * Change FROM eclipse-temurin:17-jdk-alpine to eclipse-temurin:21-jdk-alpine in Dockerfile:2
* Update runtime stage base image
  * Change FROM eclipse-temurin:17-jre-alpine to eclipse-temurin:21-jre-alpine in Dockerfile:18

#### 3. Upgrade Java version in GitHub Actions CI
**Confidence:** High
**Pattern:** Update CI pipeline Java version

**Tactical Intents:**
* Update GitHub Actions Java setup
  * Change step name from "Set up JDK 17" to "Set up JDK 21" in .github/workflows/ci.yml:10
  * Change java-version from '17' to '21' in .github/workflows/ci.yml:13

#### 4. Update documentation
**Confidence:** High
**Pattern:** Reflect runtime requirement changes in documentation

**Tactical Intents:**
* Update technology stack documentation
  * Change "Java 17" to "Java 21" in README.md:19
* Update prerequisites documentation
  * Change "Java 17" to "Java 21" in README.md:143

## Intents Tree

```
* Upgrade Java 17 to Java 21
  * Upgrade Java version in Gradle
    * Migrate to java toolchain configuration
      * Remove sourceCompatibility = '17' from build.gradle
      * Remove targetCompatibility = '17' from build.gradle
      * Add java toolchain block with languageVersion = JavaLanguageVersion.of(21)
    * Upgrade Gradle wrapper version
      * Change gradleVersion from '8.1' to '8.5' in build.gradle
  * Upgrade Java version in Docker
    * Update builder stage base image from eclipse-temurin:17-jdk-alpine to eclipse-temurin:21-jdk-alpine
    * Update runtime stage base image from eclipse-temurin:17-jre-alpine to eclipse-temurin:21-jre-alpine
  * Upgrade Java version in GitHub Actions
    * Change step name from "Set up JDK 17" to "Set up JDK 21"
    * Change java-version parameter from '17' to '21'
  * Update documentation
    * Change Technology Stack Java version from 17 to 21 in README.md
    * Change Prerequisites Java version from 17 to 21 in README.md
```

## Transformation Patterns

### Pattern 1: Version Number Replacement
- Type: Simple text replacement
- Occurrences: Multiple files (build.gradle, Dockerfile, ci.yml, README.md)
- From: "17" (in Java context)
- To: "21"

### Pattern 2: Gradle Build Configuration Modernization
- Type: Structural transformation
- Scope: build.gradle
- From: Legacy sourceCompatibility/targetCompatibility
- To: Modern java toolchain DSL

### Pattern 3: Gradle Wrapper Version Update
- Type: Version upgrade
- Scope: build.gradle wrapper configuration
- From: 8.1
- To: 8.5
- Rationale: Java 21 support requires Gradle 8.5+

## Edge Cases and Exceptions

None identified. All changes follow consistent patterns with no manual adjustments or deviations.

## Potential Challenges for Automation

1. **Gradle wrapper version coordination**: Recipe must ensure Gradle version is compatible with target Java version
2. **Multi-file coordination**: Changes must be applied atomically across 4 different file types (Gradle, Dockerfile, YAML, Markdown)
3. **Documentation updates**: Text replacements in documentation must be context-aware to avoid unintended changes
4. **Build configuration structural change**: Migration from sourceCompatibility/targetCompatibility to toolchain requires AST manipulation, not simple text replacement

## Success Criteria

- All Java version references updated from 17 to 21
- Gradle build configuration migrated to toolchain syntax
- Gradle wrapper version updated to support Java 21
- Docker images use Java 21 base images
- CI pipeline configured for Java 21
- Documentation reflects updated requirements
