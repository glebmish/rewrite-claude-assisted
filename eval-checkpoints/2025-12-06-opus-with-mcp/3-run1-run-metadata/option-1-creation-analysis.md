# Option 1: Composed Recipe Analysis

## Strategy
Option 1 uses a **composed approach** combining existing OpenRewrite recipes to handle each transformation intent separately.

## Recipe Discovery

### Intent 1: Java Version Upgrade (11 -> 17)
- **Found**: `org.openrewrite.gradle.UpdateJavaCompatibility`
- **Coverage**: Full - handles `java.toolchain.languageVersion` in build.gradle
- **Rationale**: Semantic recipe that understands Gradle DSL structure

### Intent 2: Dropwizard Dependency Upgrades (2.1.12 -> 3.0.0)
- **Found**: `org.openrewrite.gradle.UpgradeDependencyVersion`
- **Coverage**: Full - handles string notation `group:artifact:version`
- **Applied to**: 5 artifacts (core, jdbi3, auth, configuration, testing)

### Intent 3: Import Relocations
- **Found**: `org.openrewrite.java.ChangeType`
- **Coverage**: Full - relocates fully-qualified type references including imports
- **Applied to**: 4 type changes
  - `io.dropwizard.Application` -> `io.dropwizard.core.Application`
  - `io.dropwizard.Configuration` -> `io.dropwizard.core.Configuration`
  - `io.dropwizard.setup.Bootstrap` -> `io.dropwizard.core.setup.Bootstrap`
  - `io.dropwizard.setup.Environment` -> `io.dropwizard.core.setup.Environment`

### Intent 4: Remove @Override Annotations
- **Found**: `org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride`
- **Coverage**: Full - specifically designed for Dropwizard migration
- **Rationale**: Dropwizard 3.x changed `initialize()` and `run()` from abstract methods to concrete methods with default implementations

## Coverage Summary

| Intent | Recipe | Coverage |
|--------|--------|----------|
| Java 11 -> 17 | UpdateJavaCompatibility | 100% |
| Dropwizard deps | UpgradeDependencyVersion (x5) | 100% |
| Import relocations | ChangeType (x4) | 100% |
| @Override removal | RemoveUnnecessaryOverride | 100% |

## Gaps Identified
**None** - All transformations from the PR diff are covered by existing semantic recipes.

## Recipe Choice Rationale

1. **UpdateJavaCompatibility** over UpgradeJavaVersion
   - More targeted for Gradle projects
   - Directly handles toolchain configuration

2. **ChangeType** over ChangePackage
   - ChangePackage affects entire package hierarchy
   - ChangeType is precise for individual class relocations
   - PR shows only 4 specific classes moved, not entire package

3. **RemoveUnnecessaryOverride** (Dropwizard-specific)
   - Discovered in `org.openrewrite.java.dropwizard.method` namespace
   - Semantically validates that methods no longer override parent
   - Safer than generic RemoveAnnotation which would blindly remove

## Considerations

- Recipe ordering: Dependencies upgraded before Java code changes
- All recipes use LST-based transformations (no text manipulation)
- RemoveUnnecessaryOverride is context-aware (checks actual inheritance)
