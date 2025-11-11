# OpenRewrite Version Upgrade Guide

This document describes how to upgrade OpenRewrite versions in the data-ingestion pipeline.

## Version Update Checklist

When upgrading OpenRewrite to a new version, update these **2 locations**:

### 1. Update `scripts/01-setup-generator.sh`

At the top of the file, update the version variables (lines 14-16):

```bash
# Version configuration - UPDATE THESE when bumping OpenRewrite versions
REWRITE_VERSION="${REWRITE_VERSION:-8.64.0}"          # ← Update this
MODERNE_BOM_VERSION="${MODERNE_BOM_VERSION:-0.21.0}"  # ← Update this if needed
SPRING_QUARKUS_VERSION="${SPRING_QUARKUS_VERSION:-0.2.0}"  # ← Update this if needed
```

### 2. Update `scripts/extract-recipe-metadata.gradle.kts`

In the buildscript block, update the rewrite-core version (line 43):

```kotlin
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        // UPDATE THIS VERSION when bumping OpenRewrite: currently 8.64.0
        classpath("org.openrewrite:rewrite-core:8.64.0")  // ← Update this
        classpath("com.fasterxml.jackson.core:jackson-databind:2.18.0")
    }
}
```

**Note**: The version must be hardcoded in the buildscript block due to Gradle's evaluation order. Variables defined outside buildscript blocks cannot be accessed inside them.

## Important Notes

- The `rewrite-core` version in **both files MUST match** to avoid API compatibility issues
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
