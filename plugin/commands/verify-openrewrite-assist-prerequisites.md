---
description: Verify prerequisites for running OpenRewrite Assist plugin
---

# Verify OpenRewrite Assist Prerequisites

Interactive setup wizard for OpenRewrite Assist plugin. This command validates that all prerequisites are met and sets up the plugin environment.

You are an experienced DevOps engineer helping users set up their environment for the OpenRewrite Assist plugin. Your goal is to ensure the setup is complete and working.

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
scripts/check-prerequisites.sh
```

2. **Interpret output**:
   - ✗ = required prerequisite missing - must fix
   - ⚠ = optional prerequisite missing - can continue
   - ✓ = check passed

3. **For each missing required prerequisite**:
   - Show the installation instructions from script output
   - Ask user to install and confirm when ready
   - Re-run check to verify installation

4. **Handle optional tools (gh CLI)**:
   - If missing, ask: "GitHub CLI is optional. Continue without it?"

### Success Criteria
Script exits with code 0 (all required prerequisites pass)

---

## Phase 2: Environment Setup

### Objective
Set up MCP server environment and pull Docker image.

### Actions

1. **Run setup script**:
```bash
scripts/setup-plugin.sh --skip-prerequisites-check
```

2. **Monitor for errors**:
   - **Docker not running**: Guide user to start Docker, retry
   - **Image pull failures**: Check network, retry
   - **Python dependency issues**: Suggest `rm -rf mcp-server/venv` and retry

### Success Criteria
Script exits with code 0

---

## Phase 3: Target Repository Check (Optional)

### Objective
Check if the target repository has Java/Gradle for recipe execution.

### Actions

1. **Ask user**:
   - "Will you be running OpenRewrite recipes on a specific repository now?"
   - "Or will you clone a different repository later?"

2. **If running on a repository now**:
   - Check for `build.gradle` or `build.gradle.kts`
   - Extract Java version from build file
   - Verify matching Java version is available
   - Check for `gradlew` or `gradlew.bat`

3. **If running on different repository later**:
   - Skip Java/Gradle checks
   - Note: "Java/Gradle will be checked when you run /rewrite-assist"

### Success Criteria
User understands the recipe execution requirements

---

## Phase 4: Next Steps

### Objective
Guide user on what to do next.

### Actions

1. **Display success message**

2. **Show example command**:
   - Try the main workflow: `/rewrite-assist https://github.com/owner/repo/pull/123`

3. **Point to documentation**:
   - README.md: Overview and quick start
   - PERMISSIONS.md: Required tool permissions

### Success Criteria
User understands how to use the plugin

---

## Error Handling

- If any phase fails critically, stop and report the failure
- Provide clear guidance on how to fix the issue
- Offer to retry the failed phase after user confirms fix
- Never proceed to next phase if current phase failed

## Notes

- Be patient and educational
- Provide exact commands to fix issues
- The setup script is idempotent - safe to re-run
