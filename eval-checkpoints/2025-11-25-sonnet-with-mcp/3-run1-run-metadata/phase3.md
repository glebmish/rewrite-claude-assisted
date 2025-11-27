# Phase 3: Recipe Mapping

## Recipe Discovery Results
No Dropwizard 3.0-specific migration recipe exists in OpenRewrite ecosystem. All transformations composed from semantic recipes.

## Option 1: Comprehensive Approach
- **Recipe Name**: `com.example.tasks.UpgradeDropwizard3Comprehensive`
- **File**: `option-1-recipe.yaml`
- **Strategy**: Broad recipes with wildcard dependency matching
- **Components**: Java 17 upgrade + bulk dependency update + type migrations + cleanup
- **Advantages**: Simple composition, minimal configuration, leverages composite recipes

## Option 2: Surgical Approach
- **Recipe Name**: `com.example.DropwizardUpgrade30Surgical`
- **File**: `option-2-recipe.yaml`
- **Strategy**: Narrow recipes with explicit control
- **Components**: Java 17 upgrade + 5 individual dependency updates + type migrations + cleanup
- **Advantages**: Maximum control, clear audit trail, incremental capable

## Coverage Analysis
All intents from Phase 2 are fully covered:
1. Java toolchain update (11 → 17)
2. Dropwizard dependency updates (2.1.12 → 3.0.0)
3. Package migrations (io.dropwizard.* → io.dropwizard.core.*)
4. @Override annotation removal

## Status
Phase 3 completed successfully. Two recipe options ready for validation.
