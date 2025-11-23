# Phase 2: Intent Analysis

## PR Information
- **URL**: https://github.com/openrewrite-assist-testing-dataset/weather-monitoring-service/pull/3
- **Title**: Upgrade to Java 17 with full compatibility
- **Base Branch**: master
- **PR Branch**: feature/java-17-upgrade-pr

## OpenRewrite Key Insights
- LST preserves formatting and comments during transformations
- Recipe composition should layer: foundation → refinement → cleanup
- Use language-specific visitors for different file types
- Preconditions can limit recipe application scope
- Search recipes are non-modifying and useful for validation

## PR Analysis

### Code Change Patterns
The PR contains two distinct groups of changes:

1. **Java version upgrade** (files: build.gradle, Dockerfile, gradle-wrapper.properties)
2. **Authentication simplification** (files: WeatherApiApplication.java, auth package)

The authentication changes are manual refactoring unrelated to Java 17 upgrade. The Java version changes are systematic.

## Intent Tree

### Strategic Intent: Upgrade Java 11 to Java 17
**Confidence**: High (directly stated in PR title and description)

#### 1. Upgrade Java version in Gradle build configuration
**Confidence**: High (direct pattern)
**Recipe Type**: Gradle/Java configuration

##### 1.1 Change Java compatibility version from 11 to 17
- **File**: build.gradle
- **Pattern**: `sourceCompatibility = '11'` → `sourceCompatibility = '17'`
- **Pattern**: `targetCompatibility = '11'` → `targetCompatibility = '17'`
- **Confidence**: High

#### 2. Upgrade Gradle wrapper version
**Confidence**: High (necessary for Java 17 support)
**Recipe Type**: Gradle wrapper

##### 2.1 Change Gradle distribution version from 6.7 to 7.6
- **File**: gradle/wrapper/gradle-wrapper.properties
- **Pattern**: Replace `distributionUrl=https\://services.gradle.org/distributions/gradle-6.7-all.zip` with `gradle-7.6-all.zip`
- **Confidence**: High

#### 3. Upgrade Docker base images to Java 17
**Confidence**: High (systematic pattern)
**Recipe Type**: Dockerfile

##### 3.1 Change builder base image from OpenJDK 11 to Eclipse Temurin 17
- **File**: Dockerfile
- **Pattern**: `FROM openjdk:11-jdk-slim` → `FROM eclipse-temurin:17-jdk-alpine`
- **Confidence**: High

##### 3.2 Change runtime base image from OpenJDK 11 to Eclipse Temurin 17
- **File**: Dockerfile
- **Pattern**: `FROM openjdk:11-jre-slim` → `FROM eclipse-temurin:17-jre-alpine`
- **Confidence**: High

### Strategic Intent: Simplify Dropwizard Authentication
**Confidence**: High (stated in PR description)
**Note**: This is NOT related to Java 17 upgrade - it's manual application refactoring

#### 1. Replace custom auth filters with standard BasicCredentialAuthFilter
**Confidence**: High
**Recipe Type**: Java refactoring

##### 1.1 Delete deprecated custom auth filter classes
- **Files**: JwtAuthFilter.java, ApiKeyAuthFilter.java, JwtAuthenticator.java (deleted)
- **Confidence**: High

##### 1.2 Modify ApiKeyAuthenticator to use BasicCredentials
- **File**: ApiKeyAuthenticator.java
- **Pattern**: `implements Authenticator<String, User>` → `implements Authenticator<BasicCredentials, User>`
- **Pattern**: `authenticate(String apiKey)` → `authenticate(BasicCredentials credentials)`
- **Pattern**: Add logic to extract username from BasicCredentials
- **Confidence**: High

##### 1.3 Add type field to User class
- **File**: User.java
- **Pattern**: Add `private final String type;` field
- **Pattern**: Update constructor to accept type parameter
- **Pattern**: Remove equals/hashCode, replace with toString
- **Confidence**: High

##### 1.4 Update WeatherApiApplication to use BasicCredentialAuthFilter
- **File**: WeatherApiApplication.java
- **Pattern**: Remove ChainedAuthFilter setup with JWT and ApiKey filters
- **Pattern**: Add BasicCredentialAuthFilter.Builder setup
- **Confidence**: High

##### 1.5 Update test classes
- **File**: ApiKeyAuthenticatorTest.java (modified), JwtAuthenticatorTest.java (deleted)
- **Pattern**: Replace String parameters with BasicCredentials instances
- **Confidence**: High

## Patterns and Exceptions

### Java 17 Upgrade Patterns
- **Systematic**: All Java version references changed from 11 to 17
- **Gradle**: Minimum version 7.x required for Java 17 support
- **Docker**: Eclipse Temurin chosen over OpenJDK (modern best practice)
- **Alpine variant**: Changed from slim to alpine for smaller image size

### Authentication Refactoring Patterns
- **Manual**: No systematic pattern - custom application logic changes
- **Framework-specific**: Dropwizard-specific authentication patterns
- **Not automatable**: Business logic decisions about which auth methods to support

## Automation Challenges

### Java 17 Upgrade (Automatable)
- Gradle version compatibility checking
- Docker base image selection (multiple valid options)
- Ensuring all Java version references are updated

### Authentication Refactoring (Not Automatable)
- Requires business decisions about authentication strategy
- Custom filter implementation logic
- Test case adjustments based on new implementation
- This is application-specific refactoring, not a migration pattern

## Recipe Mapping Recommendations

Based on OpenRewrite best practices, focus on **Java 17 upgrade only**:

1. **Search for existing recipes**:
   - Java 11 → 17 migration recipes
   - Gradle wrapper upgrade recipes
   - Dockerfile Java version update recipes

2. **Likely needed recipes**:
   - ChangeGradleJavaLanguageVersion (sourceCompatibility/targetCompatibility)
   - UpdateGradleWrapper (version upgrade)
   - Custom recipe for Dockerfile base image updates

3. **Not suitable for recipes**:
   - Authentication refactoring (application-specific, requires business logic decisions)
