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
Set up Python virtual environment and pull Docker image.

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
     - Run: `rm -rf plugin/mcp-server/venv && cd plugin/mcp-server && python3 -m venv venv`
     - Retry setup

### Success Criteria
Python virtual environment is configured and Docker image is available

---

## Phase 3: Verification

### Objective
Verify all development components are working correctly.

### Actions

1. **Run verification script**:
```bash
scripts/verify-dev-setup.sh
```

2. **Interpret results**:
   - For each failed check:
     - Read the error message
     - Provide specific fix based on failure type
     - Offer to retry after fix

3. **Common issues and fixes**:
   - **MCP server files missing**: Check plugin directory structure
   - **Python dependencies incomplete**: `cd plugin/mcp-server && ./venv/bin/pip install -r requirements.txt`
   - **Docker image not found**: `docker pull glebmish/openrewrite-recipes-db:latest`
   - **MCP configuration missing**: Re-run `scripts/setup-dev.sh`

### Success Criteria
All verification checks pass (or only optional warnings)

---

## Phase 4: Target Repository Check (Optional)

### Objective
Check if the target repository has Java/Gradle for recipe execution.

### Actions

1. **Ask user**:
   - "Will you be running OpenRewrite recipes directly on this repository?"
   - "Or will you clone a different repository for recipe execution?"

2. **If running on this repository**:
   - Check for `build.gradle` or `build.gradle.kts`
   - Extract Java version from build file
   - Verify matching Java version is available
   - Check for `gradlew` or `gradlew.bat`

3. **If running on different repository**:
   - Skip Java/Gradle checks
   - Note: "Java/Gradle will be checked when you run /rewrite-assist"

### Success Criteria
User understands the recipe execution requirements

---

## Phase 5: Next Steps

### Objective
Guide developer on what to do next.

### Actions

1. **Display success message**

2. **Show development commands**:
   - Test the plugin: `claude` then `/rewrite-assist https://github.com/owner/repo/pull/123`
   - Run evaluations: See `eval/README.md`

3. **Point to documentation**:
   - `plugin/README.md`: Plugin overview and usage
   - `plugin/PERMISSIONS.md`: Required tool permissions
   - `eval/README.md`: Evaluation framework

### Success Criteria
Developer understands how to test the plugin and run evaluations

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
