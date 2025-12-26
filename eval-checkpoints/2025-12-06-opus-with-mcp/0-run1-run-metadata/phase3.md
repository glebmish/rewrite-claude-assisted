# Phase 3: Recipe Mapping

## Recipes Created

### Option 1: Broad Approach (`option-1-recipe.yaml`)
- **Name**: `com.example.PRRecipe2Option1`
- **Strategy**: Uses comprehensive migration recipes as foundation
- **Key Recipes**:
  - `org.openrewrite.java.migrate.UpgradeToJava21` (foundation)
  - `org.openrewrite.gradle.UpdateGradleWrapper` (version: 8.5)
  - `org.openrewrite.text.FindAndReplace` (Dockerfile, README gaps)
  - `org.openrewrite.yaml.ChangeValue` (CI step name)

### Option 2: Narrow/Targeted Approach (`option-2-recipe.yaml`)
- **Name**: `com.example.PRRecipe2Option2`
- **Strategy**: Surgical precision with specific recipes for each change
- **Key Recipes**:
  - `org.openrewrite.github.SetupJavaUpgradeJavaVersion` (CI java-version)
  - `org.openrewrite.yaml.ChangeValue` (CI step name)
  - `org.openrewrite.text.FindAndReplace` (Gradle, Dockerfile, README)

## Coverage Analysis

| File | Option 1 | Option 2 |
|------|----------|----------|
| build.gradle (toolchain) | Semantic (UpgradeToJava21) | Text-based |
| build.gradle (wrapper) | Semantic (UpdateGradleWrapper) | Text-based |
| ci.yml (java-version) | Semantic (UpgradeToJava21) | Semantic (SetupJavaUpgradeJavaVersion) |
| ci.yml (step name) | Semantic (ChangeValue) | Semantic (ChangeValue) |
| Dockerfile | Text-based | Text-based |
| README.md | Text-based | Text-based |

## Identified Gaps
- No semantic Dockerfile recipe for image version changes
- No direct README/documentation recipe for version updates

## Output Files
- `option-1-recipe.yaml`
- `option-2-recipe.yaml`
- `option-1-creation-analysis.md`
- `option-2-creation-analysis.md`
