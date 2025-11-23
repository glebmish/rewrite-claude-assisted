# Phase 3: Recipe Mapping

## Recipe Discovery and Composition

Two recipe options created using openrewrite-expert subagent.

### Option 1: Broad Recipe Approach
**File:** option-1-recipe.yaml
**Recipe Name:** com.ecommerce.catalog.PRRecipe2Option1
**Strategy:** Use comprehensive UpgradeToJava21 recipe with targeted gap-filling

**Composition:**
* org.openrewrite.java.migrate.UpgradeToJava21 (foundation)
* org.openrewrite.gradle.UpdateGradleWrapper (Gradle 8.5)
* FindAndReplace recipes for infrastructure files (Docker, GitHub Actions, README)

**Coverage:** 60% semantic + 40% text-based

### Option 2: Surgical Targeted Approach
**File:** option-2-recipe.yaml
**Recipe Name:** com.ecommerce.catalog.PRRecipe2Option2
**Strategy:** Narrow recipes matching exact PR changes only

**Composition:**
* Specific recipes for Gradle and GitHub Actions
* FindAndReplace recipes for all other transformations
* No broad migration recipes

**Coverage:** 25% semantic + 75% text-based

## Key Findings

### Recipe Gaps Identified
* No semantic recipe for Gradle sourceCompatibility → toolchain migration
* No Docker LST parser (text-based approach required)
* GitHub Actions recipes only update parameters, not step names

### Files Created
* /.output/2025-11-22-21-59/option-1-recipe.yaml
* /.output/2025-11-22-21-59/option-2-recipe.yaml
* /.output/2025-11-22-21-59/option-1-creation-analysis.md
* /.output/2025-11-22-21-59/option-2-creation-analysis.md
