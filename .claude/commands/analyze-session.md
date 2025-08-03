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
/analyze-session <scratchpad-file-path>
```

### Example
```
/analyze-session .scratchpad/2024-11-20-14-30/2024-11-20-14-30-rewrite-assist-07fee281-e1e8-4582-bda8-1056f1d9ec1b.md
```

This will analyze a rewrite-assist session that attempted to find OpenRewrite recipes for PR changes.

## Workflow

1. **Validate Input**
  - Check if scratchpad file path was provided
  - Verify file exists
  - Confirm file is readable

2. **Delegate to Session Analyzer**
  - Invoke the session-analyzer subagent with the scratchpad file
  - The subagent will analyze:
    - Workflow phase completion (fetch-repos, extract-intent, recipe-mapping, validation)
    - Recipe discovery effectiveness
    - Validation accuracy and coverage claims
    - Iteration improvements
    - Cost-benefit ROI

3. **Report Results**
  - Display workflow effectiveness score
  - Show recipe coverage achievements
  - Confirm report files were generated
  - Provide location of detailed reports

## Error Handling
- Missing file argument → Request file path
- File not found → Suggest checking path
- Analysis failure → Report subagent error

## Output
The session-analyzer subagent will generate:
- Full workflow analysis: `.scratchpad/<current-workflow-dir>/analysis-reports/<session-id>-report.md`
- Recipe effectiveness data: `.scratchpad/<current-workflow-dir>/<session-id>-data.json`
- Executive summary with ROI: `.scratchpad/<current-workflow-dir>/<session-id>-summary.txt`

Key metrics reported:
- Workflow effectiveness score (0-100%)
- Recipe mapping accuracy
- Validation coverage achieved
- Cost vs manual effort saved

## Success Criteria
- Successfully validates input file
- Session analyzer completes workflow analysis
- Reports are generated with effectiveness scores
- ROI calculation shows value of automation
- Actionable insights for improving recipe discovery