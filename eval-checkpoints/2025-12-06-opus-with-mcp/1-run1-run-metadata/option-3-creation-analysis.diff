# Option 3 Creation Analysis

## Objective
Create a refined recipe combining learnings from Option 1 and Option 2 validation results to maximize precision while maintaining coverage of automatable changes.

## Validation Results Summary

| Metric | Option 1 | Option 2 |
|--------|----------|----------|
| Precision | 76.92% | 90.91% |
| Recall | 3.39% | 3.39% |
| True Positives | 10 | 10 |
| False Positives | 3 | 1 |

## Key Learnings Applied

### From Option 1 (Broad Approach)
**Issues identified:**
- `UpgradeToJava17` over-applied to `.github/workflows/ci.yml` (not in PR)
- `UpdateGradleWrapper` added `distributionSha256Sum` (not in PR)
- `UpdateGradleWrapper` updated `gradlew` script (not in PR)
- `UpdateGradleWrapper` updated `gradle-wrapper.jar` (not in PR)

**Decision:** Avoid broad umbrella recipes that touch unrelated files.

### From Option 2 (Targeted Approach)
**Successes:**
- `UpdateJavaCompatibility` precisely updated only build.gradle
- No CI workflow changes (unlike Option 1)
- Higher precision (90.91% vs 76.92%)

**Remaining issues:**
- `UpdateGradleWrapper` still added `distributionSha256Sum`
- Still updated wrapper scripts/binaries

**Decision:** Keep `UpdateJavaCompatibility`, replace `UpdateGradleWrapper` with more precise alternative.

## Option 3 Strategy

### Recipe 1: Java Compatibility (Kept from Option 2)
```yaml
org.openrewrite.gradle.UpdateJavaCompatibility:
  version: 17
  declarationStyle: String
```
- Targeted update of sourceCompatibility/targetCompatibility
- No side effects on other files

### Recipe 2: Gradle Wrapper URL (New Approach)
```yaml
org.openrewrite.properties.ChangePropertyValue:
  propertyKey: distributionUrl
  oldValue: "https\\://services.gradle.org/distributions/gradle-6.7-all.zip"
  newValue: "https\\://services.gradle.org/distributions/gradle-7.6-all.zip"
```
**Why this change:**
- `UpdateGradleWrapper` always adds SHA256 checksum (unavoidable)
- `UpdateGradleWrapper` always updates wrapper scripts/binaries
- `ChangePropertyValue` modifies ONLY the distributionUrl property
- Matches exactly what the PR changed

**Trade-off:** Does not update wrapper binaries, but PR didn't change them either.

### Recipes 3-4: Docker Images (Kept from Both)
```yaml
org.openrewrite.text.FindAndReplace:
  find: "FROM openjdk:11-jdk-slim"
  replace: "FROM eclipse-temurin:17-jdk-alpine"
  filePattern: "**/Dockerfile"
  plaintextOnly: true
```
- Both options had identical Docker changes
- Working correctly, no modifications needed

## Expected Improvements

| Aspect | Option 1 | Option 2 | Option 3 (Expected) |
|--------|----------|----------|---------------------|
| CI workflow changes | Yes (FP) | No | No |
| SHA256 added | Yes (FP) | Yes (FP) | No |
| gradlew updated | Yes (FP) | Yes | No |
| gradle-wrapper.jar updated | Yes (FP) | Yes | No |
| False Positives | 3 | 1 | 0 |

## Files Expected to Change

1. `build.gradle` - sourceCompatibility/targetCompatibility 11 -> 17
2. `gradle/wrapper/gradle-wrapper.properties` - distributionUrl only
3. `Dockerfile` - Both FROM statements

## Files NOT Changed (Matching PR)

- `.github/workflows/ci.yml` - No change (avoided with UpdateJavaCompatibility)
- `gradlew` - No change (avoided with ChangePropertyValue)
- `gradle/wrapper/gradle-wrapper.jar` - No change (avoided with ChangePropertyValue)

## Risk Assessment

**Low Risk:**
- All recipes are well-established OpenRewrite recipes
- Changes are minimal and targeted

**Potential Issue:**
- `ChangePropertyValue` requires exact match of oldValue
- If the existing distributionUrl differs slightly, it won't match

## Conclusion

Option 3 combines:
- Precision of Option 2 (using UpdateJavaCompatibility)
- New approach for Gradle wrapper (using ChangePropertyValue)
- Same Docker image updates (proven effective)

Expected precision: ~100% for automatable changes (3 files, matching PR exactly).
