---
name: openrewrite-assist
description: |
  Automated OpenRewrite recipe discovery and validation from GitHub PRs.
  Use when: analyzing PR changes to find matching OpenRewrite recipes,
  validating recipe effectiveness, creating automated refactoring workflows.
  Triggers on: "find recipes for this PR", "create OpenRewrite recipe",
  "automate this refactoring", "analyze PR for recipe opportunities".
version: 1.0.0
---

# OpenRewrite Assist Skill

## Overview

This skill enables AI-powered discovery and validation of OpenRewrite recipes by analyzing GitHub Pull Request changes. It maps code transformations to existing OpenRewrite recipes and validates their effectiveness through empirical testing.

## When to Use This Skill

- Analyzing a GitHub PR to find applicable OpenRewrite recipes
- Creating automated refactoring configurations from manual code changes
- Validating whether OpenRewrite recipes correctly replicate PR changes
- Migrating framework versions (Spring Boot, JUnit, Java versions)
- Automating repetitive code transformations across repositories

## Main Entry Point

Use the `/rewrite-assist` command with a GitHub PR URL:

```
/rewrite-assist https://github.com/owner/repo/pull/123
```

## Workflow Phases

The workflow executes these phases sequentially:

1. **Repository Setup** (`/fetch-repos`) - Clone repos and fetch PR branches
2. **Intent Extraction** (`/extract-intent`) - Analyze PR changes for transformation patterns
3. **Recipe Mapping** - Discover and compose OpenRewrite recipes matching the intents
4. **Recipe Validation** - Test recipes against the actual PR changes
5. **Recipe Refinement** - Combine learnings into optimal recipe configuration
6. **Final Recommendation** - Select best recipe with validation metrics

## Specialized Agents

The skill uses specialized subagents:

- **openrewrite-expert** - Recipe discovery, composition, and gap analysis
- **openrewrite-recipe-validator** - Empirical validation through recipe execution
- **openrewrite-session-analyzer** - Workflow effectiveness scoring

## Required Tools

- MCP Server: `openrewrite-mcp` for recipe search
- Bash commands for git operations and recipe execution
- Read/Write/Edit for file operations

## Output Artifacts

All outputs are saved to `.output/<timestamp>/`:

- `intent-tree.md` - Extracted transformation intents
- `option-N-recipe.yaml` - Generated recipe configurations
- `option-N-recipe.diff` - Validation diffs
- `option-N-stats.json` - Precision/recall metrics
- `result/recommended-recipe.yaml` - Final recommended recipe
- `result/recommended-recipe.diff` - Final validation diff

## Prerequisites

- Java 11/17/21 (matching target project)
- Docker (for MCP database)
- GitHub CLI (`gh`) for PR access
- Gradle wrapper in target repository

## Configuration

Model preferences are configurable per agent. Default uses `opus` for expert agents for best quality. Override by modifying agent frontmatter.

## Reference Documentation

See `references/openrewrite-guide.md` for comprehensive OpenRewrite framework documentation including:
- Lossless Semantic Tree (LST) concepts
- Visitor patterns and recipe types
- Recipe composition strategies
- Best practices for recipe development
