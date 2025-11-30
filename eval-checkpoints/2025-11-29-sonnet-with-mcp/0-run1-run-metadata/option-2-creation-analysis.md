# Option 2 Creation Analysis - Narrow/Specific Approach

## Intent Summary

Java 17 to Java 21 upgrade across:
* Build configuration (Gradle)
* CI/CD (GitHub Actions)
* Container images (Docker)
* Documentation (README.md)

## Recipe Mapping

### 1. Gradle Java Version Configuration
**Recipe**: `org.openrewrite.java.migrate.UpgradeJavaVersion` (version: 21)
**Coverage**:
- Replaces `sourceCompatibility = '17'` with toolchain configuration
- Replaces `targetCompatibility = '17'` with toolchain configuration
- Adds `java.toolchain.languageVersion = JavaLanguageVersion.of(21)`
**Semantic Approach**: Uses Gradle LST to understand build file structure and properly configure Java toolchain

### 2. Gradle Wrapper Update
**Recipe**: `org.openrewrite.gradle.UpdateGradleWrapper` (version: 8.5)
**Coverage**: Updates Gradle wrapper from 8.1 to 8.5
**Semantic Approach**: Modifies gradle-wrapper.properties understanding the properties file format

### 3. GitHub Actions Java Version
**Recipe**: `org.openrewrite.github.SetupJavaUpgradeJavaVersion` (minimumJavaMajorVersion: 21)
**Coverage**:
- Updates `java-version: '17'` to `java-version: '21'` in setup-java action
**Semantic Approach**: Understands YAML structure and GitHub Actions workflow schema to modify the correct property

### 4. GitHub Actions Step Name
**Recipe**: `org.openrewrite.text.FindAndReplace`
**Coverage**: Changes step name from "Set up JDK 17" to "Set up JDK 21"
**Why Text-based**:
- Step names are free-form strings without semantic meaning
- No semantic recipe exists for renaming workflow step names
- YAML value replacement would be overly complex for simple string change
**Parameters**:
- find: "Set up JDK 17"
- replace: "Set up JDK 21"
- filePattern: ".github/workflows/*.yml"

### 5. Dockerfile Builder Stage Base Image
**Recipe**: `org.openrewrite.text.FindAndReplace`
**Coverage**: Changes FROM eclipse-temurin:17-jdk-alpine to eclipse-temurin:21-jdk-alpine
**Why Text-based**:
- No semantic Dockerfile recipe found for base image updates
- Docker base images are string literals in FROM statements
- Text replacement is precise and safe for this pattern
**Parameters**:
- find: "eclipse-temurin:17-jdk-alpine"
- replace: "eclipse-temurin:21-jdk-alpine"
- filePattern: "**/Dockerfile"

### 6. Dockerfile Runtime Stage Base Image
**Recipe**: `org.openrewrite.text.FindAndReplace`
**Coverage**: Changes FROM eclipse-temurin:17-jre-alpine to eclipse-temurin:21-jre-alpine
**Why Text-based**: Same rationale as builder stage
**Parameters**:
- find: "eclipse-temurin:17-jre-alpine"
- replace: "eclipse-temurin:21-jre-alpine"
- filePattern: "**/Dockerfile"

### 7. README.md Documentation Updates
**Recipe**: `org.openrewrite.text.FindAndReplace`
**Coverage**: Updates "Java 17" to "Java 21" in both Technology Stack and Prerequisites sections
**Why Text-based**:
- Documentation is plain text/markdown without semantic structure
- No semantic recipe for markdown content updates
- Simple string replacement appropriate for documentation
**Parameters**:
- find: "Java 17"
- replace: "Java 21"
- filePattern: "**/README.md"

## Gap Analysis

**Complete Coverage**: All transformations from the intent tree are covered

**No Gaps Identified**:
1. Gradle configuration ✓ - Covered by UpgradeJavaVersion
2. Gradle wrapper ✓ - Covered by UpdateGradleWrapper
3. GitHub Actions java-version ✓ - Covered by SetupJavaUpgradeJavaVersion
4. GitHub Actions step name ✓ - Covered by text replacement (no semantic alternative)
5. Dockerfile base images ✓ - Covered by text replacement (no semantic alternative)
6. README documentation ✓ - Covered by text replacement (appropriate for docs)

## Recipe Selection Rationale

**Semantic Recipes (Priority)**:
1. `UpgradeJavaVersion` - Handles complex Gradle build file transformations correctly
2. `UpdateGradleWrapper` - Manages wrapper properties with checksums
3. `SetupJavaUpgradeJavaVersion` - Understands GitHub Actions YAML structure

**Text-based Recipes (When Necessary)**:
4-7. `FindAndReplace` - Used only where no semantic alternative exists:
   - GitHub Actions step names (free-form strings)
   - Dockerfile FROM statements (no Dockerfile semantic recipes available)
   - README.md content (markdown documentation)

## Composition Strategy

**Sequential Execution**:
1. Gradle changes first (build foundation)
2. GitHub Actions updates (CI/CD)
3. Docker image updates (deployment)
4. Documentation updates last (non-functional)

**Recipe Ordering**:
- Semantic recipes execute before text-based to preserve LST where possible
- Text recipes target specific file patterns to avoid unintended changes
- No conflicts between recipes (different files or non-overlapping changes)

## Trade-offs

**Advantages**:
- Precise control over each transformation
- Easy to understand what each recipe does
- Can be selectively applied or removed
- Minimal risk of unintended changes

**Disadvantages**:
- More verbose than broad recipes
- Multiple text-based recipes for simple replacements
- May need updates if file patterns change

## Testing Recommendations

1. Verify Gradle build still works after toolchain migration
2. Test GitHub Actions workflow executes successfully
3. Verify Docker images build and run correctly
4. Review README.md for any missed version references
