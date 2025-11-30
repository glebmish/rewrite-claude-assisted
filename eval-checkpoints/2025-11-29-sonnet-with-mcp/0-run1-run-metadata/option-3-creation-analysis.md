# Option 3 Recipe Creation Analysis

## Objective
Create a hybrid recipe that fixes the critical toolchain migration gap from Options 1 & 2 while maintaining high precision and complete recall.

## Critical Gap Identified

**Both Option 1 and Option 2 failed to migrate to Java toolchain API:**

- Expected (PR #2): `java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }`
- Actual (Options 1 & 2): `sourceCompatibility = '21'` and `targetCompatibility = '21'`

**Root Cause:** No OpenRewrite semantic recipe exists to migrate from the legacy sourceCompatibility/targetCompatibility properties to the modern Gradle toolchain API.

**Evidence from recipe searches:**
- `org.openrewrite.java.migrate.UpgradeJavaVersion` - Uses `UpdateJavaCompatibility` which only updates the values to 21, doesn't migrate the syntax
- `org.openrewrite.gradle.UpdateJavaCompatibility` - Updates property values, not the configuration approach
- Searched extensively with variations: "migrate to java toolchain", "sourceCompatibility to toolchain", "gradle java toolchain languageVersion" - no semantic recipe found

## Recipe Strategy

**Hybrid Approach - Surgical precision with text replacement where needed:**

### Semantic Recipes Used (Structure-Aware)
1. `org.openrewrite.gradle.UpdateGradleWrapper` - Updates wrapper version, JAR, and properties
2. `org.openrewrite.github.SetupJavaUpgradeJavaVersion` - Updates GitHub Actions java-version field semantically

### Text Replacement (Where No Semantic Alternative Exists)
3. Build.gradle toolchain migration - **No semantic recipe available**
4. GitHub Actions step name - Simple text change
5. Dockerfile base images - Simple text substitution
6. README.md documentation - Simple text substitution

## Recipe Composition

### 1. Java Toolchain Migration (CRITICAL FIX)
```yaml
- org.openrewrite.text.FindAndReplace:
    find: "sourceCompatibility = '17'\ntargetCompatibility = '17'"
    replace: "java {\n    toolchain {\n        languageVersion = JavaLanguageVersion.of(21)\n    }\n}"
```

**Why text replacement:**
- No LST-based recipe exists for this migration
- The transformation requires removing two properties and adding a completely new configuration block
- Text replacement is the ONLY option available

**Risk mitigation:**
- Exact string match including quotes and newlines ensures precision
- File pattern limits to build.gradle files only

### 2. Gradle Wrapper Update
```yaml
- org.openrewrite.gradle.UpdateGradleWrapper:
    version: 8.5
```

**Why semantic:** Updates wrapper JAR, scripts, properties file, and SHA-256 checksums properly.

### 3. GitHub Actions Java Version
```yaml
- org.openrewrite.github.SetupJavaUpgradeJavaVersion:
    minimumJavaMajorVersion: 21
```

**Why semantic:** Understands GitHub Actions YAML structure and updates the java-version field correctly.

### 4. Documentation & Configuration Updates
Multiple `FindAndReplace` recipes for:
- GitHub Actions step name
- Docker images (JDK and JRE)
- README.md Java version
- README.md Gradle version (missed in Option 2)

**Why text replacement:** These are literal string substitutions in plain text or comments, no semantic understanding needed.

## Improvements Over Previous Options

### vs. Option 1 (Broad Approach)
**Option 1 Issues:**
- Used `UpgradeToJava21` which includes unnecessary modernizations (getFirst(), isEmpty())
- Updated sourceCompatibility/targetCompatibility instead of migrating to toolchain
- Low precision (40%) due to over-application

**Option 3 Advantages:**
- Fixes toolchain migration gap
- No unnecessary code modernizations
- Higher expected precision by avoiding broad recipes

### vs. Option 2 (Narrow Approach)
**Option 2 Issues:**
- Used `UpgradeJavaVersion` which still uses old compatibility properties
- Missing Gradle version update in README.md
- Same toolchain migration gap

**Option 3 Advantages:**
- Fixes toolchain migration with text replacement (only available option)
- Adds missing Gradle version documentation update
- Complete coverage of all PR changes

## Coverage Analysis

### Files Modified (Expected)
1. `build.gradle` - Toolchain migration ✓
2. `gradle/wrapper/gradle-wrapper.properties` - Version + SHA-256 ✓
3. `gradle/wrapper/gradle-wrapper.jar` - Binary update ✓
4. `gradlew` & `gradlew.bat` - Wrapper scripts ✓
5. `.github/workflows/ci.yml` - Java version + step name ✓
6. `Dockerfile` - JDK & JRE images ✓
7. `README.md` - Java & Gradle versions ✓

### Precision Considerations

**Potential Over-Application:**
- Gradle wrapper script changes (standard for wrapper updates, safe)
- SHA-256 checksum addition (security enhancement, beneficial)

**Expected Metrics:**
- Recall: 95-100% (all PR changes covered)
- Precision: 80-90% (minimal over-application, mainly wrapper internals)
- F1 Score: 85-95%

## Technical Justification

**Text Replacement for Toolchain Migration:**

After exhaustive recipe searches with multiple query variations:
- "migrate from sourceCompatibility targetCompatibility to java toolchain gradle"
- "convert gradle sourceCompatibility to toolchain API"
- "remove sourceCompatibility add toolchain"
- "add java toolchain block gradle"

**Conclusion:** No semantic recipe exists. Text replacement is the ONLY available approach for this specific transformation.

**Why this is acceptable:**
- The pattern is highly specific and unlikely to match elsewhere
- FilePattern restricts to build.gradle files only
- The transformation is well-defined with exact strings
- Alternative would be to write a custom OpenRewrite recipe (out of scope)

## Recipe Ordering Rationale

1. **Toolchain migration first** - Most critical change, affects build configuration
2. **Wrapper update second** - Updates build infrastructure
3. **CI/CD updates** - GitHub Actions configuration
4. **Docker updates** - Container images
5. **Documentation** - README updates last

## Expected Outcomes

**Strengths:**
- Complete coverage of all PR #2 changes
- Fixes the critical toolchain migration gap
- No unnecessary code modernizations
- Predictable, minimal scope

**Limitations:**
- Relies on text replacement for toolchain (no semantic alternative)
- Gradle wrapper will include standard script modernizations
- Pattern matching requires exact string match

**Recommendation:** This recipe provides the best balance of precision and recall for replicating PR #2 exactly.
