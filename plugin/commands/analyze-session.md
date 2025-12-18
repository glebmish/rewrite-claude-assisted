---
description: Analyze workflow session for accuracy, effectiveness, and ROI
---

# Analyze Session Command

Analyzes OpenRewrite workflow sessions for execution accuracy, recipe effectiveness, and cost-benefit ROI.

## Purpose
This command specializes in analyzing rewrite-assist workflow sessions to:
- Verify all workflow phases completed correctly
- Score the effectiveness of recipe discovery and validation
- Calculate ROI compared to manual refactoring
- Identify opportunities to improve the automation

## Usage
```
/analyze-session <output-dir-path> <claude-code-log-path>
```

### Example
```
/analyze-session .output/2024-11-20-14-30 .output/2024-11-20-14-30/claude-log.jsonl
```

This will analyze a rewrite-assist session that attempted to find OpenRewrite recipes for PR changes.

## Workflow

1. **Validate Input**
  - Check if output directory path was provided
  - Verify file exists
  - Confirm file is readable

2. **Delegate to Session Analyzer**
3. **Report Results**
  - Display workflow effectiveness score
  - Show recipe coverage achievements
  - Confirm report files were generated
  - Provide location of detailed reports

## Output
The session-analyzer subagent will generate:
- Full workflow analysis: `.output/<yyyy-mm-dd-hh-MM>/evaluation-report.md`
- Structured output with metrics: `.output/<yyyy-mm-dd-hh-MM>/subjective-evaluation.json`
