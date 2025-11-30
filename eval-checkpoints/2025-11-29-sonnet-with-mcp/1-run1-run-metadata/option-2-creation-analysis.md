# Option 2: Enhanced Hybrid Approach Analysis

## Alternative Strategy
Unlike Option 1's broad `UpgradeToJava17` recipe, this option uses a **surgical, hybrid approach** combining:
- Semantic recipes for structured changes (Gradle, Java)
- Text-based recipes for non-Java files (Dockerfile)
- Explicit file deletions
- Strategic cleanup recipes

This provides **more control** and **transparency** while achieving **better coverage** than the original Option 2.

## Recipe Discovery Summary

Performed systematic multi-query searches across all intent tree levels:
- Java version upgrades: 10 recipes found
- Gradle compatibility: 10 recipes found
- Gradle wrapper: 10 recipes found
- Docker changes: 8 recipes found (no semantic Dockerfile recipes)
- File deletion: 10 recipes found
- Import management: 10 recipes found
- Method signature changes: 10 recipes found
- Text replacement: 6 recipes found

## Recipe Composition

### 1. Gradle Java Compatibility (Semantic - High Confidence)
**org.openrewrite.gradle.UpdateJavaCompatibility** (2 instances)
- Changes `sourceCompatibility = '11'` → `'17'`
- Changes `targetCompatibility = '11'` → `'17'`
- **Why semantic**: Understands Gradle DSL structure, not just text
- **Coverage**: 100% of intent 1.1.1

### 2. Gradle Wrapper Upgrade (Semantic - High Confidence)
**org.openrewrite.gradle.UpdateGradleWrapper** (version: 7.6)
- Updates `gradle/wrapper/gradle-wrapper.properties`
- Changes distribution URL to gradle-7.6-all.zip
- Adds SHA-256 checksum automatically
- **Why semantic**: Queries services.gradle.org, validates versions
- **Coverage**: 100% of intent 1.2.1

### 3. Dockerfile Base Images (Text - No Semantic Alternative)
**org.openrewrite.text.FindAndReplace** (2 instances)
- `openjdk:11-jdk-slim` → `eclipse-temurin:17-jdk-alpine`
- `openjdk:11-jre-slim` → `eclipse-temurin:17-jre-alpine`
- **Why text-based**: No Docker-aware LST support in OpenRewrite
- **Justification**: Exact string match, low risk of false positives
- **Coverage**: 100% of intents 1.3.1 and 1.3.2

### 4. File Deletions (Semantic - High Confidence)
**org.openrewrite.DeleteSourceFiles** (4 instances)
- Removes JWT authentication files
- Removes custom API key filter
- Removes associated tests
- **Why semantic**: Uses source path resolution, not filesystem
- **Coverage**: 100% of intents 2.1.1, 2.1.2, 2.1.3, 2.2.1

### 5. Import Cleanup (Semantic - Automatic)
**org.openrewrite.java.RemoveUnusedImports**
- Removes imports for deleted classes
- Safe: won't remove if unknown types present
- **Coverage**: Partial coverage of intent 2.3.1

### 6. Code Formatting (Semantic - Consistency)
**org.openrewrite.java.format.AutoFormat**
- Normalizes whitespace
- Fixes indentation
- **Coverage**: Addresses whitespace changes throughout PR

## Coverage Analysis

### Fully Automated (55%)
✓ Gradle sourceCompatibility/targetCompatibility (intent 1.1.1)
✓ Gradle wrapper properties (intent 1.2.1)
✓ Dockerfile base images (intents 1.3.1, 1.3.2)
✓ File deletions (intents 2.1.1-2.1.3, 2.2.1)
✓ Unused import removal (partial intent 2.3.1)
✓ Code formatting (whitespace normalization)

### Requires Custom Recipe Implementation (45%)
✗ WeatherApiApplication authentication refactoring (intents 2.3.1-2.3.2)
  - Complex business logic transformation
  - ChainedAuthFilter → BasicCredentialAuthFilter migration
  - Requires understanding of Dropwizard authentication patterns

✗ ApiKeyAuthenticator method signature changes (intents 2.4.1-2.4.2)
  - `Authenticator<String,User>` → `Authenticator<BasicCredentials,User>`
  - Method parameter: `String apiKey` → `BasicCredentials credentials`
  - Logic: Extract username from credentials object

✗ User class structural changes (intents 2.5.1-2.5.2, 2.6.1-2.6.2)
  - Add `type` field
  - Update constructor signature
  - Add `getType()` method
  - Replace `equals()`/`hashCode()` with `toString()`

✗ Test method updates (intents 2.6.1-2.6.2)
  - String literals → BasicCredentials objects
  - Update assertions for new User structure

## Key Differences from Option 1

| Aspect | Option 1 (Broad) | Option 2 (Hybrid) |
|--------|------------------|-------------------|
| **Core Strategy** | Single broad migration recipe | Multiple targeted recipes |
| **Java 17 Features** | Applies ALL Java 17 transformations (text blocks, pattern matching, etc.) | Only infrastructure changes |
| **Dockerfile** | Not covered | Covered via text replacement |
| **Control** | Low - accepts all UpgradeToJava17 changes | High - explicit about each change |
| **Risk** | May apply unwanted transformations | Only applies specified changes |
| **Visibility** | Opaque - 30+ sub-recipes | Transparent - each step visible |
| **Coverage** | ~70% (similar to Option 2) | ~55% (excludes Java 17 API migrations) |

## Recipe Ordering Rationale

1. **Gradle changes first**: Build infrastructure before code changes
2. **Dockerfile changes**: Infrastructure before Java code
3. **File deletions**: Remove code before trying to refactor it
4. **Import cleanup**: After deletions to remove unused imports
5. **Formatting last**: After all substantive changes

## Gaps Requiring Custom Recipes

### Gap 1: Dropwizard Authentication Migration
**No semantic recipe exists** for:
- Removing ChainedAuthFilter setup
- Adding BasicCredentialAuthFilter setup
- Changing filter builder patterns

**Custom recipe needed** to:
1. Detect ChainedAuthFilter usage pattern
2. Extract authenticator configuration
3. Replace with BasicCredentialAuthFilter.Builder pattern
4. Update import statements

### Gap 2: Interface Type Parameter Changes
**No semantic recipe exists** for:
- Changing generic type parameters in `implements` clauses
- Updating all downstream code that depends on type parameter

**Custom recipe needed** to:
1. Find `implements Authenticator<String, User>`
2. Change to `implements Authenticator<BasicCredentials, User>`
3. Update method signatures accordingly

### Gap 3: Class Structure Modifications
**No semantic recipe exists** for:
- Adding fields to existing classes
- Updating constructor signatures with new parameters
- Replacing method implementations (equals/hashCode → toString)

**Custom recipe needed** for each structural change type.

## Recommendation

**Option 2 (Enhanced Hybrid)** is recommended when:
- You want explicit control over each transformation
- You want to avoid Java 17 API modernizations (text blocks, etc.)
- Dockerfile changes are important
- You're willing to implement custom recipes for authentication changes

**Option 1 (Broad)** may be preferred when:
- You want comprehensive Java 17 API adoption
- Dockerfile changes can be manual
- You accept all transformations from UpgradeToJava17

**Both options** require custom recipe implementation for the complex authentication refactoring (~45% of changes).
