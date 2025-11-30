# Intent Tree

## Strategic Goal: Upgrade Java 11 to Java 17 and simplify authentication framework

### 1. Upgrade Java version from 11 to 17
#### 1.1 Upgrade Java version in Gradle build configuration
##### 1.1.1 Change sourceCompatibility and targetCompatibility
- Change `sourceCompatibility = '11'` to `sourceCompatibility = '17'` in build.gradle:29
- Change `targetCompatibility = '11'` to `targetCompatibility = '17'` in build.gradle:30

#### 1.2 Upgrade Gradle wrapper version for Java 17 compatibility
##### 1.2.1 Update Gradle wrapper properties
- Change distributionUrl from `gradle-6.7-all.zip` to `gradle-7.6-all.zip` in gradle/wrapper/gradle-wrapper.properties:43

#### 1.3 Upgrade Docker base images to Java 17
##### 1.3.1 Update builder stage base image
- Change `FROM openjdk:11-jdk-slim` to `FROM eclipse-temurin:17-jdk-alpine` in Dockerfile:7

##### 1.3.2 Update runtime stage base image
- Change `FROM openjdk:11-jre-slim` to `FROM eclipse-temurin:17-jre-alpine` in Dockerfile:17

### 2. Simplify authentication by removing JWT and consolidating on BasicCredentialAuthFilter
#### 2.1 Remove JWT authentication implementation
##### 2.1.1 Delete JWT filter class
- Delete file weather-api/src/main/java/com/weather/api/auth/JwtAuthFilter.java

##### 2.1.2 Delete JWT authenticator class
- Delete file weather-api/src/main/java/com/weather/api/auth/JwtAuthenticator.java

##### 2.1.3 Delete JWT authenticator test
- Delete file weather-api/src/test/java/com/weather/api/auth/JwtAuthenticatorTest.java

#### 2.2 Remove custom API key filter implementation
##### 2.2.1 Delete custom API key filter class
- Delete file weather-api/src/main/java/com/weather/api/auth/ApiKeyAuthFilter.java

#### 2.3 Migrate to Dropwizard BasicCredentialAuthFilter
##### 2.3.1 Update WeatherApiApplication imports
- Remove import: `com.weather.api.auth.JwtAuthFilter` (line 56)
- Remove import: `com.weather.api.auth.ApiKeyAuthFilter` (line 57)
- Add import: `com.weather.api.auth.User` (line 58)
- Remove import: `io.dropwizard.auth.chained.ChainedAuthFilter` (line 63)
- Remove import: `javax.ws.rs.container.ContainerRequestFilter` (line 69)
- Remove import: `java.util.List` (line 70)

##### 2.3.2 Replace authentication setup in WeatherApiApplication.run()
- Remove whitespace-only line at line 79
- Remove JWT filter creation code (lines 82-87)
- Remove API key filter creation code (lines 89-93)
- Remove ChainedAuthFilter creation code (lines 95-96)
- Remove ChainedAuthFilter registration (line 98)
- Add BasicCredentialAuthFilter setup with comment (lines 95-99)
- Update AuthValueFactoryProvider.Binder to use `User.class` instead of `com.weather.api.auth.User.class` (line 101)
- Remove whitespace inconsistencies (lines 81, 107, 110)

#### 2.4 Update ApiKeyAuthenticator to use BasicCredentials
##### 2.4.1 Update ApiKeyAuthenticator class signature and imports
- Add import: `io.dropwizard.auth.basic.BasicCredentials` (line 176)
- Change class declaration from `implements Authenticator<String, User>` to `implements Authenticator<BasicCredentials, User>` (line 182)

##### 2.4.2 Update authenticate method
- Change method signature from `authenticate(String apiKey)` to `authenticate(BasicCredentials credentials)` (lines 190-193)
- Extract username from BasicCredentials and use as API key (lines 194-196)
- Update User instantiation to include both username and "api-key" type parameter (line 197)

#### 2.5 Update User class to include authentication type
##### 2.5.1 Add type field and update constructor
- Add `type` field (line 318)
- Update constructor to accept both name and type parameters (line 321-323)

##### 2.5.2 Add getter and update toString
- Add `getType()` method (lines 337-339)
- Replace `equals()` and `hashCode()` methods with `toString()` method (lines 341-348)
- Remove newline at end of file (line 351)

#### 2.6 Update ApiKeyAuthenticator tests
##### 2.6.1 Update test imports
- Add import: `io.dropwizard.auth.basic.BasicCredentials` (line 360)

##### 2.6.2 Update test method implementations
- Replace String API keys with BasicCredentials in all test methods (lines 368-421)
- Update assertion for user name to check for "key1" instead of "api-user" (line 378)
- Add assertion for user type "api-key" (line 379)
- Update test comments for null handling (line 400)
