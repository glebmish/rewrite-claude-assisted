# Option 3 Recipe Creation Analysis

## Design Philosophy

Option 3 combines the best aspects of both validated recipes while addressing all critical issues identified during validation. This hybrid approach uses:
- **Targeted semantic recipes** where available (JUnit test code transformations, Gradle wrapper updates)
- **Precise text replacement** only where semantic recipes are unavailable or produce incorrect results
- **Explicit version control** to avoid unwanted upgrades (e.g., Mockito)
- **Correct dependency scoping** with split JUnit 5 dependencies

## Key Improvements Over Option 1 (Broad Approach)

### 1. JUnit Dependency Configuration - FIXED
**Option 1 Issue**: Wrong scope (`implementation` instead of `testImplementation`/`testRuntimeOnly`), wrong artifact (`junit-jupiter` instead of split `junit-jupiter-api`/`junit-jupiter-engine`), wrong version (5.14.1 vs 5.8.1)

**Option 3 Solution**:
- Uses `org.openrewrite.gradle.AddDependency` with explicit configuration
- Separate entries for `junit-jupiter-api` (testImplementation) and `junit-jupiter-engine` (testRuntimeOnly)
- Pinned to version 5.8.1 to match PR
- Uses `onlyIfUsing: org.junit.jupiter.api.*` to ensure conditional addition

### 2. Java Toolchain Migration - FIXED
**Option 1 Issue**: Used `sourceCompatibility`/`targetCompatibility` instead of modern toolchain API

**Option 3 Solution**:
- Text replacement to convert old syntax to toolchain syntax
- Matches exact PR pattern with proper indentation
- Targets specific Java version (17) in toolchain configuration

### 3. Application Plugin Property - FIXED
**Option 1 Issue**: Deprecated `mainClassName` not updated to `mainClass`

**Option 3 Solution**:
- Regex-based replacement targeting application block specifically
- Preserves exact formatting and property value
- Uses capture groups to maintain context

### 4. ShadowJar Configuration - FIXED
**Option 1 Issue**: Missing `mainClassName` in shadowJar block

**Option 3 Solution**:
- Adds `mainClassName` property to shadowJar block
- Uses regex to locate correct insertion point after `mergeServiceFiles()`
- Maintains proper indentation

### 5. No Unwanted Mockito Upgrade
**Option 1 Issue**: Upgraded Mockito from 3.12.4 to 4.11.0 (major version jump)

**Option 3 Solution**:
- Removes broad `UpgradeToJava17` recipe that caused this
- Uses targeted recipes that don't touch Mockito

## Key Improvements Over Option 2 (Narrow Approach)

### 1. Java Toolchain - ADDRESSED
**Option 2 Issue**: `UpdateGradleJavaCompatibility` produced `sourceCompatibility`/`targetCompatibility`

**Option 3 Solution**:
- Direct text replacement to achieve toolchain syntax
- No intermediate compatibility properties

### 2. JUnit Dependencies - IMPROVED
**Option 2 Issue**: Same as Option 1 - wrong scope, version, and structure

**Option 3 Solution**:
- Explicit `AddDependency` calls with correct parameters
- Conditional addition based on usage (`onlyIfUsing`)

### 3. GitHub Actions Step Name - ADDRESSED
**Option 2 Issue**: Only updated `java-version` value, not step name

**Option 3 Solution**:
- Added `org.openrewrite.yaml.ChangeValue` with JSONPath selector
- Targets step name specifically using filter expression
- Semantic YAML manipulation instead of text replacement

### 4. Comments and Property Names - ADDRESSED
**Option 2 Issue**: No recipe support for comment updates or property renames

**Option 3 Solution**:
- Text replacement for comment updates
- Regex-based property renaming for `mainClassName` → `mainClass`

## Recipe Ordering Rationale

1. **Gradle infrastructure first**: Wrapper and plugins before code changes
2. **JUnit code transformations**: Test annotations, assertions, imports
3. **JUnit configuration**: Platform usage in test block
4. **Dependency management**: Remove old, add new with correct scopes
5. **GitHub Actions**: Update CI configuration
6. **Build file refinements**: Toolchain, comments, property names (text-based, run last to avoid LST loss)

## Text Replacement Justification

While semantic recipes are preferred, text replacement is necessary for:

1. **Java toolchain migration**: No existing recipe migrates from compatibility to toolchain syntax
2. **Comment updates**: Comments are not part of semantic tree, require text manipulation
3. **Property renaming in application block**: No recipe for deprecated Gradle property updates
4. **ShadowJar mainClassName addition**: Shadow plugin recipes don't handle this configuration

**Important**: Text-based recipes are placed LAST to minimize impact on language-specific LST processing.

## Expected Outcomes

### Coverage Improvements
- **GitHub Actions step name**: Now updated (was missed in both options)
- **Java toolchain**: Proper modern syntax (was wrong in both options)
- **JUnit dependencies**: Correct scope, artifacts, version (was wrong in both options)
- **Application properties**: Both mainClass and shadowJar mainClassName (was missing in both options)
- **Comments**: Updated to reflect JUnit 5 (was missing in both options)

### Precision Improvements
- **No Mockito upgrade**: Stays at 3.12.4 (Option 1 incorrectly upgraded to 4.11.0)
- **No Optional.isEmpty()**: Won't modernize production code unnecessarily (Option 1 did this)
- **Exact version matching**: JUnit 5.8.1, not 5.14.1

### Potential Concerns

1. **Text replacement fragility**: Regex patterns assume specific formatting in build.gradle
   - Mitigation: Patterns designed to be flexible with whitespace
   - Alternative: Custom recipes if text replacement proves unreliable

2. **LST loss warning**: FindAndReplace converts files to plain text
   - Mitigation: All semantic recipes run before text replacements
   - Impact: Minimal since this is final recipe run

3. **JSONPath in YAML recipe**: Step name selector uses filter expression
   - Risk: May not match if workflow structure differs
   - Mitigation: Pattern matches any `setup-java` action

## Metrics Prediction

Based on validation results:

**Option 1**: F1 64.52% (20 TP, 11 FP, 11 FN)
**Option 2**: F1 67.86% (19 TP, 6 FP, 12 FN)
**Option 3 Expected**: F1 > 85% (target: 27-28 TP, 3-4 FP, 3-4 FN)

**Expected improvements**:
- +5-7 true positives (toolchain, step name, dependencies, properties, comments)
- -7 false positives (no Mockito upgrade, no Optional modernization, no wrong dependencies)
- -7-8 false negatives (fills gaps from both options)

## Testing Recommendations

1. Verify toolchain syntax transformation on build.gradle
2. Confirm JUnit dependencies have correct scope and version
3. Check GitHub Actions step name update
4. Validate application and shadowJar property updates
5. Ensure no unwanted dependency upgrades (Mockito, etc.)
6. Test that wrapper updates complete successfully
