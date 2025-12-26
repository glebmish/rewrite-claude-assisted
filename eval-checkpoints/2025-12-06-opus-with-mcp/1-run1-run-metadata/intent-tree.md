# Intent Tree - PR #3

## Strategic Intent: Upgrade Java 11 to Java 17 with Authentication Simplification

### 1. Java Version Upgrade (High Confidence)
* Upgrade Java language version from 11 to 17
  * Update Gradle build configuration
    * Change sourceCompatibility from '11' to '17' in build.gradle:29
    * Change targetCompatibility from '11' to '17' in build.gradle:30
  * Upgrade Gradle wrapper version
    * Change distributionUrl from gradle-6.7-all.zip to gradle-7.6-all.zip in gradle/wrapper/gradle-wrapper.properties:3

### 2. Docker Base Image Update (High Confidence)
* Update Docker images to Eclipse Temurin 17
  * Change builder stage base image
    * Replace openjdk:11-jdk-slim with eclipse-temurin:17-jdk-alpine in Dockerfile:2
  * Change runtime stage base image
    * Replace openjdk:11-jre-slim with eclipse-temurin:17-jre-alpine in Dockerfile:17

### 3. Authentication Refactoring (Medium Confidence - Complex Changes)
* Simplify authentication from ChainedAuthFilter to BasicCredentialAuthFilter
  * Remove JWT authentication support
    * Delete JwtAuthFilter.java (weather-api/src/main/java/com/weather/api/auth/JwtAuthFilter.java)
    * Delete JwtAuthenticator.java (weather-api/src/main/java/com/weather/api/auth/JwtAuthenticator.java)
    * Delete JwtAuthenticatorTest.java (weather-api/src/test/java/com/weather/api/auth/JwtAuthenticatorTest.java)
  * Remove custom ApiKeyAuthFilter
    * Delete ApiKeyAuthFilter.java (weather-api/src/main/java/com/weather/api/auth/ApiKeyAuthFilter.java)
  * Refactor ApiKeyAuthenticator to use BasicCredentials
    * Change Authenticator<String, User> to Authenticator<BasicCredentials, User> in ApiKeyAuthenticator.java:10
    * Add import for io.dropwizard.auth.basic.BasicCredentials
    * Change authenticate(String apiKey) to authenticate(BasicCredentials credentials)
    * Extract username from BasicCredentials as API key
    * Update User construction to include type parameter
  * Modify User class
    * Add 'type' field to User class
    * Change constructor from User(String name) to User(String name, String type)
    * Add getType() method
    * Replace equals/hashCode with toString method
  * Update WeatherApiApplication authentication setup
    * Remove ChainedAuthFilter usage
    * Remove JwtAuthFilter creation
    * Remove ApiKeyAuthFilter creation
    * Add BasicCredentialAuthFilter.Builder configuration
    * Simplify import statements (remove JwtAuthFilter, ApiKeyAuthFilter, ChainedAuthFilter, ContainerRequestFilter, List)
    * Add import for User class
  * Update ApiKeyAuthenticatorTest
    * Change test inputs from String to BasicCredentials
    * Update assertions for new User fields

## Patterns Identified

### Repeatable Patterns (Suitable for OpenRewrite)
1. Java version upgrade in Gradle (sourceCompatibility/targetCompatibility)
2. Gradle wrapper version upgrade
3. Docker base image replacement (openjdk → eclipse-temurin)

### Non-Repeatable/Complex Patterns (Low OpenRewrite Coverage)
1. Authentication architecture refactoring (ChainedAuthFilter → BasicCredentialAuthFilter)
2. Class modification (adding fields, changing constructors)
3. Test refactoring for new API

## Automation Challenges
- Authentication refactoring is highly application-specific
- User class modification requires understanding of existing usage
- Test updates are tightly coupled to implementation changes

## Confidence Levels
- **High**: Java/Gradle/Docker version changes - standard migration patterns
- **Medium**: Authentication changes - framework-specific but complex
- **Low**: User class refactoring - custom business logic changes
