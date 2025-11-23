# Option 2: Targeted Approach - Creation Analysis

## Strategy
Surgical, minimal changes matching PR scope exactly - only Dropwizard 3.0 requirements

## Intent Coverage Mapping

### 1. Java Toolchain Update (11 → 17)
**Recipe**: `org.openrewrite.gradle.UpdateJavaCompatibility`
- **Coverage**: Complete - Updates `java.toolchain.languageVersion` to 17
- **Scope**: Minimal - Only toolchain configuration, no API migrations
- **Precision**: Exact match to PR changes

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
  - Configuration
  - Bootstrap
  - Environment
- **Semantic approach**: Uses LST to understand Java type system, not text replacement

### 4. Remove @Override Annotations
**Coverage**: NOT COVERED
- **Intentional omission**: No precise recipe exists for selective removal
- **Recommendation**: Manual removal or accept as gap

## Gap Analysis

### Identified Gap: @Override Annotation Removal
**Why not covered**:
- `RemoveAnnotation` operates globally on pattern matches
- No recipe exists for method-name-conditional annotation removal
- Would require custom recipe development

**Manual steps required**:
1. Remove `@Override` from `initialize(Bootstrap<T>)` methods
2. Remove `@Override` from `run(T, Environment)` methods in Application subclasses
3. Keep `@Override` on all other method overrides

**Custom recipe approach** (if needed):
```java
// Pseudo-recipe logic needed
public class RemoveOverrideFromDropwizardMethods extends Recipe {
    @Override
    public TreeVisitor<?, ExecutionContext> getVisitor() {
        return new JavaIsoVisitor<>() {
            @Override
            public J.MethodDeclaration visitMethodDeclaration(
                J.MethodDeclaration method, ExecutionContext ctx) {

                // Check if method is initialize() or run()
                if (isApplicationMethod(method)) {
                    // Remove @Override annotation
                    return removeAnnotation(method, Override.class);
                }
                return method;
            }
        };
    }
}
```

## Advantages
- **Minimal scope**: Only changes required for Dropwizard 3.0 compatibility
- **Predictable**: No surprise transformations from broad Java migration
- **Testable**: Smaller change surface = easier validation
- **PR alignment**: Matches intent exactly (except @Override gap)
- **Lower risk**: Fewer moving parts, less potential for conflicts

## Disadvantages
- **Incomplete**: Missing @Override removal (requires manual step)
- **No modernization**: Doesn't adopt Java 17 features
- **Future work**: May need additional recipes later for full Java 17 adoption

## Recipe Ordering
1. Toolchain update first (build requirement)
2. Dependency updates second (framework version)
3. Package migrations third (code compatibility)

## Comparison to Option 1

| Aspect | Option 1 (Broad) | Option 2 (Targeted) |
|--------|------------------|---------------------|
| Java migration | ~180 recipes | 1 recipe (toolchain only) |
| @Override handling | Too broad | Gap (manual) |
| Scope | PR + modernization | PR only |
| Risk | Higher | Lower |
| Testing effort | Extensive | Moderate |

## Recommendation
Best for teams wanting minimal disruption and precise control. Accept manual @Override cleanup as acceptable trade-off for reduced scope. Add Java 17 feature adoption recipes later if desired.
