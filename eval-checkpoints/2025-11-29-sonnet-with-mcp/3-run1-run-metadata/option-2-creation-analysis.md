# Option 2: Surgical Approach - Recipe Analysis

## Recipe Discovery Process

### Search Strategy
Executed systematic multi-query searches across all intent tree levels:
- Java toolchain configuration (4 query variants)
- Individual dependency updates (4 variants)
- Type reference changes (4 variants)
- Package imports (4 variants)
- Annotation removal (4 variants)

### Key Finding
**No comprehensive Dropwizard 2.x to 3.x migration recipe exists**. Composed surgical solution using atomic recipes for each transformation.

## Recipe Selection Rationale

### 1. Java Toolchain Update
**Recipe:** `org.openrewrite.gradle.UpdateJavaCompatibility`
- **Why semantic:** Directly updates Gradle `java.toolchain.languageVersion` property
- **Coverage:** Precise match for `JavaLanguageVersion.of(11)` → `JavaLanguageVersion.of(17)`
- **Advantage:** More targeted than composite `UpgradeJavaVersion`
- **Setting:** `compatibilityType: both` updates source and target compatibility

### 2. Individual Dependency Updates
**Recipe:** `org.openrewrite.gradle.UpgradeDependencyVersion` (5 instances)
- **Why semantic:** Parses Gradle dependency DSL, handles string and map notation
- **Coverage:** Explicitly updates each of 5 Dropwizard dependencies
- **Advantage:** Full control and visibility over each dependency change
- **Matches intent tree exactly:**
  - dropwizard-core: 2.1.12 → 3.0.0
  - dropwizard-jdbi3: 2.1.12 → 3.0.0
  - dropwizard-auth: 2.1.12 → 3.0.0
  - dropwizard-configuration: 2.1.12 → 3.0.0
  - dropwizard-testing: 2.1.12 → 3.0.0

### 3. Type Reference Changes
**Recipe:** `org.openrewrite.java.ChangeType` (4 instances)
- **Why semantic:** Updates imports, fully-qualified references, maintains type safety
- **Coverage:** Precisely matches intent tree requirements
- **Advantage:** Only changes specified types, no over-migration
- **Transformations:**
  - `io.dropwizard.Application` → `io.dropwizard.core.Application`
  - `io.dropwizard.setup.Bootstrap` → `io.dropwizard.core.setup.Bootstrap`
  - `io.dropwizard.setup.Environment` → `io.dropwizard.core.setup.Environment`
  - `io.dropwizard.Configuration` → `io.dropwizard.core.Configuration`

### 4. Remove @Override Annotations
**Recipe:** `org.openrewrite.java.RemoveAnnotation`
- **Why semantic:** Parses Java AST, identifies and removes annotation nodes
- **Coverage limitation:** Removes ALL @Override annotations, not just from initialize()/run()
- **Risk:** May remove legitimate @Override annotations
- **Alternative considered:** `RemoveUnnecessaryOverride` (more precise, but may not catch all)

## Expected Coverage vs Intent Tree

### Full Coverage
- ✓ Java toolchain: 11 → 17
- ✓ All 5 dependencies individually specified
- ✓ All 4 type migrations precisely matched
- ⚠️ @Override removal: broader than needed

### Coverage Analysis by Intent

| Intent | Recipe | Coverage |
|--------|--------|----------|
| Java 11→17 | UpdateJavaCompatibility | 100% |
| 5 dependencies | 5× UpgradeDependencyVersion | 100% |
| 4 type changes | 4× ChangeType | 100% |
| 2 @Override removals | RemoveAnnotation | >100% (too broad) |

## Identified Gaps

### @Override Removal Precision
**Problem:** `RemoveAnnotation` removes ALL @Override annotations

**Evidence from intent tree:**
```
Only these need removal:
- @Override from initialize() in TaskApplication.java
- @Override from run() in TaskApplication.java
```

**What RemoveAnnotation does:**
- Removes @Override from EVERY method in the codebase
- May remove legitimate overrides that should be kept

**Potential solution:**
```yaml
# Not available in standard recipes, would require custom recipe
- Remove @Override from specific methods:
    className: TaskApplication
    methodName: initialize

- Remove @Override from specific methods:
    className: TaskApplication
    methodName: run
```

**Workaround:** Use `RemoveUnnecessaryOverride` instead (from Option 1), which only removes incorrect @Override annotations

## Trade-offs

### Advantages
- Maximum precision for dependencies and type changes
- Each transformation explicitly visible
- No risk of over-migration on packages
- Easy to audit and understand each change

### Disadvantages
- Verbose (14 recipe steps vs 4)
- @Override removal too aggressive
- More maintenance if additional dependencies needed

## Gap Filling Recommendation

### Modify @Override Removal
Replace:
```yaml
- org.openrewrite.java.RemoveAnnotation:
    annotationPattern: "@java.lang.Override"
```

With:
```yaml
- org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride:
    ignoreAnonymousClassMethods: false
```

This provides semantic analysis to remove only incorrect @Override annotations.

## Recommendation
Use Option 2 if:
- You need precise control over every change
- Want to avoid unintended package migrations
- Prefer explicit over implicit transformations
- Can accept verbose recipe definition for safety
