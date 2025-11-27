# Option 1: Comprehensive Dropwizard 3.0 Upgrade Analysis

## Recipe Strategy: Broad Approach

This option leverages existing OpenRewrite recipes to provide comprehensive migration coverage with minimal custom configuration.

## Intent Coverage

### 1. Java Toolchain Upgrade (11 → 17)
**Recipe:** `org.openrewrite.java.migrate.UpgradeJavaVersion`
- Updates `java.toolchain.languageVersion` in build.gradle
- Composite recipe that includes Gradle compatibility updates
- **Coverage:** Complete ✓

### 2. Dropwizard Dependency Upgrades (2.1.12 → 3.0.0)
**Recipe:** `org.openrewrite.gradle.UpgradeDependencyVersion`
- Single recipe with wildcard artifactId to upgrade all Dropwizard dependencies
- Handles: dropwizard-core, dropwizard-jdbi3, dropwizard-auth, dropwizard-configuration, dropwizard-testing
- Uses semantic understanding of Gradle DSL structure
- **Coverage:** Complete ✓

### 3. Package Import Migrations (io.dropwizard → io.dropwizard.core)
**Recipe:** `org.openrewrite.java.ChangeType` (4 instances)
- Type-aware semantic transformations for:
  - Application
  - Configuration
  - setup.Bootstrap
  - setup.Environment
- Updates imports, fully-qualified references, and type declarations
- **Coverage:** Complete ✓

### 4. Remove @Override Annotations
**Recipe:** `org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride`
- Specifically designed for Dropwizard migration scenarios
- Removes @Override from methods that don't actually override/implement
- Handles initialize() and run() methods in Application classes
- **Coverage:** Complete ✓

## Recipe Composition Rationale

**Layered Approach:**
1. **Foundation:** Java version upgrade establishes new language level
2. **Dependencies:** Bulk dependency update via wildcard matching
3. **Code Migration:** Type changes handle package restructuring
4. **Cleanup:** Remove incorrect annotations

**Why Broad Recipes:**
- Leverages composite recipe `UpgradeJavaVersion` which includes multiple sub-recipes for Java 17 compatibility
- Wildcard dependency matching reduces recipe count while maintaining comprehensive coverage
- `ChangeType` is semantically precise - understands Java type system rather than text replacement
- Specialized Dropwizard recipe for annotation cleanup

## Gap Analysis

**No Gaps Identified:**
- All identified intents from PR analysis are covered by existing recipes
- No custom recipe development required
- No text-based transformations needed

## Alternative Considerations

**Potential Enhancements:**
- Could add `org.openrewrite.java.migrate.UpgradeToJava17` for additional Java 17 features (text blocks, pattern matching)
- Not included as PR doesn't show adoption of Java 17 language features
- Focus is migration compatibility, not feature adoption

## Recipe Ordering

**Dependencies:**
1. Java version first - establishes baseline for all subsequent transformations
2. Dependency upgrades next - ensures correct classpath for type resolution
3. Type changes - require upgraded dependencies to resolve new package structure
4. Annotation cleanup last - requires updated types to determine override validity

## Testing Recommendations

- Verify build.gradle toolchain updated to Java 17
- Confirm all 5 Dropwizard dependencies upgraded to 3.0.0
- Check all imports changed to io.dropwizard.core.* packages
- Validate @Override removed from initialize() and run() methods
- Ensure application still compiles and runs

## Risk Assessment

**Low Risk:**
- All recipes are semantic and LST-based
- No text manipulation or regex-based changes
- Well-tested recipes from official OpenRewrite repository
- Dropwizard-specific recipe indicates community validation
