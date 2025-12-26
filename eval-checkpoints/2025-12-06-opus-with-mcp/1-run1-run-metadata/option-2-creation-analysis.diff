# Option 2: Targeted/Narrow Approach Analysis

## Recipe Selection Summary

| Intent | Recipe | Semantic? | Rationale |
|--------|--------|-----------|-----------|
| Java 11->17 in Gradle | `org.openrewrite.gradle.UpdateJavaCompatibility` | Yes | Understands Gradle DSL structure, handles sourceCompatibility/targetCompatibility |
| Gradle wrapper 6.7->7.6 | `org.openrewrite.gradle.UpdateGradleWrapper` | Yes | Parses gradle-wrapper.properties, manages version semantically |
| Docker builder image | `org.openrewrite.text.FindAndReplace` | No | No Docker-specific recipe exists for image replacement |
| Docker runtime image | `org.openrewrite.text.FindAndReplace` | No | No Docker-specific recipe exists for image replacement |

## Recipe-to-PR-Change Mapping

### 1. org.openrewrite.gradle.UpdateJavaCompatibility
- **PR Change**: `build.gradle:29-30` - Change `sourceCompatibility = '11'` and `targetCompatibility = '11'` to `'17'`
- **Configuration**: `version: 17`, `declarationStyle: String`
- **Why semantic**: Recipe understands Gradle DSL, handles both source and target compatibility, preserves declaration style (String quotes)

### 2. org.openrewrite.gradle.UpdateGradleWrapper
- **PR Change**: `gradle/wrapper/gradle-wrapper.properties:3` - Change `gradle-6.7-all.zip` to `gradle-7.6-all.zip`
- **Configuration**: `version: "7.6"`, `distribution: all`
- **Why semantic**: Recipe parses properties file structure, updates distributionUrl correctly, can add SHA256 checksum

### 3-4. org.openrewrite.text.FindAndReplace (Docker images)
- **PR Changes**:
  - `Dockerfile:2`: `FROM openjdk:11-jdk-slim` -> `FROM eclipse-temurin:17-jdk-alpine`
  - `Dockerfile:17`: `FROM openjdk:11-jre-slim` -> `FROM eclipse-temurin:17-jre-alpine`
- **Why text-based**: OpenRewrite lacks semantic Dockerfile parsing for image replacement
- **Risk**: Low - exact string match reduces false positives

## Coverage Analysis

### Covered (High Confidence)
- [x] Java version in Gradle (100%)
- [x] Gradle wrapper version (100%)
- [x] Docker base images (100%)

### Not Covered (Medium/Low Confidence - Out of Scope)
- [ ] Authentication refactoring (ChainedAuthFilter -> BasicCredentialAuthFilter)
- [ ] User class modification (add type field, change constructor)
- [ ] File deletions (JwtAuthFilter, JwtAuthenticator, ApiKeyAuthFilter)
- [ ] Test updates

## Precision vs Coverage Trade-offs

**Precision**: HIGH
- Each recipe targets exactly one type of change
- No unnecessary transformations
- Easy to validate each step

**Coverage**: ~40% of PR changes
- Focuses only on high-confidence, infrastructure changes
- Excludes application-specific refactoring

## Gap Analysis

### True Gaps (No Recipe Exists)
1. **Docker image replacement** - Used text-based fallback
2. **Authentication architecture refactoring** - Application-specific, not automatable
3. **Java class modifications** - Too specific to this codebase

### Alternative Considered
- `org.openrewrite.docker.search.FindDockerImageUses` - Only finds, doesn't replace
- No `org.openrewrite.docker.ChangeDockerImage` or similar exists

## Execution Notes

1. Recipe order is intentional - semantic recipes before text-based
2. Text-based Dockerfile changes use `plaintextOnly: true` to avoid LST conversion issues
3. Gradle wrapper recipe may add `distributionSha256Sum` (acceptable side effect)
