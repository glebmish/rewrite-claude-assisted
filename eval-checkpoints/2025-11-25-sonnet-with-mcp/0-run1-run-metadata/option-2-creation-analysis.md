# Option 2: Surgical Precision with Targeted Recipes

## Intent Summary

Java 17 to Java 21 upgrade across five file types:
- GitHub Actions workflow (YAML)
- Gradle build configuration (Groovy)
- Dockerfile (text)
- Gradle wrapper properties
- README documentation (Markdown)

## Recipe Selection Strategy

This option uses **narrow, targeted recipes** for surgical precision. Each transformation is handled by a specific recipe optimized for that particular change.

## Recipe Mapping

### 1. GitHub Actions CI (YAML Structure-Aware)
**Recipe**: `org.openrewrite.github.SetupJavaUpgradeJavaVersion`
- **Why**: Semantic YAML transformation understanding GitHub Actions structure
- **Covers**: All `actions/setup-java` java-version properties
- **Parameters**: `minimumJavaMajorVersion: 21`
- **Semantic Approach**: Parses YAML structure, identifies setup-java actions, modifies java-version property

### 2. Gradle Build File (Groovy DSL-Aware)
**Recipe**: `org.openrewrite.gradle.UpdateJavaCompatibility` (2 instances)
- **Why**: Understands Gradle DSL syntax and semantics
- **Covers**: sourceCompatibility and targetCompatibility separately
- **Parameters**:
  - Instance 1: `version: 21, compatibilityType: source, declarationStyle: String`
  - Instance 2: `version: 21, compatibilityType: target, declarationStyle: String`
- **Semantic Approach**: Parses Gradle build script, identifies compatibility declarations, updates values while preserving format

**Note**: This option does NOT migrate to toolchain. It keeps the existing sourceCompatibility/targetCompatibility pattern but updates values to 21.

### 3. Gradle Wrapper (Properties Structure-Aware)
**Recipe**: `org.openrewrite.gradle.UpdateGradleWrapper`
- **Why**: Semantic understanding of Gradle wrapper structure and versioning
- **Covers**: gradle/wrapper/gradle-wrapper.properties updates
- **Parameters**: `version: 8.5, distribution: bin`
- **Semantic Approach**: Updates wrapper version, adds SHA-256 checksum, validates compatibility

### 4. Dockerfile (Text-Based - Last Resort)
**Recipe**: `org.openrewrite.FindAndReplace` (2 instances)
- **Why**: No semantic Dockerfile recipe exists for base image version updates
- **Limitation**: Text-based replacement, not structure-aware
- **Covers**:
  - JDK image: `eclipse-temurin:17-jdk-alpine → eclipse-temurin:21-jdk-alpine`
  - JRE image: `eclipse-temurin:17-jre-alpine → eclipse-temurin:21-jre-alpine`
- **Parameters**: Specific find/replace with filePattern: `**/Dockerfile`
- **Risk**: Could match unintended text; patterns are sufficiently specific to minimize risk

### 5. README.md Documentation (Text-Based - Last Resort)
**Recipe**: `org.openrewrite.FindAndReplace` (2 instances)
- **Why**: No semantic Markdown recipe for version references
- **Limitation**: Text-based replacement
- **Covers**:
  - Java version: `"Java 17" → "Java 21"`
  - Gradle version: `"Gradle 8.1" → "Gradle 8.5"`
- **Parameters**: Specific strings with filePattern: `**/README.md`
- **Risk**: May miss variations like "java 17" or "JDK 17"; patterns match observed documentation style

## Coverage Analysis

### Complete Coverage
- GitHub Actions java-version: ✓ Semantic recipe
- Gradle sourceCompatibility: ✓ Semantic recipe
- Gradle targetCompatibility: ✓ Semantic recipe
- Gradle wrapper version: ✓ Semantic recipe

### Text-Based Coverage (Acceptable)
- Dockerfile base images: ⚠ Text replacement (no semantic alternative)
- README.md documentation: ⚠ Text replacement (no semantic alternative)

## Gap Analysis

**Dockerfile Transformation**:
- Searched for: Docker base image modification recipes
- Found: Only search/discovery recipes (`FindDockerImageUses`)
- Gap: No semantic recipe to update Dockerfile FROM statements
- Resolution: Used `FindAndReplace` with precise patterns

**README Documentation**:
- Searched for: Markdown content modification recipes
- Found: No relevant recipes for version number updates
- Gap: No semantic Markdown transformation recipes
- Resolution: Used `FindAndReplace` with exact string matches

## Recipe Ordering and Dependencies

Order matters for correct execution:

1. **GitHub Actions** (independent)
2. **Gradle compatibility** - source first, then target (independent of each other)
3. **Gradle wrapper** (independent)
4. **Dockerfile JDK image** (independent)
5. **Dockerfile JRE image** (independent)
6. **README Java version** (independent)
7. **README Gradle version** (independent)

No conflicts expected - each recipe targets different files or different properties.

## Advantages of This Approach

1. **Precision**: Each recipe does exactly one thing
2. **Transparency**: Clear what each step does
3. **Debugging**: Easy to identify which recipe caused issues
4. **Selective Execution**: Can comment out specific recipes if needed
5. **No Unintended Changes**: Limited scope reduces risk

## Disadvantages of This Approach

1. **Verbose**: 8 recipe invocations vs 1-2 in broad approach
2. **Maintenance**: More recipes to update if requirements change
3. **Text-Based Fallback**: Dockerfile and README use non-semantic transformations
4. **Incomplete Migration**: Doesn't migrate to Java toolchain (by design for Option 2)

## Testing Recommendations

1. Run on test branch first
2. Verify GitHub Actions workflow syntax with `actionlint`
3. Validate Gradle build with `./gradlew build`
4. Check Dockerfile with `docker build`
5. Review README changes for accuracy
6. Test wrapper: `./gradlew --version` should show 8.5

## Alternative Considered

**Could use**: `org.openrewrite.java.migrate.UpgradeJavaVersion` (composite recipe)
- **Why not chosen**: Too broad for Option 2's surgical approach
- **What it would do**: Updates build configs but may include other transformations
- **Trade-off**: Option 2 favors explicit control over convenience

## Customization Notes

To migrate to toolchain instead of compatibility properties:
- Replace both `UpdateJavaCompatibility` recipes with custom recipe that:
  1. Removes sourceCompatibility/targetCompatibility
  2. Adds java.toolchain block with languageVersion = 21

This would require a custom recipe implementation.

## Risk Assessment

**Low Risk**:
- GitHub Actions (semantic YAML)
- Gradle compatibility (semantic Groovy)
- Gradle wrapper (semantic properties)

**Medium Risk**:
- Dockerfile (text-based, specific patterns)
- README (text-based, exact strings)

**Mitigation**: Review all changes before committing, especially text-based replacements.
