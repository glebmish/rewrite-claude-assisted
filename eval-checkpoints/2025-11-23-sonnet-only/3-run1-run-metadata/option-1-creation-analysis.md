# Option 1: Broad Approach - Creation Analysis

## Strategy
Uses Java migration foundation (`UpgradeJavaVersion`) combined with Dropwizard-specific transformations

## Intent Coverage Mapping

### 1. Java Version Upgrade (11 → 17)
**Recipe**: `org.openrewrite.java.migrate.UpgradeJavaVersion`
- **Coverage**: Complete - Updates toolchain in build.gradle
- **Scope**: Comprehensive Java 17 migration including deprecated API replacements
- **Note**: This is a composite recipe containing ~180 sub-recipes for Java version migration

### 2. Dropwizard Dependency Updates (2.1.12 → 3.0.0)
**Recipes**: 5x `org.openrewrite.gradle.UpgradeDependencyVersion`
- **Coverage**: Complete - All 5 dependencies explicitly upgraded
- **Dependencies covered**:
  - dropwizard-core
  - dropwizard-jdbi3
  - dropwizard-auth
  - dropwizard-configuration
  - dropwizard-testing

### 3. Package Reorganization (io.dropwizard → io.dropwizard.core)
**Recipes**: 4x `org.openrewrite.java.ChangeType`
- **Coverage**: Complete - All identified package relocations
- **Classes migrated**:
  - Application
  - Bootstrap
  - Environment
  - Configuration

### 4. Remove @Override Annotations
**Recipe**: `org.openrewrite.java.RemoveAnnotation`
- **Coverage**: Partial - Removes ALL @Override annotations
- **Gap**: Too broad - removes @Override from ALL methods, not just initialize() and run()
- **Impact**: May remove legitimate @Override annotations from other methods

## Gap Analysis

### Critical Gap: @Override Removal Precision
The PR shows @Override removed only from `initialize()` and `run()` methods in Application subclasses. However, `RemoveAnnotation` with pattern `@java.lang.Override` removes ALL @Override annotations project-wide.

**Why this gap exists**:
- No built-in recipe for conditional annotation removal based on method name
- RemoveAnnotation operates on all occurrences matching the pattern
- Requires custom recipe or manual cleanup

**Alternatives considered**:
1. Accept broad removal, manually re-add where needed (not ideal)
2. Omit this step, handle manually (recommended)
3. Write custom recipe with method-name filtering (best but requires development)

## Advantages
- **Comprehensive**: UpgradeJavaVersion provides future-proofing for Java 17 features
- **Minimal recipe count**: Single Java migration recipe vs many individual recipes
- **Maintained**: Leverages well-tested OpenRewrite Java migration recipes
- **Discovery**: May catch additional Java 11→17 issues not in original PR

## Disadvantages
- **Scope creep**: Changes beyond PR scope (180+ sub-recipes in UpgradeJavaVersion)
- **Testing burden**: Must validate all Java migration changes, not just Dropwizard
- **@Override precision**: Cannot selectively remove annotations
- **Potential conflicts**: Java migration may interact with Dropwizard 2.x→3.0 changes

## Recipe Ordering
1. Java version upgrade first (foundation)
2. Dependency updates second (new APIs available)
3. Package migrations third (use new package structure)
4. Annotation removal last (cleanup)

## Recommendation
Best for teams wanting comprehensive Java 17 modernization alongside Dropwizard upgrade. Accept that @Override removal requires manual review or omission of that step.
