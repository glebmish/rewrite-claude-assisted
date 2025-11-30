# Option 1: Broad Approach - Recipe Analysis

## Recipe Discovery Process

### Search Strategy
Executed systematic multi-query searches across all intent tree levels:
- Dropwizard upgrade recipes (4 query variants)
- Java version upgrade (4 variants)
- Dependency version updates (4 variants)
- Package import migrations (4 variants)
- Annotation removal (4 variants)

### Key Finding
**No comprehensive Dropwizard 2.x to 3.x migration recipe exists** in the OpenRewrite ecosystem. Found only Dropwizard-to-Spring-Boot migration recipes, which are not applicable.

## Recipe Selection Rationale

### 1. Java Version Upgrade
**Recipe:** `org.openrewrite.java.migrate.UpgradeJavaVersion`
- **Why semantic:** Understands Gradle toolchain structure, updates `java.toolchain.languageVersion`
- **Coverage:** Fully covers intent to upgrade from Java 11 to 17
- **Composite recipe:** Includes UpdateJavaCompatibility, Maven compiler updates, Jenkins updates

### 2. Dependency Version Updates
**Recipe:** `org.openrewrite.gradle.UpgradeDependencyVersion` with wildcard
- **Why semantic:** Parses Gradle DSL, understands dependency blocks
- **Coverage:** Updates all `io.dropwizard:*:2.1.12` to `3.0.0` in one step
- **Advantage:** Single recipe handles all 5 dependencies via wildcard artifact matching

### 3. Package Import Migration
**Recipe:** `org.openrewrite.java.ChangePackage`
- **Why semantic:** Updates package statements, imports, and fully-qualified type references
- **Coverage limitation:** May be too broad - changes ALL io.dropwizard packages
- **Risk:** Could migrate packages that shouldn't be migrated
- **Setting:** `recursive: false` to avoid subpackage changes

### 4. Remove Unnecessary @Override
**Recipe:** `org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride`
- **Why semantic:** Analyzes method signatures against superclass/interface methods
- **Coverage:** Removes @Override only from methods that don't actually override
- **Advantage:** Dropwizard-specific recipe, understands the migration context

## Expected Coverage vs Intent Tree

### Full Coverage
- ✓ Java version upgrade (11 → 17)
- ✓ All 5 Dropwizard dependencies (2.1.12 → 3.0.0)
- ✓ @Override removal (semantic analysis)

### Partial Coverage with Risk
- ⚠️ Package imports: `ChangePackage` may change too much
  - Intent: Only migrate specific classes (Application, Bootstrap, Environment, Configuration)
  - Reality: Recipe changes entire `io.dropwizard` package to `io.dropwizard.core`
  - **Gap:** May migrate packages that should remain unchanged

## Identified Gaps

### Package Migration Precision
**Problem:** `ChangePackage` is too broad for the specific requirement

**Evidence from intent tree:**
```
Only these specific imports need migration:
- io.dropwizard.Application → io.dropwizard.core.Application
- io.dropwizard.setup.* → io.dropwizard.core.setup.*
- io.dropwizard.Configuration → io.dropwizard.core.Configuration
```

**What ChangePackage does:**
- Changes ALL imports starting with `io.dropwizard` to `io.dropwizard.core`
- May break imports that should stay in `io.dropwizard` namespace

**Better approach:** Use `ChangeType` for each specific class (see Option 2)

## Trade-offs

### Advantages
- Simple, concise recipe (4 steps)
- Wildcard dependency matching reduces verbosity
- Composite recipes handle related changes

### Disadvantages
- Package migration may be too aggressive
- Less precise control over what gets changed
- May require manual fixes for over-migrated packages

## Recommendation
Use Option 1 if:
- You want quick migration with manual cleanup
- Project has limited Dropwizard API surface area
- Willing to review and revert unintended package changes
