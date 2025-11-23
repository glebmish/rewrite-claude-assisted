# Option 1: Narrow/Specific Recipe Approach - Analysis

## Recipe Selection Rationale

### Narrow Recipe Strategy
This option uses **4 targeted recipes** for surgical precision:

1. **org.openrewrite.gradle.UpdateJavaCompatibility** (version: 17)
   - Semantic Gradle recipe that understands Gradle build structure
   - Updates `sourceCompatibility` and `targetCompatibility` properties
   - Uses LST to preserve formatting and comments
   - Parameter: `addIfMissing: false` (only update existing properties)

2. **org.openrewrite.gradle.UpdateGradleWrapper** (version: 7.6)
   - Updates gradle-wrapper.properties distributionUrl
   - Gradle 7.6 required for Java 17 support (7.3+ minimum)
   - Queries services.gradle.org for accurate artifact URLs
   - Parameter: `addIfMissing: false` (wrapper already exists)

3. **org.openrewrite.text.FindAndReplace** (builder image)
   - Text-based recipe for Dockerfile (no Dockerfile LST parser exists)
   - Pattern: `FROM openjdk:11-jdk-slim` → `FROM eclipse-temurin:17-jdk-alpine`
   - Exact string match (regex: false, caseSensitive: true)
   - Scoped to Dockerfile files only

4. **org.openrewrite.text.FindAndReplace** (runtime image)
   - Text-based recipe for Dockerfile runtime stage
   - Pattern: `FROM openjdk:11-jre-slim` → `FROM eclipse-temurin:17-jre-alpine`
   - Exact string match (regex: false, caseSensitive: true)
   - Scoped to Dockerfile files only

### Why Narrow Over Broad?

**Rejected broader alternative**: `org.openrewrite.java.migrate.UpgradeBuildToJava17`
- Contains only `UpgradeJavaVersion` which targets multiple build systems
- Less granular control over exact Gradle wrapper version
- Doesn't handle Dockerfile transformations
- Would require additional recipes anyway

**Rejected comprehensive migration**: `org.openrewrite.java.migrate.UpgradeToJava17`
- Includes 10+ sub-recipes for Java 11→17 language features
- Applies pattern matching, text blocks, record imports, etc.
- **NOT NEEDED**: PR diff shows NO Java code changes requiring these features
- Overly broad for simple version bump

## Coverage Assessment

### Changes Covered (100% of Java 17 upgrade)

**Gradle Build Configuration** ✓
- `build.gradle`: sourceCompatibility '11' → '17'
- `build.gradle`: targetCompatibility '11' → '17'
- Recipe: UpdateJavaCompatibility handles both properties

**Gradle Wrapper** ✓
- `gradle-wrapper.properties`: gradle-6.7-all.zip → gradle-7.6-all.zip
- Recipe: UpdateGradleWrapper with exact version

**Dockerfile Builder Stage** ✓
- Line 7: `FROM openjdk:11-jdk-slim` → `FROM eclipse-temurin:17-jdk-alpine`
- Recipe: FindAndReplace with exact pattern match

**Dockerfile Runtime Stage** ✓
- Line 17: `FROM openjdk:11-jre-slim` → `FROM eclipse-temurin:17-jre-alpine`
- Recipe: FindAndReplace with exact pattern match

### Changes NOT Covered (Out of Scope)

**Authentication Refactoring** ✗
- WeatherApiApplication.java: ChainedAuthFilter → BasicCredentialAuthFilter
- ApiKeyAuthenticator.java: String → BasicCredentials signature change
- User.java: Added type field, modified constructor
- Deleted: JwtAuthFilter.java, JwtAuthenticator.java, ApiKeyAuthFilter.java
- Updated: ApiKeyAuthenticatorTest.java
- Deleted: JwtAuthenticatorTest.java

**Rationale**: Authentication changes are application-specific business logic refactoring unrelated to Java 17 upgrade. These require manual implementation decisions and cannot be automated.

## Gap Analysis

### Semantic vs Text-Based Recipes

**Gap Identified**: Dockerfile transformations use text-based recipes

**Why?**
- OpenRewrite has no Dockerfile LST parser
- Text-based recipes are the recommended approach for Dockerfiles
- FindAndReplace with exact string matching provides safe, predictable results

