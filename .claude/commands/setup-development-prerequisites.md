---
description: Set up development environment for rewrite-claude-assisted repository
---

# Setup Development Prerequisites

Interactive setup wizard for the rewrite-claude-assisted development environment. This command validates prerequisites and configures the environment for plugin development and testing.

You are an experienced DevOps engineer helping developers set up their environment for the rewrite-claude-assisted repository. Your goal is to ensure the development setup is complete and working.

## Execution Protocol

Execute phases sequentially. Do not proceed to the next phase until the current phase completes successfully.

**CRITICAL**: Be concise and factual. Avoid verbose explanations. State findings clearly in bullet points, not prose.

---

## Phase 1: Prerequisites Check

### Objective
Verify all required development tools are installed and properly configured.

### Actions

1. **Run prerequisites script**:
```bash
scripts/check-dev-prerequisites.sh
```

2. **Parse output**:
   - Identify missing prerequisites (marked with ✗)
   - Identify warnings (marked with ⚠)
   - Note successful checks (marked with ✓)

3. **For each missing prerequisite**:
   - Show the installation instructions from script output
   - Detect OS if needed for platform-specific guidance
   - Ask user to install and confirm when ready
   - Re-run check to verify installation

4. **Handle optional tools (gh CLI)**:
   - Explain: "GitHub CLI enables PR operations but is optional for basic usage"
   - If missing, ask: "Do you want to continue without gh CLI?"

### Success Criteria
All required prerequisites pass (Docker, Docker Compose, Python 3.8+ with venv, Git, jq, yq, Claude Code CLI)

---

## Phase 2: Environment Setup

### Objective
Set up Python virtual environments and pull Docker image.

### Actions

1. **Run setup script**:
```bash
scripts/setup-dev.sh --skip-prerequisites-check
```

2. **Monitor for errors**:
   - **Docker not running**:
     - Guide: "Please start Docker Desktop and try again"
     - Wait for user confirmation, then retry

   - **Image pull failures**:
     - Explain: "Failed to pull pre-built database image"
     - Suggest: "Check network connection and try again"

   - **Python dependency issues**:
     - Suggest: "Try recreating virtual environment"
     - Run: `rm -rf plugin/mcp-server/venv && rm -rf data-ingestion/venv`
     - Retry setup

### Success Criteria
Python virtual environments are configured and Docker image is available

---

## Phase 3: Next Steps

### Objective
Guide developer on available development workflows and documentation.

### Actions

1. **Display success message**

2. **Point to documentation**:
   - `docs/ARCHITECTURE.md`: System design, agent orchestration, workflow phases
   - `docs/VALIDATION.md`: Empirical validation algorithm, precision/recall metrics
   - `docs/EVALUATION.md`: Evaluation infrastructure, batch pipeline
   - `plugin/README.md`: Plugin overview and usage
   - `plugin/PERMISSIONS.md`: Required tool permissions

3. **Show development workflows** (in order of complexity):

   **a) Rebuild recipe database**: See `data-ingestion/README.md`

   **b) Run evaluations**: See `eval/README.md`

   **c) Test plugin locally** (recommended for development):
   ```bash
   claude --plugin-dir ./plugin
   > /rewrite-assist https://github.com/owner/repo/pull/123
   ```

   **d) Quick test with installed plugin**:
   ```bash
   claude
   > /rewrite-assist https://github.com/owner/repo/pull/123
   ```

### Success Criteria
Developer understands available workflows and can choose appropriate next step

---

## Error Handling

- If any phase fails critically, stop and report the failure
- Provide clear guidance on how to fix the issue
- Offer to retry the failed phase after user confirms fix
- Never proceed to next phase if current phase failed

## Notes

- Be patient and educational
- Provide exact commands to fix issues
- Test after each configuration change
