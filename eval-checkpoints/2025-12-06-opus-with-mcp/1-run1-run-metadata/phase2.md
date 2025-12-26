# Phase 2: Intent Extraction

## PR Summary
- **Title**: Upgrade to Java 17 with full compatibility
- **URL**: https://github.com/openrewrite-assist-testing-dataset/weather-monitoring-service/pull/3

## Extracted Intents

### High Confidence (Automatable)
1. **Java 11 → 17 upgrade in Gradle**: sourceCompatibility/targetCompatibility changes
2. **Gradle wrapper 6.7 → 7.6**: distributionUrl update
3. **Docker image migration**: openjdk:11 → eclipse-temurin:17 (both JDK and JRE variants)

### Medium Confidence (Partially Automatable)
4. **Authentication simplification**: ChainedAuthFilter → BasicCredentialAuthFilter
   - File deletions (JwtAuthFilter, JwtAuthenticator, ApiKeyAuthFilter)
   - ApiKeyAuthenticator refactor (String → BasicCredentials)

### Low Confidence (Manual/Custom)
5. **User class modification**: Added type field, changed constructor signature
6. **Test updates**: Aligned with new authentication API

## Files Changed
- `Dockerfile` (2 changes)
- `build.gradle` (1 change)
- `gradle/wrapper/gradle-wrapper.properties` (1 change)
- `WeatherApiApplication.java` (major refactor)
- `ApiKeyAuthenticator.java` (API change)
- `User.java` (class modification)
- `ApiKeyAuthenticatorTest.java` (test update)

## Files Deleted
- `JwtAuthFilter.java`
- `JwtAuthenticator.java`
- `ApiKeyAuthFilter.java`
- `JwtAuthenticatorTest.java`

## Recipe Mapping Notes
- Standard Java migration recipes available for build config
- Docker changes may need PlainText recipes
- Auth refactoring is too application-specific for generic recipes

## Status
Phase 2 completed. Intent tree saved to `intent-tree.md`.
