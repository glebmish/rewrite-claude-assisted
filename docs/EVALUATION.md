# Evaluation Infrastructure

*Evaluation system for AI-assisted refactoring workflows*

[← Back: README](../README.md) | [← Back: Architecture](ARCHITECTURE.md) | [← Back: Validation Algorithm](VALIDATION.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Eval Design Highlights](#eval-design-highlights)
3. [Test Environment Setup](#test-environment-setup)
4. [Evaluation Algorithm](#evaluation-algorithm)
5. [Multi-Agent Orchestration & Artifact Capture](#multi-agent-orchestration--artifact-capture)
6. [Batch Evaluation Pipeline](#batch-evaluation-pipeline)
7. [Post-Eval Manual Analysis](#post-eval-manual-analysis)
8. [Evolution Tracking](#evolution-tracking)

---

## Overview

Evaluating AI-generated refactoring recipes requires more than LLM-based assessment. This system implements **empirical validation**: execute recipes on real code, measure precision/recall against ground truth, and track costs across multi-agent workflows.

### Eval Design Highlights

1. **Algorithmic Rigor** — Diff-based matching algorithm, not LLM evaluation. Every metric grounded in actual code execution.

2. **Multi-Agent Observability** — Per-agent cost and tool tracking across 7+ subagents. Bottleneck identification and optimization guidance.

3. **Production Infrastructure** — Batch orchestration solving real constraints (session limits, concurrency). Docker isolation, CI/CD automation.

4. **Comprehensive Metrics** — F1 + precision + recall + cost + duration + tool success rates.

5. **Historical Tracking** — 5 checkpoints documenting 6-month evolution. Quantified ROI, regression detection, A/B testing.

6. **Reproducibility** — Deterministic evaluation, comprehensive artifact capture (15+ files per run), machine + human-readable formats.

**Results**: 97.6% tool success rate, 100% workflow completion rate.

---

## Test Environment Setup

### Docker Container

The evaluation environment runs in Ubuntu 22.04 containers with comprehensive tooling pre-installed.
System dependencies include Git for repository operations, GitHub CLI for PR data access, and other utilities.
The environment supports multiple Java versions (11, 17) to support different projects,
with automatic version detection and selection during recipe execution.

Python 3.8+ is installed with pip and venv support for MCP server dependencies. 
The Claude Code CLI is installed via Node.js 24.5.0 through nvm, providing the primary interface for executing the 6-phase workflow.
Locale settings are configured for UTF-8 encoding as a fix for encoding corruption bug.

### MCP Server Integration

Two MCP servers are configured and pre-installed in the Docker image. The primary OpenRewrite recipe server connects to a
PostgreSQL database with pgvector extension, containing embeddings for 1000+ recipes.
Python dependencies including sentence-transformers and asyncpg are pre-installed in a system-wide virtualenv to
avoid reinstallation overhead on every run.

The log MCP server enables progress tracking and status reporting during long-running evaluations.
Both servers communicate with Claude Code via stdio transport. Database connection parameters are configured through environment variables,
supporting both local Docker Compose mode (embedded PostgreSQL) and GitHub Actions mode (external PostgreSQL service).

### Permissions and Security Configuration

A settings file defines pre-approved tool patterns that Claude Code can execute without interactive confirmation.
This includes bash commands (git operations, gradle execution, file manipulation), MCP tool invocations 
(recipe search, recipe documentation fetch, progress logging), and file operations (read, write, edit, glob, grep).

Specific Java version selection is permitted through JAVA_HOME environment variable overrides.
GitHub CLI commands are allowed for PR metadata fetching. The permission system uses glob patterns to match command variations
while maintaining security boundaries—for example, git push is explicitly denied to prevent accidental remote modifications.

### Environment Variables and Secrets

The container receives several environment variables at runtime. CLAUDE_CODE_OAUTH_TOKEN provides API access for the Claude Code CLI.
GH_TOKEN enables GitHub API authentication for PR data and artifact operations. SSH private keys are injected for git clone operations over SSH protocol.

MCP database credentials are configured through DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD variables.
The system supports two deployment modes: local evaluation with embedded PostgreSQL, and CI/CD evaluation with external PostgreSQL services managed by GitHub Actions.

### Execution Orchestration

The entrypoint script coordinates the entire evaluation workflow. It parses command-line arguments including PR URL,
strict mode flag, debug mode, and timeout settings. SSH keys are configured for GitHub repository access.
MCP servers are initialized and health-checked before workflow execution begins.

The script creates symlinks to pre-installed Python virtual environments, avoiding repeated dependency installation.
It configures MCP database connections based on deployment mode. The 6-phase workflow is executed through Claude Code CLI
with full logging to JSONL files. Upon completion, all artifacts are collected from the output directory and prepared for upload
to GitHub Actions artifacts or local storage.

Timeout mechanisms ensure runaway evaluations are terminated. Error handling captures failures at each phase, reporting detailed diagnostics.
The execution environment is isolated per run — each evaluation uses a fresh working directory with PID-based repository
copies to prevent interference between parallel validations.

---

## Evaluation Algorithm

### Non-Interactive Claude Code Execution

Evaluations run Claude Code in non-interactive mode through the CLI. The initial prompt is simply the PR URL passed to the `/rewrite-assist` custom command. Claude Code executes the 6-phase workflow without user intervention, making all decisions autonomously based on empirical validation metrics.

The workflow logic is defined in custom commands and specialized subagents rather than in the evaluation harness itself. The main orchestrator command coordinates phase execution sequentially. Expert subagents handle recipe discovery and composition. Validator subagents perform empirical testing and precision/recall calculation. Refinement subagents synthesize improved recipes from validation feedback.

This architecture isolates evaluation concerns from workflow logic—the evaluation infrastructure simply provides the environment, captures artifacts, and aggregates metrics. The workflow itself remains identical whether run interactively by developers or non-interactively in CI/CD.

**Real-time progress tracking**: The log MCP server provides a workaround for monitoring long-running evaluations. The workflow uses `mcp__log-mcp-server__log` to write progress messages (phase transitions, validation completions, metric updates) to an external log that can be tailed in real-time. This compensates for the lack of native streaming output from Claude Code in non-interactive mode.

### Post-Execution Analysis

After Claude Code completes, a separate analysis step processes the captured artifacts. Analysis scripts run outside the Claude Code session to avoid consuming additional API credits. The diff precision/recall algorithm (detailed in VALIDATION.md) compares recipe output against PR ground truth, calculating true positives, false positives, and false negatives.

Cost tracking parses JSONL logs to extract token usage per agent and model, applying API pricing to calculate dollar costs. Tool success metrics aggregate bash commands, file operations, and MCP invocations to identify reliability bottlenecks. All analysis outputs are deterministic and reproducible—no LLM involvement in metric calculation eliminates hallucination risk.

**Note on LLM-based analysis**: Early experiments used Claude to subjectively analyze recipe quality and suggest improvements. This was disabled due to the lack of resources.

### Artifact Structure

Each evaluation run produces 15+ files capturing complete execution state:

```
.output/{timestamp}/
├── log/{session-id}.jsonl          # Main orchestrator execution log
├── log/agent-{id}.jsonl            # 7+ subagent logs (experts, validators, refinement)
├── intent-tree.md                  # Hierarchical breakdown of PR changes
├── option-{1,2,3}-recipe.yaml      # Recipe candidates (wide, narrow, refined)
├── option-{1,2,3}-recipe.diff      # Recipe execution outputs
├── option-{1,2,3}-stats.json       # Precision/recall/F1 metrics per option
├── option-{1,2,3}-creation-analysis.md      # Composition rationale
├── option-{1,2,3}-validation-analysis.md    # Gap analysis (FP/FN breakdown)
├── workflow-metadata.json          # Run summary (duration, F1, cost, success)
├── claude-usage-stats.json         # Token counts, tool calls by agent/model
├── claude-cost-stats.json          # Dollar costs by agent/model
├── recipe-precision-analysis.json  # Detailed TP/FP/FN breakdown for the resulting recipe
└── result/
    ├── recommended-recipe.yaml     # Final selected recipe
    ├── recommended-recipe.diff     # Final recipe execution output
    └── pr.diff                     # Ground truth PR diff
```

---

## Multi-Agent Orchestration & Artifact Capture

### Claude Code Execution Tracking

**Implementation**: `scripts/analysis/claude-stats.py`

**Log Collection Strategy**:
```
.output/{timestamp}/log/
├── {session-id}.jsonl        # Main orchestrator
├── agent-{id-1}.jsonl        # Subagents
├── agent-{id-3}.jsonl        
└── ...
```

**Token & Cost Attribution**:
1. Parse JSONL logs for each agent's tool usage patterns
2. Extract input/output tokens per agent and model
3. Calculate costs using API pricing:
   - Sonnet 4.5: \$3/\$15 per 1M tokens (input/output), \$3.75/\$0.30 (cache creation/read)
   - Haiku 4.5: \$1/\$5 per 1M tokens (input/output), \$1.25/\$0.10 (cache creation/read)
   - Note: Cache costs can represent 37-51% of total workflow cost
4. Aggregate by agent role, model type, tool category

**Tool Success Metrics**:
- Track all tool invocations: `Bash()`, `Read()`, `mcp__find_recipes()`
- Measure success/failure rates per tool type
- Record execution duration for bottleneck identification

**Output Artifacts** (per run):
- `claude-usage-stats.json` — Token counts, tool call inventory
- `claude-cost-stats.json` — Per-agent cost breakdown
- `workflow-metadata.json` — Run summary (duration, input, etc)

---

## Batch Evaluation Pipeline

### Challenge

Claude Code Pro has session limits. GitHub Actions has concurrency quotas. Running many tests as a single pipeline is not feasible—even 10 tests had to be reduced to 5 and broken down into multiple batches run throughout a day or two.

### Suite Configuration

**File**: `eval/suites/{name}.yaml`

```yaml
suite_name: "java-version-upgrades"
batch_size: 2  # Max concurrent workflows
prs:
  - url: "https://github.com/org/repo/pull/1"
    name: test 1
  - url: "https://github.com/org/repo/pull/2"
    name: test 2
  - url: "https://github.com/org/repo/pull/3"
    name: test 3
  - url: "https://github.com/org/repo/pull/4"
    name: test 4
  - url: "https://github.com/org/repo/pull/5"
    name: test 5
```

### Automated Workflow Generation

**Script**: `eval/generate-suite-workflows.sh`

**Process**:
1. Parse suite YAML configuration
2. Generate batch workflow files respecting `batch_size` constraint
3. Generate aggregation workflow to collect results after all batches complete
4. Each batch workflow invokes `rewrite-assist.yml` with specific PR parameters
5. Workflows coordinate via GitHub Actions dependencies and matrix strategy
6. Output: `suite-{name}-batch-{N}.yml` for each batch, plus `suite-{name}-aggregate.yml`

**Execution Flow**:
```
Suite: 5 PRs, batch_size: 2

Batch 1: [PR 1, PR 2] → Wait for completion (and claude session limit reset if needed)
Batch 2: [PR 3, PR 4] → Wait for completion (and claude session limit reset if needed)
Batch 3: [PR 5] → Wait for completion
Aggregation job: Collect all artifacts, generate summary
```

### Result Aggregation

The aggregation workflow downloads all artifacts from completed batch runs and processes them locally. It parses `workflow-metadata.json` from each run directory and calculates suite-level statistics:
- Average/min/max F1, precision, recall
- Average cost per run, total suite cost
- Success rate (workflow completion percentage)
- Tool success rates across all runs

Outputs are generated as `summary.md` with markdown tables and `suite-results.json` for machine processing. These files are committed to the repository under `eval-checkpoints/{suite-name}/` for historical tracking.

---

## Post-Eval Manual Analysis

### Checkpoint Contents

Each evaluation checkpoint in `eval-checkpoints/{name}/` contains:
- `summary.md` — Aggregated metrics table (avg/min/max F1, costs, success rate)
- `suite-results.json` — Machine-readable data for trend analysis
- `manual-review.md` — Human observations of failure patterns and insights
- Per-run directories with 15+ artifact files each

### Manual Review Process

After automated metrics are calculated, manual review examines failure patterns and edge cases. Reviewers analyze false positives to identify over-aggressive recipes, false negatives to find missing transformations, and execution failures to uncover tooling issues. Common patterns are documented—for example, YAML formatting issues with empty strings, semantic recipe failures requiring text-based fallbacks, or Java version mismatches causing compilation errors.

Manual notes capture qualitative observations that metrics alone cannot reveal. Did the intent extraction miss a subtle pattern? Did the recipe composition strategy fail for a specific change category? Are there systematic gaps in the OpenRewrite recipe catalog? These insights inform future workflow improvements.

### Gemini Analysis

Gemini CLI is used for supplementary analysis via its generous free tier, allowing detailed examination without additional cost. Gemini reviews validation analysis files, identifies common failure modes across multiple runs, and suggests potential recipe improvements. This complements empirical metrics with qualitative pattern recognition.

The analysis is advisory rather than authoritative—Gemini's suggestions are manually reviewed before incorporation. The free tier constraint means this step is optional and opportunistic rather than systematic. When API quotas allow, Gemini provides a second perspective on recipe quality and coverage gaps.

---

## Evolution Tracking

**6 checkpoints** documenting system improvements:

| Date | F1 | Precision | Recall | Cost | Key Change |
|------|-----|-----------|--------|------|------------|
| 2025-11-01 | n/a | n/a | n/a | $3.82 | Baseline (Haiku) - invalid metrics due to validation issues |
| 2025-11-17 | 0.52 | 0.58 | 0.51 | $4.28 | Sonnet 4.5 upgrade |
| 2025-11-23 | 0.54 | 0.61 | 0.52 | $4.15 | Context optimization (-35% tokens) |
| 2025-11-25 | 0.51 | 0.64 | 0.49 | $4.13 | MCP semantic search |
| **2025-11-29** | **0.85** | **0.90** | **0.82** | **$5.42** | **Refinement phase (+66% F1)** |
| 2025-12-06 | 0.71 | 0.92 | 0.69 | $9.97 | Opus 4.5 (full workflow) |

*Bold indicates best overall result (by F1 score)*

Checkpoints enable regression detection, A/B testing of workflow changes, and quantified measurement of improvement strategies. Each checkpoint captures the complete evaluation state at a point in time, allowing historical comparison and trend analysis across 6 months of development.

---

[← Back: README](../README.md) | [← Back: Architecture](ARCHITECTURE.md) | [← Back: Validation Algorithm](VALIDATION.md)
