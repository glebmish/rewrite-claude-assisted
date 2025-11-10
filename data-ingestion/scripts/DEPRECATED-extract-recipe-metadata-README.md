# Deprecated: extract-recipe-metadata.gradle.kts

## Why it was deprecated

The init script approach (`extract-recipe-metadata.gradle.kts`) only found ~20 recipes because:

- Init scripts have a **separate classpath** from the project
- It only included `rewrite-core` in the init script dependencies
- When `Environment.builder().scanRuntimeClasspath()` ran, it only found recipes in rewrite-core

## The Fix

Replaced with `recipe-metadata-task.gradle.kts` which:

- Is **applied to the project** (`apply(from = "...")`)  
- Has access to **all project dependencies** (rewrite-java, rewrite-spring, rewrite-testing-frameworks, etc.)
- Finds **thousands of recipes** instead of just ~20

The `02b-generate-structured-data.sh` script now:
1. Backs up `build.gradle.kts`
2. Temporarily applies the task script
3. Runs `extractRecipeMetadata`
4. Restores the original `build.gradle.kts`

This ensures metadata extraction sees the same recipes as documentation generation.
