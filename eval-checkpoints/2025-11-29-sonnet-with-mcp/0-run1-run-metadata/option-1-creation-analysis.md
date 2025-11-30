# Option 1 Recipe Analysis: Comprehensive Approach

## Strategy
This recipe uses a BROAD/GENERAL approach, leveraging comprehensive migration recipes that handle multiple aspects of the Java 21 upgrade automatically.

## Core Recipe Selection

### Primary Recipe: org.openrewrite.java.migrate.UpgradeToJava21
**Coverage**: ~70% of required changes

**Why this recipe**:
- Official OpenRewrite recipe specifically designed for Java 21 migrations
- Handles Java version upgrades in build files through its sub-recipes
- Already includes `org.openrewrite.github.SetupJavaUpgradeJavaVersion` for GitHub Actions java-version updates
- Updates deprecated APIs and applies Java 21 language features
- Upgrades plugins to Java 21 compatible versions

**What it covers from intent tree**:
- Migrate to java toolchain configuration (via UpgradeJavaVersion)
- Remove sourceCompatibility/targetCompatibility (via UpdateJavaCompatibility)
- Add java toolchain section with JavaLanguageVersion.of(21)
- Change java-version from '17' to '21' in actions/setup-java (via SetupJavaUpgradeJavaVersion)

**What it DOESN'T cover**:
- GitHub Actions step name changes (not part of semantic recipe)
- Gradle wrapper version updates
- Docker image version updates
- README documentation updates

## Gap-Filling Recipes

### 1. Gradle Wrapper Update
**Recipe**: `org.openrewrite.gradle.UpdateGradleWrapper`
- **Parameters**: version: 8.5
- **Why needed**: UpgradeToJava21 focuses on Java version in build configuration, not the wrapper itself
- **Semantic approach**: Uses Gradle-aware recipe that understands wrapper properties structure

### 2. Docker Base Image Updates
**Recipe**: `org.openrewrite.text.FindAndReplace` (2 instances)
- **Why text replacement**: No semantic Docker recipe exists for image version updates
- **Justification**: Docker FROM statements are simple text patterns without complex structure
- **Alternative considered**: org.kubernetes.UpdateContainerImageName exists but is for Kubernetes manifests, not Dockerfiles
- **Coverage**:
  - Builder stage: eclipse-temurin:17-jdk-alpine → eclipse-temurin:21-jdk-alpine
  - Runtime stage: eclipse-temurin:17-jre-alpine → eclipse-temurin:21-jre-alpine

### 3. GitHub Actions Step Name
**Recipe**: `org.openrewrite.text.FindAndReplace`
- **Why text replacement**: Step names are YAML string values, no semantic recipe for this specific change
- **Alternative considered**: org.openrewrite.yaml.ChangePropertyValue doesn't work for nested YAML structures like step names within arrays
- **Pattern**: "Set up JDK 17" → "Set up JDK 21"

### 4. README Documentation Updates
**Recipe**: `org.openrewrite.text.FindAndReplace` (2 instances)
- **Why text replacement**: Markdown content changes have no semantic recipe
- **Coverage**:
  - Technology Stack section: "- **Java**: Java 17" → "- **Java**: Java 21"
  - Prerequisites section: "- Java 17" → "- Java 21"

## Recipe Composition Rationale

### Broad Recipe First
Starting with `UpgradeToJava21` provides:
- Comprehensive coverage of Java-related changes
- Battle-tested migration paths
- Automatic handling of deprecated APIs
- Plugin version upgrades

### Text Replacements Last
Placed after semantic recipes because:
- Text replacement converts LST to plain text
- Language-specific recipes need LST structure
- Text replacements for non-Java files (Dockerfile, README) don't affect Java LST

## Trade-offs

**Advantages**:
- Simple, maintainable recipe composition
- Leverages official migration recipes
- Comprehensive API deprecation handling
- Future Java 21 features adoption included

**Disadvantages**:
- May apply more changes than strictly in the PR (e.g., deprecated API migrations)
- Less granular control over individual transformations
- Text replacements are brittle if file content changes

## Coverage Assessment

| Intent | Coverage | Method |
|--------|----------|--------|
| Java toolchain configuration | Complete | UpgradeToJava21 → UpgradeJavaVersion → UpdateJavaCompatibility |
| Gradle wrapper 8.1→8.5 | Complete | UpdateGradleWrapper |
| Docker builder image | Complete | FindAndReplace (text) |
| Docker runtime image | Complete | FindAndReplace (text) |
| GitHub Actions java-version | Complete | UpgradeToJava21 → SetupJavaUpgradeJavaVersion |
| GitHub Actions step name | Complete | FindAndReplace (text) |
| README Technology Stack | Complete | FindAndReplace (text) |
| README Prerequisites | Complete | FindAndReplace (text) |

## Recipe Execution Order

1. **UpgradeToJava21** - Semantic Java changes first
2. **UpdateGradleWrapper** - Semantic Gradle changes
3. **FindAndReplace recipes** - Text changes for non-semantic files

This ordering ensures LST-based recipes run before text manipulation recipes.
