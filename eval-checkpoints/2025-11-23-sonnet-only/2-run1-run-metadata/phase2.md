# Phase 2: Intent Analysis

## PR Information
- **URL**: https://github.com/openrewrite-assist-testing-dataset/user-management-service/pull/3
- **Title**: feat: Migrate to JUnit 5, upgrade Gradle and Java version
- **Base Branch**: master
- **PR Branch**: feature/upgrade

## PR Description
This commit includes the following changes:
- Migrates the project from JUnit 4 to JUnit 5
- Upgrades the Gradle version from 6.9 to 7.6.4
- Upgrades the Java version from 11 to 17
- Updates the CI workflow to use Java 17
- Replaces the deprecated `mainClassName` with `mainClass` in the `application` block

## Intent Tree

### Strategic Goal: Upgrade Java 11 to Java 17 with ecosystem modernization
**Confidence**: High
**Type**: Language version upgrade + framework migration + build tool upgrade

#### 1. Upgrade Java version in Gradle
**Confidence**: High

##### 1.1 Migrate to Java toolchain configuration
**Confidence**: High

###### 1.1.1 Remove sourceCompatibility and targetCompatibility from build.gradle
**Confidence**: High
- **File**: build.gradle
- **Lines**: 10-11
- **Change**: Delete `sourceCompatibility = JavaVersion.VERSION_11` and `targetCompatibility = JavaVersion.VERSION_11`

###### 1.1.2 Add Java toolchain section to build.gradle
**Confidence**: High
- **File**: build.gradle
- **Lines**: 10-12
- **Change**: Add `toolchain { languageVersion = JavaLanguageVersion.of(17) }` in java block

#### 2. Upgrade Gradle wrapper version
**Confidence**: High

##### 2.1 Change Gradle distribution version
**Confidence**: High

###### 2.1.1 Update distributionUrl in gradle-wrapper.properties
**Confidence**: High
- **File**: gradle/wrapper/gradle-wrapper.properties
- **Line**: 3
- **Change**: Change from `gradle-6.9-bin.zip` to `gradle-7.6.4-bin.zip`

#### 3. Upgrade Github Actions CI
**Confidence**: High

##### 3.1 Update Java version in CI workflow
**Confidence**: High

###### 3.1.1 Change JDK version in setup-java action
**Confidence**: High
- **File**: .github/workflows/ci.yml
- **Lines**: 9-13
- **Change**: Change job name from "Set up JDK 11" to "Set up JDK 17" and java-version from '11' to '17'

#### 4. Migrate from JUnit 4 to JUnit 5
**Confidence**: High

##### 4.1 Update JUnit dependencies in build.gradle
**Confidence**: High

###### 4.1.1 Replace JUnit 4 dependency with JUnit 5 dependencies
**Confidence**: High
- **File**: build.gradle
- **Lines**: 45-47
- **Change**: Replace `testImplementation 'junit:junit:4.13.2'` with:
  - `testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.1'`
  - `testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.1'`

##### 4.2 Update test configuration in build.gradle
**Confidence**: High

###### 4.2.1 Change test framework from useJUnit to useJUnitPlatform
**Confidence**: High
- **File**: build.gradle
- **Lines**: 67-69
- **Change**: Replace `useJUnit()` with `useJUnitPlatform()`

##### 4.3 Update test code annotations and imports
**Confidence**: High

###### 4.3.1 Replace JUnit 4 imports with JUnit 5 imports in test files
**Confidence**: High
- **File**: src/test/java/com/example/usermanagement/UserResourceTest.java
- **Lines**: 3-4, 7
- **Change**:
  - Replace `org.junit.Before` with `org.junit.jupiter.api.BeforeEach`
  - Replace `org.junit.Test` with `org.junit.jupiter.api.Test`
  - Replace `org.junit.Assert.*` with `org.junit.jupiter.api.Assertions.*`

###### 4.3.2 Replace @Before annotation with @BeforeEach
**Confidence**: High
- **File**: src/test/java/com/example/usermanagement/UserResourceTest.java
- **Line**: 13
- **Change**: Replace `@Before` with `@BeforeEach`

#### 5. Update Gradle plugin versions
**Confidence**: High

##### 5.1 Upgrade Shadow plugin
**Confidence**: High

###### 5.1.1 Update shadow plugin version in build.gradle
**Confidence**: High
- **File**: build.gradle
- **Line**: 4
- **Change**: Change from `version '6.1.0'` to `version '7.1.2'`

#### 6. Fix deprecated Gradle configurations
**Confidence**: High

##### 6.1 Replace deprecated mainClassName with mainClass
**Confidence**: High

###### 6.1.1 Update application block in build.gradle
**Confidence**: High
- **File**: build.gradle
- **Line**: 49
- **Change**: Replace `mainClassName` with `mainClass`

###### 6.1.2 Add mainClassName to shadowJar block for backward compatibility
**Confidence**: High
- **File**: build.gradle
- **Line**: 54
- **Change**: Add `mainClassName = 'com.example.usermanagement.UserManagementApplication'`

## Patterns Identified

### Pattern 1: Complete Java ecosystem upgrade
- Coordinated changes across build.gradle, gradle wrapper, and CI configuration
- All references to Java 11 replaced with Java 17
- Migration to modern Gradle toolchain API

### Pattern 2: JUnit 4 to JUnit 5 migration
- Dependency replacement in build.gradle
- Import statement changes in test files
- Annotation changes (@Before → @BeforeEach, org.junit.Test → org.junit.jupiter.api.Test)
- Assertion class changes (Assert.* → Assertions.*)
- Test runner change (useJUnit() → useJUnitPlatform())

### Pattern 3: Gradle modernization
- Gradle wrapper upgrade to compatible version
- Shadow plugin upgrade
- Deprecated API replacement (mainClassName → mainClass)

## Edge Cases and Exceptions

1. **Shadow plugin backward compatibility**: The PR adds `mainClassName` to shadowJar block even though it's deprecated in the application block, likely for shadow plugin compatibility
2. **Single test file**: Only one test file is modified, suggesting limited test coverage or this is the only test file in the project

## Preconditions Required

1. **Java version precondition**: Should only apply to projects using Java 11
2. **JUnit version precondition**: Should only apply to projects using JUnit 4
3. **Gradle version precondition**: Should only apply to projects using Gradle 6.x
4. **File existence preconditions**:
   - build.gradle must exist
   - gradle/wrapper/gradle-wrapper.properties must exist
   - .github/workflows/ci.yml must exist

## Automation Challenges

1. **Test file patterns**: Need to identify all test files with JUnit 4 annotations across the codebase
2. **Shadow plugin specifics**: The backward compatibility workaround for mainClassName in shadowJar may require special handling
3. **Version coordination**: Multiple version changes need to be coordinated (Java 11→17, Gradle 6.9→7.6.4, JUnit 4→5, Shadow 6.1.0→7.1.2)

## Summary

This PR performs a comprehensive upgrade of the Java ecosystem:
- **Primary intent**: Upgrade from Java 11 to Java 17
- **Secondary intents**: Migrate JUnit 4→5, upgrade Gradle 6.9→7.6.4, upgrade build plugins
- **Scope**: Multi-file transformation affecting build configuration, CI pipeline, and test code
- **Pattern consistency**: High - all Java 11 references are systematically replaced with Java 17
- **Automation potential**: High - clear patterns suitable for OpenRewrite recipes
