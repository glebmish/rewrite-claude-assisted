# Phase 3: Recipe Mapping

## Recipe Options Created

### Option 1: Layered Composite Approach
- **File**: `option-1-recipe.yaml`
- **Name**: `com.example.simpleblog.MigrateH2ToPostgreSQLComposite`
- **Strategy**: 6-layer composite with conceptual grouping
- **Recipe Count**: 14 steps organized by transformation type

### Option 2: Surgical Targeted Approach
- **File**: `option-2-recipe.yaml`
- **Name**: `com.example.simpleblog.MigrateH2ToPostgreSQLTargeted`
- **Strategy**: Explicit step-by-step transformation
- **Recipe Count**: 14 steps with goal annotations

## Coverage Analysis

**Complete Semantic Coverage (100%)**:
- Gradle dependency management (remove H2, add PostgreSQL + Testcontainers)
- YAML configuration property changes (driver, credentials, dialect)

**Partial Coverage (60-75%)**:
- SQL syntax transformation (text-based fallback)
- GitHub Actions version bump (text-based fallback)
- Dockerfile base image change (text-based fallback)
- Build file comments (text-based fallback)

## Recipe Discovery Findings

**Available Recipes Used**:
- `org.openrewrite.gradle.RemoveDependency`
- `org.openrewrite.gradle.AddDependency`
- `org.openrewrite.yaml.ChangePropertyValue`
- `org.openrewrite.text.FindAndReplace`

**Gaps Identified**:
- No semantic Dockerfile recipes exist
- No semantic SQL transformation recipes exist
- Limited GitHub Actions workflow support

## Key Differences

**Option 1 Advantages**:
- Conceptual clarity with layers
- More concise
- Standard migration pattern
- Easier maintenance

**Option 2 Advantages**:
- Maximum transparency
- Granular control
- Better for incremental adoption
- Easier to customize

## Validation Required

Both recipes require validation to:
1. Verify correct execution on target repository
2. Compare output with PR diff
3. Identify any gaps in coverage
4. Measure effectiveness
