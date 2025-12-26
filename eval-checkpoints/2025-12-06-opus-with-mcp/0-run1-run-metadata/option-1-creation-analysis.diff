# Option 1: Broad Recipe Composition Analysis

## Approach: Wide Net / Comprehensive Migration

This recipe uses the broadest available migration recipes as foundation, supplementing with targeted recipes only for gaps.

## Recipe Mapping

| Intent | Recipe Used | Coverage |
|--------|-------------|----------|
| Java build config (Gradle toolchain) | `org.openrewrite.java.migrate.UpgradeToJava21` | COMPLETE |
| GitHub Actions java-version | `org.openrewrite.github.SetupJavaUpgradeJavaVersion` (via UpgradeToJava21) | COMPLETE |
| Gradle wrapper 8.1->8.5 | `org.openrewrite.gradle.UpdateGradleWrapper` | COMPLETE |
| Dockerfile base images | `org.openrewrite.text.FindAndReplace` | GAP-FILL |
| CI step name | `org.openrewrite.yaml.ChangeValue` | GAP-FILL |
| README.md updates | `org.openrewrite.text.FindAndReplace` | GAP-FILL |

## Key Decisions

### 1. UpgradeToJava21 as Foundation
- **Why**: This composite recipe includes 17+ sub-recipes covering:
  - `UpgradeBuildToJava21` -> handles Gradle toolchain configuration
  - `SetupJavaUpgradeJavaVersion` -> handles GitHub Actions
  - Various deprecated API migrations
  - Switch expression modernization
  - SequencedCollection adoption
- **Trade-off**: May apply more changes than strictly needed for this PR, but ensures comprehensive coverage

### 2. UpdateGradleWrapper Added Separately
- **Why**: UpgradeToJava21 does not include wrapper version upgrade
- `UpdateGradleWrapper` with `version: "8.5"` handles gradle-wrapper.properties

### 3. Gap: Dockerfile Changes
- **Search Results**: Only `FindDockerImageUses` (search-only) found
- **No semantic recipe exists** for changing Docker base image versions
- **Solution**: `text.FindAndReplace` as last resort
- Exact match patterns ensure precision

### 4. Gap: CI Step Name
- **Why not covered**: SetupJavaUpgradeJavaVersion only changes java-version value, not step name
- **Solution**: `yaml.ChangeValue` with JsonPath targeting setup-java steps
- Semantic YAML understanding preserved

### 5. Gap: README.md
- **No semantic recipe** for markdown documentation updates
- **Solution**: `text.FindAndReplace` with specific patterns
- Two separate patterns for different contexts in README

## Coverage Assessment

- **Semantic Coverage**: ~60% (Gradle build, GitHub Actions java-version)
- **Text-based Gap Fill**: ~40% (Dockerfile, step name, README)

## Considerations

1. **Recipe Order**: UpgradeToJava21 runs first (broad changes), then gap-fill recipes
2. **Potential Extra Changes**: UpgradeToJava21 may modernize Java code patterns (switch expressions, etc.) - acceptable for broad approach
3. **Text Recipes Last**: FindAndReplace for README runs last to avoid LST conflicts

## Recipes Searched

- `org.openrewrite.java.migrate.UpgradeToJava21` - PRIMARY
- `org.openrewrite.gradle.UpdateGradleWrapper` - USED
- `org.openrewrite.github.SetupJavaUpgradeJavaVersion` - INCLUDED IN PRIMARY
- `org.openrewrite.docker.search.FindDockerImageUses` - SEARCH ONLY, NOT APPLICABLE
- `org.openrewrite.yaml.ChangeValue` - USED FOR GAP
- `org.openrewrite.text.FindAndReplace` - USED FOR GAPS
