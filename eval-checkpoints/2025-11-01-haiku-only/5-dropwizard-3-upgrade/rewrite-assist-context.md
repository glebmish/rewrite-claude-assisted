# Dropwizard 2.1 to 3.0 Migration Recipe Analysis

## Available Recipes

### Option 1: Comprehensive Approach
**Recipe Composition**:
1. **Dependency Update**
   - Recipe: `org.openrewrite.maven.UpgradeDependencyVersion`
   - Applies to: Dropwizard core dependencies
   - Configuration:
     ```yaml
     - org.openrewrite.maven.UpgradeDependencyVersion:
         groupId: io.dropwizard
         artifactId: dropwizard-core
         newVersion: 3.0.0
     ```

2. **Package/Import Migration**
   - Recipe: `org.openrewrite.java.ChangePackage`
   - Applies to: Dropwizard core package migrations
   - Specific Mappings:
     ```yaml
     - org.openrewrite.java.ChangePackage:
         oldPackageName: io.dropwizard.setup
         newPackageName: io.dropwizard.core.setup
     - org.openrewrite.java.ChangePackage:
         oldPackageName: io.dropwizard
         newPackageName: io.dropwizard.core
     ```

3. **Java Version Upgrade**
   - Recipe: `org.openrewrite.java.migrate.Java11toJava17`
   - Applies to: Java language version migration
   - Handles: Language feature compatibility, deprecated API updates

### Option 2: Targeted Surgical Approach
**Recipe Composition**:
1. **Specific Import Replacements**
   - Recipe: `org.openrewrite.java.ChangeType`
   - Mappings:
     ```yaml
     - org.openrewrite.java.ChangeType:
         oldFullyQualifiedTypeName: io.dropwizard.Application
         newFullyQualifiedTypeName: io.dropwizard.core.Application
     - org.openrewrite.java.ChangeType:
         oldFullyQualifiedTypeName: io.dropwizard.setup.Bootstrap
         newFullyQualifiedTypeName: io.dropwizard.core.setup.Bootstrap
     - org.openrewrite.java.ChangeType:
         oldFullyQualifiedTypeName: io.dropwizard.setup.Environment
         newFullyQualifiedTypeName: io.dropwizard.core.setup.Environment
     - org.openrewrite.java.ChangeType:
         oldFullyQualifiedTypeName: io.dropwizard.Configuration
         newFullyQualifiedTypeName: io.dropwizard.core.Configuration
     ```

2. **Annotation Removal**
   - Recipe: `org.openrewrite.staticanalysis.RemoveUnusedModifiers`
   - Handles: Removing unnecessary @Override annotations

## Gaps and Limitations
- No direct Dropwizard 2.1 to 3.0 migration recipe exists
- Manual review still recommended for semantic changes
- No automatic handling of potential runtime configuration changes

## Recommended Approach
1. Run comprehensive approach first
2. Manually verify and test each transformed component
3. Pay special attention to:
   - Runtime configuration
   - Any potential breaking API changes in Dropwizard 3.0
   - Verify all imports and package migrations

## Testing Recommendations
- Use existing test suite to validate migrations
- Create integration tests to confirm Dropwizard 3.0 compatibility
- Perform gradual rollout and validation

## Notes
- MySQL Connector and Mockito versions remain unchanged
- No javax/Jakarta migration required in this scope