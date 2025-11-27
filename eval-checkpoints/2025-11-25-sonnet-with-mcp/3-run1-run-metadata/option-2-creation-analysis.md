# Option 2: Surgical Approach - Analysis

## Strategy Overview

Option 2 uses **narrow, specific recipes** for surgical precision and maximum control. Each transformation is explicitly defined with individual recipe steps, allowing fine-grained control over the migration process.

## Recipe Composition

### 1. Java Toolchain Update (Step 1)
**Recipe**: `org.openrewrite.java.migrate.UpgradeJavaVersion`
- **Purpose**: Updates Java toolchain from 11 to 17 in build.gradle
- **Semantic approach**: Uses Gradle DSL understanding to modify `java.toolchain.languageVersion`
- **Why chosen**: Comprehensive recipe that handles multiple build file formats and related configurations

### 2. Dependency Version Updates (Step 2)
**Recipe**: `org.openrewrite.gradle.UpgradeDependencyVersion` (5 instances)
- **Purpose**: Update each Dropwizard dependency individually from 2.1.12 to 3.0.0
- **Semantic approach**: Understands Gradle dependency DSL syntax (both string and map notation)
- **Why chosen**: Precise control over each dependency upgrade
- **Dependencies updated**:
  - dropwizard-core
  - dropwizard-jdbi3
  - dropwizard-auth
  - dropwizard-configuration
  - dropwizard-testing

### 3. Package Migration (Step 3)
**Recipe**: `org.openrewrite.java.ChangeType` (4 instances)
- **Purpose**: Migrate Dropwizard core classes from `io.dropwizard.*` to `io.dropwizard.core.*`
- **Semantic approach**: Uses LST to update imports, fully-qualified types, and type references
- **Why chosen**: Type-aware transformation that handles all references (imports, FQNs, etc.)
- **Types migrated**:
  - `io.dropwizard.Application` → `io.dropwizard.core.Application`
  - `io.dropwizard.Configuration` → `io.dropwizard.core.Configuration`
  - `io.dropwizard.setup.Bootstrap` → `io.dropwizard.core.setup.Bootstrap`
  - `io.dropwizard.setup.Environment` → `io.dropwizard.core.setup.Environment`

### 4. Remove Unnecessary Override Annotations (Step 4)
**Recipe**: `org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride`
- **Purpose**: Remove @Override from Application methods (initialize, run) that no longer override
- **Semantic approach**: Analyzes method signatures and inheritance hierarchy to determine validity
- **Why chosen**: Dropwizard-specific recipe that understands the framework's API changes

## Advantages of Surgical Approach

1. **Maximum Control**: Each transformation is explicit and can be individually enabled/disabled
2. **Clear Audit Trail**: Easy to see exactly what changes will be applied
3. **Incremental Migration**: Can apply subsets of transformations for gradual migration
4. **Targeted Changes**: Only affects specified types and dependencies
5. **Minimal Surprise**: No unexpected transformations from broad recipes

## Disadvantages

1. **Verbosity**: Requires listing each dependency and type migration individually
2. **Maintenance**: Need to add new entries for additional Dropwizard modules
3. **Potential Gaps**: May miss implicit transformations that broad recipes would catch
4. **Manual Discovery**: Requires knowing all specific types that need migration

## Coverage Analysis

### Complete Coverage
- ✓ Java toolchain upgrade (11 → 17)
- ✓ All 5 Dropwizard dependencies updated to 3.0.0
- ✓ Core package migrations (Application, Configuration, Bootstrap, Environment)
- ✓ @Override annotation cleanup

### Potential Gaps
- Other Dropwizard classes beyond the 4 core types may need migration
- Additional Dropwizard modules not in build.gradle won't be addressed
- Custom code using other moved packages would require additional ChangeType entries

## Gap Mitigation Strategy

If additional package migrations are discovered:
1. Add more `org.openrewrite.java.ChangeType` entries for each affected class
2. Pattern: Each migrated class requires one explicit ChangeType recipe instance
3. Alternative: Could switch to `org.openrewrite.java.ChangePackage` for broader coverage if many types need migration

## Comparison to Option 1

Option 1 would use broader recipes like:
- A comprehensive Dropwizard 3.0 migration recipe (if it exists)
- Bulk dependency updates
- Package-level migrations instead of type-level

Option 2 provides more control at the cost of more verbose configuration.

## Recommendation Use Cases

Choose Option 2 when:
- You need precise control over which dependencies are updated
- You want to review each transformation type individually
- You're doing incremental migration and need to control timing
- Your codebase has customizations that need careful handling
- Risk mitigation is critical and you want to understand every change

## Recipe Execution Order

The recipe steps execute in sequence:
1. Java version (foundation for other changes)
2. Dependencies (updates artifact versions)
3. Type migrations (adapts code to new packages)
4. Cleanup (removes now-invalid annotations)

This order ensures each transformation builds on the previous one.
