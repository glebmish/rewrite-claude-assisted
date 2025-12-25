# Required Permissions for OpenRewrite Assist Plugin

This document lists the minimum permissions required for the OpenRewrite Assist plugin to function correctly.

## Quick Setup

Add the following to your `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(mkdir:*)",
      "Bash(ls:*)",
      "Bash(cp:*)",
      "Bash(git clone:*)",
      "Bash(git diff:*)",
      "Bash(git fetch:*)",
      "Bash(git checkout:*)",
      "Bash(./gradlew:*)",
      "Bash(yq:*)",
      "Bash(scripts/validate-recipe.sh:*)",
      "Bash(scripts/get-session-id.sh:*)",
      "Bash(scripts/fetch-session.sh:*)",
      "Bash(scripts/check-prerequisites.sh:*)",
      "Bash(scripts/quick-setup.sh:*)",
      "Bash(scripts/verify-setup.sh:*)",
      "Bash(scripts/analysis/recipe-diff-precision.sh:*)",
      "mcp__openrewrite-mcp__test_connection",
      "mcp__openrewrite-mcp__find_recipes",
      "mcp__openrewrite-mcp__get_recipe"
    ]
  },
  "enableAllProjectMcpServers": true
}
```

## Permission Categories

### File Operations

| Permission | Purpose |
|------------|---------|
| `Bash(mkdir:*)` | Create output directories |
| `Bash(ls:*)` | List directory contents |
| `Bash(cp:*)` | Copy files (recipes, diffs) |

### Git Operations

| Permission | Purpose |
|------------|---------|
| `Bash(git clone:*)` | Clone repositories for analysis |
| `Bash(git diff:*)` | Generate diffs for comparison |
| `Bash(git fetch:*)` | Fetch PR branches |
| `Bash(git checkout:*)` | Switch branches |

### Build Operations

| Permission | Purpose |
|------------|---------|
| `Bash(./gradlew:*)` | Run Gradle for recipe execution |
| `Bash(yq:*)` | Parse YAML recipe files |

### Plugin Scripts

| Permission | Purpose |
|------------|---------|
| `Bash(scripts/validate-recipe.sh:*)` | Validate recipes against repos |
| `Bash(scripts/get-session-id.sh:*)` | Capture session ID |
| `Bash(scripts/fetch-session.sh:*)` | Fetch Claude session logs |
| `Bash(scripts/check-prerequisites.sh:*)` | Check system requirements |
| `Bash(scripts/quick-setup.sh:*)` | Run setup wizard |
| `Bash(scripts/verify-setup.sh:*)` | Verify installation |
| `Bash(scripts/analysis/recipe-diff-precision.sh:*)` | Calculate precision metrics |

### MCP Tools

| Permission | Purpose |
|------------|---------|
| `mcp__openrewrite-mcp__test_connection` | Verify MCP server connectivity |
| `mcp__openrewrite-mcp__find_recipes` | Search for OpenRewrite recipes |
| `mcp__openrewrite-mcp__get_recipe` | Get detailed recipe information |

## MCP Server Configuration

To enable the MCP server, add to your settings:

```json
{
  "enableAllProjectMcpServers": true
}
```

Or enable specifically:

```json
{
  "enabledMcpjsonServers": ["openrewrite-mcp"]
}
```

## Security Considerations

### Why These Permissions?

1. **Git operations**: Required to clone repos and analyze PR changes
2. **Gradle execution**: Required to run OpenRewrite recipes
3. **Script execution**: Plugin scripts automate validation workflow
4. **MCP tools**: Enable semantic recipe search

### What We Don't Need

- No network access beyond git/Docker
- No system modification permissions
- No access to sensitive directories outside workspace

## Minimal Permission Set

If you want the absolute minimum for basic functionality:

```json
{
  "permissions": {
    "allow": [
      "Bash(git clone:*)",
      "Bash(git diff:*)",
      "Bash(./gradlew:*)",
      "mcp__openrewrite-mcp__find_recipes",
      "mcp__openrewrite-mcp__get_recipe"
    ]
  },
  "enableAllProjectMcpServers": true
}
```

Note: This minimal set may require manual approval for some operations.

## Troubleshooting

### "Permission denied" errors

1. Check your `.claude/settings.json` includes the required permissions
2. Restart Claude Code after modifying settings
3. If using project-level settings, ensure `.claude/settings.json` exists in project root

### MCP tools not available

1. Ensure `enableAllProjectMcpServers: true` is set
2. Verify the MCP server is running (Docker container)
3. Restart Claude Code to reload MCP configuration
