# Option 2: Targeted Approach Analysis

## Strategy: Maximum Precision with Atomic Recipes

This recipe uses individual, atomic recipes for each transformation, providing explicit control over every change.

## Recipe Discovery Process

### Intent 1: Java Version Upgrade (11 -> 17)

**Search queries used:**
- "Change Java toolchain version in Gradle"
- "Update Java version in build.gradle"
- "Gradle Java language version"

**Recipe selected:** `org.openrewrite.gradle.UpdateJavaCompatibility`
- Handles `java.toolchain.languageVersion` in build.gradle
- Semantically understands Gradle DSL structure
- Parameter: `version: 17`

**Alternative considered:** `org.openrewrite.java.migrate.UpgradeJavaVersion`
- Composite recipe that includes UpdateJavaCompatibility
- Rejected: Too broad for targeted approach

### Intent 2: Dropwizard Dependencies (2.1.12 -> 3.0.0)

**Search queries used:**
- "Upgrade Gradle dependency version"
- "Change dependency version in Gradle"

**Recipe selected:** `org.openrewrite.gradle.UpgradeDependencyVersion` (x5)
- Understands Gradle dependency declaration patterns
- Handles both String notation (`"group:artifact:version"`) and Map notation
- Each dependency upgraded explicitly:
  - dropwizard-core
  - dropwizard-jdbi3
  - dropwizard-auth
  - dropwizard-configuration
  - dropwizard-testing

**Why not wildcards?** Using `artifactId: dropwizard-*` could work but explicit listing provides:
- Clear documentation of what changes
- Ability to version differently if needed
- No unexpected dependency upgrades

### Intent 3: Import Relocations

**Search queries used:**
- "Change Java import statement"
- "ChangeType Java import"
- "io.dropwizard.Application to io.dropwizard.core.Application"

**Recipe selected:** `org.openrewrite.java.ChangeType` (x4)
- Type-safe transformation using LST
- Handles imports, type references, and fully qualified names
- Explicit mappings:
  - `io.dropwizard.Application` -> `io.dropwizard.core.Application`
  - `io.dropwizard.Configuration` -> `io.dropwizard.core.Configuration`
  - `io.dropwizard.setup.Bootstrap` -> `io.dropwizard.core.setup.Bootstrap`
  - `io.dropwizard.setup.Environment` -> `io.dropwizard.core.setup.Environment`

**Alternative considered:** `org.openrewrite.java.ChangePackage`
- Would change entire `io.dropwizard` package
- Rejected: Too broad - would affect classes that don't move

### Intent 4: Remove @Override Annotations

**Search queries used:**
- "Remove @Override annotation"
- "Remove unnecessary override"
- "Override annotation removal"

**Recipe selected:** `org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride`
- Dropwizard-specific recipe
- Intelligently detects when @Override is no longer valid
- Works with type resolution to verify method signatures

**Alternative considered:** `org.openrewrite.java.RemoveAnnotation`
- Pattern-based: `@java.lang.Override`
- Rejected: Would remove ALL @Override annotations, not just invalid ones

## Coverage Analysis

| Intent | Coverage | Recipe |
|--------|----------|--------|
| Java 11 -> 17 | COMPLETE | UpdateJavaCompatibility |
| Dependency upgrades (5) | COMPLETE | UpgradeDependencyVersion x5 |
| Import relocations (4) | COMPLETE | ChangeType x4 |
| @Override removal | COMPLETE | RemoveUnnecessaryOverride |

**Total coverage: 100%**

## Trade-offs vs Option 1 (Broad Approach)

| Aspect | Option 2 (Targeted) | Option 1 (Broad) |
|--------|---------------------|------------------|
| Precision | HIGH - explicit control | MEDIUM - may include extras |
| Verbosity | HIGH - 12 recipe invocations | LOW - fewer recipes |
| Maintainability | Requires updates per change | Adapts automatically |
| Transparency | Every change visible | Some changes implicit |
| Risk | LOW - predictable | MEDIUM - broader scope |

## Considerations

1. **Recipe ordering**: Dependencies upgraded before type changes to ensure correct resolution
2. **No conflicts**: Each recipe operates on distinct concerns
3. **Testing**: Run on subset of files first to validate behavior
4. **Extensibility**: Easy to add/remove specific transformations
