---
description: Set up development environment for rewrite-claude-assisted repository
---

# Setup Development Prerequisites

Interactive setup wizard for the rewrite-claude-assisted development environment. This command that all prerequisites are met and sets up the environment for plugin development and testing.

You are an experienced DevOps engineer helping developers set up their environment for the rewrite-claude-assisted repository. Your goal is to ensure the development setup is complete and working.

## Execution Protocol

Execute phases sequentially. Do not proceed to the next phase until the current phase completes successfully.

**CRITICAL**: Be concise and factual. Avoid verbose explanations. State findings clearly in bullet points, not prose.

---

## Phase 1: Prerequisites Check

### Objective
Verify all required tools are installed and properly configured.

### Actions

1. **Run prerequisites script**:
```bash
scripts/check-dev-prerequisites.sh
```

2. **Parse output**:
   - Identify missing prerequisites (marked with ✗)
   - Note successful checks (marked with ✓)

3. **For each missing prerequisite**:
   - Show the installation instructions from script output
   - Detect OS if needed for platform-specific guidance
   - Ask user to install and confirm when ready
   - Re-run check to verify installation

### Success Criteria
All required prerequisites pass

---

## Phase 2: Environment Setup

### Objective
Set up development environment

### Actions

1. **Run setup script**:
```bash
scripts/setup-dev.sh --skip-prerequisites-check
```

2. **Monitor for errors**:
   - **Docker not running**: Guide user to start Docker, retry
   - **Image pull failures**: Check network, retry
   - **Python dependency issues**: Suggest `rm -rf plugin/mcp-server/venv && rm -rf data-ingestion/venv` and retry

### Success Criteria
Script exits with code 0

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

3. **Show development workflows**:

   **a) Rebuild recipe database**: See `data-ingestion/README.md`

   **b) Run evaluations**: See `eval/README.md`

   **c) Test plugin locally**:
   ```bash
   claude --plugin-dir ./plugin
   > /rewrite-assist https://github.com/owner/repo/pull/123
   ```

   **d) Run assist command with installed plugin**:
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
- The setup script is idempotent - safe to re-run
