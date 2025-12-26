# Option 3 Creation Analysis

## Strategy: Refined Hybrid Approach

Combines learnings from Option 1 and Option 2 to maximize semantic recipe usage while maintaining 100% precision.

## What Worked in Previous Options

**Option 1 (Broad - UpgradeToJava21):**
- `SetupJavaUpgradeJavaVersion` correctly updated GitHub Actions java-version
- Over-applied due to Java code modernization recipes (isEmpty(), getFirst())
- Over-applied due to Gradle wrapper file updates
- Over-applied due to Guava dependency upgrade

**Option 2 (Narrow - Text Replacements):**
- Achieved 100% F1 score with perfect precision and recall
- `SetupJavaUpgradeJavaVersion` worked correctly
- `ChangeValue` YAML recipe worked correctly for step name
- Text replacements handled all other cases precisely

## Option 3 Recipe Composition

| Change | Recipe Type | Justification |
|--------|-------------|---------------|
| GH Actions java-version | SEMANTIC (`SetupJavaUpgradeJavaVersion`) | Understands setup-java action structure |
| GH Actions step name | SEMANTIC (`ChangeValue`) | JSONPath-based YAML transformation |
| Gradle wrapper version | TEXT (`FindAndReplace`) | No semantic recipe for wrapper{} block |
| Gradle toolchain migration | TEXT (`FindAndReplace`) | `UpdateJavaCompatibility` only updates values, not structure |
| Dockerfile base images | TEXT (`FindAndReplace`) | No semantic Dockerfile transformation recipe |
| README.md updates | TEXT (`FindAndReplace`) | No semantic markdown recipe |

## Semantic Recipe Analysis

### Recipes Used (2 semantic, 6 text)

1. **`SetupJavaUpgradeJavaVersion`** - Semantic understanding of GitHub Actions setup-java
2. **`ChangeValue`** - Semantic YAML manipulation with JSONPath

### Recipes NOT Used (and why)

- **`UpgradeToJava21`** - Too broad, includes code modernization and dependency upgrades
- **`UpdateJavaCompatibility`** - Only updates existing syntax, doesn't migrate to toolchain
- **`UpdateGradleWrapper`** - Updates wrapper files, not the DSL block in build.gradle
- **`UpgradeJavaVersion`** - Composite recipe including `UpdateJavaCompatibility`

## Expected Outcome

This recipe should achieve the same 100% F1 score as Option 2 because:
- It uses identical transformations for all 8 changes
- The 2 semantic recipes (`SetupJavaUpgradeJavaVersion`, `ChangeValue`) are the same as Option 2
- Text replacements are identical to Option 2

## Key Insight

For this specific PR, most changes require text-based recipes because:
1. Dockerfile transformations lack semantic recipes
2. Gradle toolchain migration (structural change) lacks semantic support
3. README/documentation updates lack semantic recipes
4. The semantic `UpdateJavaCompatibility` recipe doesn't perform the required structural transformation

The value of semantic recipes here is limited to GitHub Actions YAML, where both the java-version and step name changes can use LST-aware transformations.
