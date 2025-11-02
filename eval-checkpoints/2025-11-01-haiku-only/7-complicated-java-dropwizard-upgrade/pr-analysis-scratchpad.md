# PR Analysis: Upgrade to Java 21 and Dropwizard 4.0.5

## PR Information
- **Repository**: openrewrite-assist-testing-dataset/notification-service
- **PR Number**: #2
- **PR Title**: feat: Upgrade project to Java 21 and Dropwizard 4.0.5
- **Author**: glebmish
- **PR Description**: (Empty)
- **Files Changed**: 16
- **Additions**: +108 lines
- **Deletions**: -109 lines

## Changed Files Summary

### Build and Configuration Files (7 files)

1. **build.gradle** (+32/-34)
   - Removed JCenter repository (deprecated)
   - Changed Java compatibility from 11 to 21 using Java toolchain
   - Upgraded Dropwizard from 2.1.7 to 4.0.5
   - Added new Dropwizard modules (db, migrations)
   - Updated major dependencies for Java 21 compatibility
   - Removed wrapper configuration block

2. **gradle/wrapper/gradle-wrapper.properties** (+4/-2)
   - Upgraded Gradle from 7.6 to 8.5
   - Added network timeout and distribution URL validation

3. **gradle/wrapper/gradle-wrapper.jar** (binary file updated)

4. **gradlew** (+5/-7)
   - Updated Gradle wrapper script for version 8.5

5. **gradlew.bat** (+12/-14)
   - Updated Windows Gradle wrapper script

6. **.github/workflows/ci.yml** (+2/-2)
   - Updated GitHub Actions to use JDK 21 instead of JDK 11

7. **Dockerfile** (+12/-9)
   - Changed base image from openjdk:11 to eclipse-temurin:21
   - Updated Alpine-based runtime image
   - Fixed user creation for Alpine Linux (added shadow package)
   - Changed healthcheck from curl to wget

### Source Code Files (9 files)

8. **notification-api/build.gradle** (+4/-4)
   - Updated Dropwizard dependencies to 4.0.5
   - Updated java-jwt from 4.2.1 to 4.4.0

9. **common/src/main/java/com/notification/common/model/NotificationMessage.java** (+3/-3)
   - Migrated from javax.validation to jakarta.validation annotations
   - Changed imports: @NotNull, @Email, @Size

10. **notification-api/src/main/java/com/notification/api/NotificationApiApplication.java** (+4/-4)
    - Migrated from io.dropwizard to io.dropwizard.core package
    - Migrated from javax.ws.rs to jakarta.ws.rs

11. **notification-api/src/main/java/com/notification/api/auth/ApiKeyAuthFilter.java** (+5/-5)
    - Migrated from javax.annotation to jakarta.annotation
    - Migrated from javax.ws.rs to jakarta.ws.rs

12. **notification-api/src/main/java/com/notification/api/auth/JwtAuthFilter.java** (+7/-7)
    - Migrated from javax.annotation to jakarta.annotation
    - Migrated from javax.ws.rs to jakarta.ws.rs

13. **notification-api/src/main/java/com/notification/api/config/NotificationApiConfiguration.java** (+3/-3)
    - Migrated from io.dropwizard to io.dropwizard.core
    - Migrated from javax.validation to jakarta.validation

14. **notification-api/src/main/java/com/notification/api/resources/BatchResource.java** (+7/-7)
    - Migrated from javax.validation to jakarta.validation
    - Migrated from javax.ws.rs to jakarta.ws.rs

15. **notification-api/src/main/java/com/notification/api/resources/NotificationResource.java** (+7/-7)
    - Migrated from javax.validation to jakarta.validation
    - Migrated from javax.ws.rs to jakarta.ws.rs

16. **notification-api/src/test/java/com/notification/api/resources/NotificationResourceTest.java** (+1/-1)
    - Migrated from javax.ws.rs to jakarta.ws.rs

## Type of Changes

**Major Version Upgrade / Migration**

This is a comprehensive upgrade that includes:
- Java version upgrade: 11 → 21
- Dropwizard framework upgrade: 2.1.7 → 4.0.5
- Gradle upgrade: 7.6 → 8.5
- Jakarta EE migration (javax.* → jakarta.*)
- Dependency updates for compatibility

## Key Transformation Details

### 1. Java Version Migration
- **From**: Java 11
- **To**: Java 21
- **Method**: Using Java toolchain in Gradle
- **Impact**: All build tools, Docker images, and CI/CD updated

### 2. Dropwizard Framework Upgrade
- **From**: 2.1.7 (compatible with Java 11, Jakarta EE 8)
- **To**: 4.0.5 (requires Java 21, Jakarta EE 9+)
- **Breaking Changes**:
  - Package structure change: `io.dropwizard` → `io.dropwizard.core` for core classes
  - New modules added: dropwizard-db, dropwizard-migrations

### 3. Jakarta EE Migration (javax → jakarta)
This is the most significant code change, affecting:
- **javax.validation** → **jakarta.validation** (Bean Validation)
- **javax.ws.rs** → **jakarta.ws.rs** (JAX-RS)
- **javax.annotation** → **jakarta.annotation** (Common Annotations)
- **javax.mail** → **jakarta.mail** (Mail API)

Implementation changes:
- Mail: `javax.mail-api` + `com.sun.mail:javax.mail` → `jakarta.mail-api` + `org.eclipse.angus:angus-mail`

### 4. Dependency Updates

**Major upgrades**:
- Guava: 21.0 → 33.0.0-jre
- Jackson: 2.12.7 → 2.16.1
- Hibernate Validator: 6.2.5.Final → 8.0.1.Final
- Apache Commons Lang3: 3.12.0 → 3.14.0
- Apache HttpClient: 4.x → 5.3.1 (httpclient5)
- Twilio SDK: 8.31.1 → 10.0.0
- Slack API: 1.27.3 → 1.34.0
- Jedis: 4.3.1 → 5.1.2
- JUnit: 5.9.2 → 5.10.1
- Mockito: 4.11.0 → 5.9.0
- H2 Database: 2.1.214 → 2.2.224
- java-jwt: 4.2.1 → 4.4.0

**Removed**:
- Log4j dependencies (likely using Logback via Dropwizard defaults)

### 5. Build System Changes
- Removed deprecated JCenter repository
- Gradle wrapper upgraded to 8.5
- Added distribution URL validation
- Java toolchain configuration for consistent JDK usage

### 6. Infrastructure Changes
- Docker base images: openjdk:11 → eclipse-temurin:21 (Alpine-based)
- Alpine Linux compatibility fixes (shadow package for user management)
- Healthcheck: curl → wget (more common in Alpine)

## OpenRewrite Recipe Opportunities

This PR represents transformations that could be automated with OpenRewrite recipes:

1. **Java 21 Migration Recipe** - Update Java version in build files
2. **Dropwizard 2.x to 4.x Migration Recipe** - Handle package restructuring
3. **Jakarta EE 9 Migration Recipe** - javax.* to jakarta.* namespace changes
4. **Dependency Version Upgrade Recipes** - Systematic dependency updates
5. **Gradle 8.x Migration Recipe** - Update Gradle wrapper and configuration
6. **HttpClient 4 to 5 Migration Recipe** - Apache HttpComponents upgrade

## Pattern Analysis

The most systematic transformation pattern in this PR is:
- **Package namespace migration**: All imports from `javax.*` packages to `jakarta.*` packages
- **Consistency**: Applied uniformly across all affected files
- **Scope**: Affects validation, JAX-RS, and common annotations APIs
