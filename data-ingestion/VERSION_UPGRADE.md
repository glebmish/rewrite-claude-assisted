# OpenRewrite Version Upgrade Guide

This document describes how to upgrade OpenRewrite versions in the data-ingestion pipeline.

## Version Update Checklist

When upgrading OpenRewrite to a new version, update these **2 locations**:

### 1. Update `scripts/01-setup-generator.sh`

At the top of the file, update the version variables (lines 17-20):

```bash
# Version configuration - UPDATE THESE when bumping OpenRewrite versions
REWRITE_VERSION="${REWRITE_VERSION:-8.64.0}"          # ← Update this
MODERNE_BOM_VERSION="${MODERNE_BOM_VERSION:-0.21.0}"  # ← Update this if needed
SPRING_QUARKUS_VERSION="${SPRING_QUARKUS_VERSION:-0.2.0}"  # ← Update this if needed
```

### 2. Update `scripts/extract-recipe-metadata.gradle.kts`

At the top of the file, update the version variable (line 34):

```kotlin
// Version configuration - UPDATE THIS when bumping OpenRewrite versions
// MUST match the version pinned in 01-setup-generator.sh
val rewriteVersion = "8.64.0"  // ← Update this
```

## Important Notes

- The `rewriteVersion` in **both files MUST match** to avoid API compatibility issues
- The versions can be overridden via environment variables if needed:
  ```bash
  export REWRITE_VERSION=8.70.0
  export MODERNE_BOM_VERSION=0.22.0
  ./scripts/01-setup-generator.sh
  ```
- Recipe counts vary between versions - they are **not** hardcoded in comments

## Why This Approach

- **Centralized**: All versions defined at the top of their respective files
- **Discoverable**: Clear comments indicate what needs updating
- **Flexible**: Can override via environment variables
- **Maintainable**: Only 2 locations to update instead of 8+ scattered hardcoded strings
