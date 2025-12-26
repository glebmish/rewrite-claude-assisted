# Option 3 - Precision Refined Recipe Analysis

## Problem Addressed

Options 1 and 2 both achieved 100% recall but only 95.65% precision due to a false positive:
- `RemoveUnnecessaryOverride` incorrectly removed `@Override` from `DatabaseHealthCheck.check()`
- This method DOES override `com.codahale.metrics.health.HealthCheck.check()` - a valid override

## Root Cause

The `RemoveUnnecessaryOverride` recipe removes `@Override` from ALL methods that don't override anything in the current type hierarchy. The recipe was applied globally, affecting:
- `TaskApplication.initialize()` - correct (no longer overrides in DW 3.x)
- `TaskApplication.run()` - correct (no longer overrides in DW 3.x)
- `DatabaseHealthCheck.check()` - INCORRECT (still overrides HealthCheck.check())

## Solution: Scoped Preconditions

Option 3 uses OpenRewrite's precondition mechanism to scope the `RemoveUnnecessaryOverride` recipe:

```yaml
preconditions:
  - org.openrewrite.java.search.FindImplementations:
      typeName: io.dropwizard.core.Application
```

This ensures:
1. `RemoveUnnecessaryOverride` only runs on files containing `Application` subclasses
2. `DatabaseHealthCheck.java` is excluded (doesn't extend Application)
3. `TaskApplication.java` is included (extends Application)

## Recipe Structure

The recipe uses a two-document YAML approach:
1. **Main recipe** (`com.example.PR3Option3`): Orchestrates all transformations
2. **Helper recipe** (`com.example.PR3Option3.ScopedOverrideRemoval`): Has precondition for scoped execution

## Key Differences from Options 1/2

| Aspect | Options 1/2 | Option 3 |
|--------|-------------|----------|
| @Override removal scope | Global | Scoped to Application subclasses |
| Precision risk | False positives possible | Minimized |
| Recipe complexity | Single recipe | Nested with precondition |

## Expected Outcome

- **Precision**: 100% (no false positives on HealthCheck)
- **Recall**: 100% (all intended changes applied)

## Recipes Used

1. `org.openrewrite.gradle.UpdateJavaCompatibility` - Java 17 upgrade
2. `org.openrewrite.gradle.UpgradeDependencyVersion` - Dropwizard 3.0.0
3. `org.openrewrite.java.ChangeType` - Import relocations
4. `org.openrewrite.java.search.FindImplementations` - Precondition
5. `org.openrewrite.java.dropwizard.method.RemoveUnnecessaryOverride` - Scoped @Override removal
