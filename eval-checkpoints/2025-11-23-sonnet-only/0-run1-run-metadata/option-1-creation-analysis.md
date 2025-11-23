# Option 1: Broad Recipe Approach - Analysis

## Strategy
Use org.openrewrite.java.migrate.UpgradeToJava21 as primary recipe with targeted gap-filling for items not covered.

## Intent Categorization

**Java Version Upgrade**: Java 17 → Java 21
**Build System**: Gradle toolchain migration, wrapper update
**Infrastructure**: Docker image updates
**CI/CD**: GitHub Actions Java version
**Documentation**: README updates

## Recipe Discovery & Mapping

### Primary Recipe: org.openrewrite.java.migrate.UpgradeToJava21

**Recipe Type**: Composite recipe from rewrite-migrate-java

**What It Covers**:
- Migrates to Java 17 first (org.openrewrite.java.migrate.UpgradeToJava17)
- Updates build files via org.openrewrite.java.migrate.UpgradeBuildToJava21
- Updates GitHub Actions java-version via org.openrewrite.github.SetupJavaUpgradeJavaVersion
- Replaces deprecated APIs (Thread.stop, URL constructor, Runtime.exec)
- Adopts Java 21 features (SequencedCollection, Locale.of, switch expressions)
- Upgrades plugins to Java 21-compatible versions

**Coverage**: ~60% of required transformations

### Identified Gaps

**Gap 1: Gradle Wrapper Update**
- Required: 8.1 → 8.5
- UpgradeToJava21 does NOT include UpdateGradleWrapper
- Solution: org.openrewrite.gradle.UpdateGradleWrapper with version: 8.5

**Gap 2: Toolchain Structure Migration**
- Required: Remove sourceCompatibility/targetCompatibility, add toolchain block
- UpgradeBuildToJava21 calls org.openrewrite.gradle.UpdateJavaCompatibility which only updates VERSION NUMBERS, not structure
- Solution: org.openrewrite.text.FindAndReplace for structural change
- Note: Text-based recipe breaks LST - placed after semantic recipes

**Gap 3: Docker Image Updates**
- Required: eclipse-temurin:17 → eclipse-temurin:21 (both JDK and JRE)
- No semantic Docker parser available in OpenRewrite
- Solution: org.openrewrite.text.FindAndReplace for both FROM statements

**Gap 4: GitHub Actions Step Name**
- Required: "Set up JDK 17" → "Set up JDK 21"
- SetupJavaUpgradeJavaVersion only updates java-version parameter, NOT step name
- Solution: org.openrewrite.text.FindAndReplace for step name

**Gap 5: README Documentation**
- Required: Update Java 17 → Java 21, Gradle 8.1 → 8.5
- No documentation-specific recipe exists
- Solution: org.openrewrite.text.FindAndReplace (2 separate replacements)

## Composition Strategy: Layered Approach

**Layer 1: Semantic Comprehensive Migration**
- org.openrewrite.java.migrate.UpgradeToJava21 (handles Java code, build version numbers, GitHub Actions java-version)

**Layer 2: Build System Gaps**
- org.openrewrite.gradle.UpdateGradleWrapper (semantic, LST-based)

**Layer 3: Text-Based Structural Changes**
- FindAndReplace for toolchain migration (build.gradle)
- FindAndReplace for Docker images (Dockerfile)
- FindAndReplace for GitHub Actions step name (YAML)
- FindAndReplace for README updates (Markdown)

## Recipe Ordering Rationale

1. UpgradeToJava21 FIRST - semantic LST-based transformations
2. UpdateGradleWrapper SECOND - still LST-based
3. FindAndReplace recipes LAST - break LST capability

## Trade-offs

**Advantages**:
- Simple primary recipe covers Java code changes, API migrations
- Benefits from OpenRewrite's curated migration knowledge
- Future-proof for additional Java 21 features/deprecations
- Automatic plugin compatibility upgrades

**Disadvantages**:
- May apply unwanted code transformations (switch expressions, pattern matching)
- Heavy reliance on text-based recipes for infrastructure gaps
- Text recipes are brittle (exact string matching)
- Loss of LST after text recipes prevents further semantic work

## Validation Recommendations

- Verify toolchain block replaces sourceCompatibility/targetCompatibility correctly
- Check Docker multi-stage build image consistency
- Confirm GitHub Actions step name update
- Review switch expression conversions for code readability
- Test with Gradle 8.5 wrapper

## Alternative Considerations

If org.openrewrite.java.migrate.UpgradeToJava21 applies excessive code transformations, consider Option 2's surgical approach.
