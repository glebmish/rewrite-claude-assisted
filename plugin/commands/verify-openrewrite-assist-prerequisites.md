---
description: Verify prerequisites for running OpenRewrite Assist plugin
---

# Verify OpenRewrite Assist Prerequisites

Interactive verification wizard for OpenRewrite Assist plugin. This command validates that all prerequisites are met and the plugin is correctly configured.

You are an experienced DevOps engineer helping users verify their environment for the OpenRewrite Assist plugin. Your goal is to ensure the setup is complete and working.

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
All required prerequisites pass (Docker, Docker Compose, Python 3.8+, Git, jq, yq)

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
   - **Docker not running**:
     - Guide: "Please start Docker Desktop and try again"
     - Wait for user confirmation, then retry

   - **Image pull failures**:
     - Explain: "Failed to pull pre-built database image"
     - Suggest: "Check network connection and try again"

   - **Python dependency issues**:
     - Suggest: "Recreating virtual environment"
     - Run: `rm -rf mcp-server/venv && python3 -m venv mcp-server/venv`
     - Retry setup

### Success Criteria
MCP server environment is configured and Docker image is available

---

## Phase 3: Verification

### Objective
Verify all components are working correctly.

### Actions

1. **Run verification script**:
```bash
scripts/verify-setup.sh
```

2. **Interpret results**:
   - For each failed check:
     - Read the error message
     - Provide specific fix based on failure type
     - Offer to retry after fix

3. **Common issues and fixes**:
   - **MCP server files missing**: Check plugin installation
   - **Python dependencies incomplete**: `cd mcp-server && venv/bin/pip install -r requirements.txt`
   - **Docker image not found**: `docker pull glebmish/openrewrite-recipes-db:latest`

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
Guide user on what to do next.

### Actions

1. **Display success message**

2. **Show example commands**:
   - Try the main workflow: `/rewrite-assist https://github.com/owner/repo/pull/123`

3. **Point to documentation**:
   - README.md: Overview and quick start
   - PERMISSIONS.md: Required tool permissions

### Success Criteria
User understands how to use the plugin and what to try next

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