**Trade-off**:
- Text recipes convert file to plain text (disables LST for remaining recipes)
- Acceptable because Dockerfiles have no LST support anyway
- Recipe ordering: Dockerfile changes placed AFTER Gradle recipes to preserve LST for build files

**Alternative Considered**: Regex patterns for more flexible matching
- Rejected: Exact string match safer and matches PR diff exactly
- Pattern `FROM openjdk:11-jdk-slim` is unique and unambiguous

### Java Version-Specific Language Features

**Gap**: No adoption of Java 17 language features (pattern matching, text blocks, etc.)

**Justification**:
- PR diff contains ZERO Java code changes for language features
- Changes are pure infrastructure/config updates
- Adding feature adoption recipes would be speculative and out of scope
- If needed later, can be separate recipe run

## Trade-offs of Narrow Approach

### Advantages ✓

1. **Precise Control**
   - Exact Gradle wrapper version (7.6 not 7.x)
   - No unwanted language feature transformations
   - Predictable, minimal changes

2. **Transparent Composition**
   - Each recipe maps 1:1 to specific PR changes
   - Easy to understand what each step does
   - Simple to modify or remove individual steps

3. **Safe Execution**
   - Only changes infrastructure configuration
   - No speculative code transformations
   - Matches PR diff intent exactly

4. **Testability**
   - Can validate each recipe independently
   - Clear failure points if issues occur
   - Minimal blast radius

### Disadvantages ✗

1. **Multiple Recipe Maintenance**
   - 4 recipes to manage vs 1 broad recipe
   - More verbose YAML configuration
   - Need to understand individual recipe parameters

2. **Missed Future Patterns**
   - Won't automatically adopt new Java 17 best practices
   - Manual curation required for additional changes
   - No built-in Java 11→17 migration knowledge

3. **Text-Based Dockerfile Changes**
   - Breaks LST for Dockerfile (unavoidable - no LST parser exists)
   - Less robust than semantic transformations
   - Requires exact pattern matching

4. **No Dependency Updates**
   - Doesn't update libraries for Java 17 compatibility
   - PR shows no dependency changes, but some libs may need updates
   - Would require separate dependency upgrade recipes

## Execution Considerations

### Recipe Ordering

**Critical**: Gradle recipes BEFORE Dockerfile recipes
- UpdateJavaCompatibility and UpdateGradleWrapper use Gradle LST
- FindAndReplace converts to text, disabling LST
- Order ensures Gradle files transformed semantically first

### Expected Behavior

**build.gradle**:
- Preserves all formatting, comments, and structure
- Only modifies sourceCompatibility and targetCompatibility values
- LST-based transformation maintains Gradle syntax

**gradle-wrapper.properties**:
- Updates distributionUrl line only
- Preserves all other properties unchanged
- May update URL to official services.gradle.org format

**Dockerfile**:
- Exact string replacement for both FROM lines
- Preserves all other Dockerfile content
- No LST preservation (text-based transformation)

### Validation Strategy

1. Run recipe on repository
2. Compare output to PR diff for Java 17 changes
3. Verify no unintended changes to auth code
4. Test Gradle build with Java 17
5. Test Docker image builds successfully

## Semantic Recipe Analysis

### Why These Are NOT Simple Text Replacements

**UpdateJavaCompatibility**:
- Parses Gradle build files into Abstract Syntax Tree
- Understands Groovy/Kotlin DSL structure
- Navigates to specific property assignments
- Updates values while preserving closure context
- Maintains proper syntax for literals (quoted vs unquoted)

**UpdateGradleWrapper**:
- Parses .properties file format
- Queries Gradle services for valid distribution URLs
- Updates distributionUrl key preserving escaping rules
- Validates version exists before transformation

**FindAndReplace (Dockerfile)**:
- Text-based because Dockerfile LST doesn't exist
- Still uses OpenRewrite's visitor pattern
- File pattern matching prevents unintended file changes
- Explicit parameter controls (caseSensitive, regex) provide safety

**Rejected**: Generic text replacements like sed/awk
- No file type awareness
- No visitor pattern
- No integration with OpenRewrite ecosystem
- Not composable with other recipes

## Conclusion

This narrow approach provides **surgical precision** for the Java 17 infrastructure upgrade while avoiding speculative code transformations. It matches the PR's actual changes exactly and provides maximum control and transparency.

**Best for**: Teams that want explicit control over each transformation step and have specific version requirements.
