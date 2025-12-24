# OpenRewrite Assist Plugin

AI-powered OpenRewrite recipe discovery and validation from GitHub Pull Requests.

## Overview

This Claude Code plugin analyzes GitHub PR changes and automatically discovers, composes, and validates OpenRewrite recipes that can replicate those transformations. It's designed for:

- **Framework migrations** (Spring Boot 2→3, JUnit 4→5, Java version upgrades)
- **Code modernization** (adopting new language features, API updates)
- **Security fixes** (dependency updates, vulnerability remediation)
- **Automated refactoring** (consistent code transformations across repositories)

## Features

- **Intent Extraction**: Analyzes PR diffs to identify transformation patterns
- **Recipe Discovery**: Searches 2000+ OpenRewrite recipes using semantic search
- **Recipe Composition**: Combines multiple recipes for complete coverage
- **Empirical Validation**: Tests recipes against actual PR changes
- **Precision Metrics**: Measures recall, precision, and F1 score

## Installation

### From GitHub

```bash
claude /plugin add github.com/glebmish/openrewrite-assist-plugin
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/glebmish/openrewrite-assist-plugin.git
   ```

2. Add to Claude Code:
   ```bash
   claude /plugin add ./openrewrite-assist-plugin
   ```

## Prerequisites

Before using the plugin, ensure you have:

- **Java 11/17/21** (matching your target project)
- **Docker** (for MCP recipe database)
- **Docker Compose**
- **Python 3.8+**
- **Git**
- **GitHub CLI** (`gh`) - optional but recommended

## Quick Start

### 1. Setup

Run the prerequisites verification:

```
/verify-openrewrite-assist-prerequisites
```

This will:
- Check prerequisites (Docker, Python, Git, etc.)
- Set up the MCP server environment
- Pull the recipe database Docker image
- Verify the installation

### 2. Analyze a PR

```
/openrewrite-assist:rewrite-assist https://github.com/owner/repo/pull/123
```

The workflow will:
1. Clone the repository and fetch the PR
2. Extract transformation intents from the PR changes
3. Search for matching OpenRewrite recipes
4. Validate recipes against the actual PR changes
5. Produce a recommended recipe configuration

### 3. Review Results

All outputs are saved to `.output/<timestamp>/`:

- `intent-tree.md` - Extracted transformation intents
- `option-N-recipe.yaml` - Generated recipe configurations
- `option-N-stats.json` - Precision/recall metrics
- `result/recommended-recipe.yaml` - Final recommended recipe

## Commands

| Command | Description |
|---------|-------------|
| `/rewrite-assist <PR-URL>` | Full workflow for recipe discovery and validation |
| `/fetch-repos <PR-URLs>` | Clone repositories and fetch PR branches |
| `/extract-intent <repo:branch>` | Extract transformation intents from PR |
| `/verify-openrewrite-assist-prerequisites` | Check and set up plugin prerequisites |

## Agents

The plugin uses specialized subagents:

| Agent | Model | Purpose |
|-------|-------|---------|
| `openrewrite-expert` | opus | Recipe discovery and composition |
| `openrewrite-recipe-validator` | opus | Empirical recipe validation |

### Configuring Models

Agent models are configured in their frontmatter. To change:

1. Edit `agents/<agent-name>.md`
2. Modify the `model:` field (options: `opus`, `sonnet`, `haiku`)

## MCP Server

The plugin includes an MCP server for semantic recipe search:

- **Database**: PostgreSQL with pgvector for semantic search
- **Recipes**: 2000+ OpenRewrite recipes with embeddings
- **Tools**: `find_recipes`, `get_recipe`, `test_connection`

### Setting Up the MCP Server

Run the setup scripts:

```bash
cd scripts

# Check prerequisites
./check-prerequisites.sh

# Set up environment (creates venv, pulls Docker image)
./setup-plugin.sh
```

To manually start the database:

```bash
cd mcp-server
docker-compose up -d  # Start database
./scripts/startup.sh  # Start MCP server
```

## Permissions

See [PERMISSIONS.md](PERMISSIONS.md) for required Claude Code permissions.

## Project Structure

```
openrewrite-assist-plugin/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/                  # Slash commands
│   ├── rewrite-assist.md
│   ├── fetch-repos.md
│   ├── extract-intent.md
│   └── verify-openrewrite-assist-prerequisites.md
├── agents/                    # Specialized subagents
│   ├── openrewrite-expert.md
│   └── openrewrite-recipe-validator.md
├── mcp-server/                # Recipe search MCP server
├── scripts/                   # Setup scripts
│   ├── check-prerequisites.sh
│   └── setup-plugin.sh
├── .mcp.json                  # MCP configuration
├── README.md
├── PERMISSIONS.md
└── LICENSE
```

## Troubleshooting

### MCP Server Connection Issues

1. Ensure Docker is running
2. Check if the database container is up: `docker ps`
3. Pull the database image: `docker pull glebmish/openrewrite-recipes-db:latest`
4. Test connection: Use `mcp__openrewrite-mcp__test_connection`

### Recipe Validation Fails

1. Check Java version matches the project
2. Ensure the repository has a Gradle wrapper
3. Check the recipe YAML is valid: `yq eval recipe.yaml`

### Permission Denied

Add required permissions to your `.claude/settings.json`. See [PERMISSIONS.md](PERMISSIONS.md).

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

Apache-2.0

## Links

- [OpenRewrite Documentation](https://docs.openrewrite.org/)
- [OpenRewrite Recipe Catalog](https://docs.openrewrite.org/recipes)
- [Claude Code Documentation](https://docs.claude.com/claude-code)
