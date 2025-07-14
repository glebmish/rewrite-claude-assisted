# Rewrite Assist Command

This is the main orchestrator command for OpenRewrite recipe development and analysis. You're an experienced software engineer who is an expert in Java and refactoring. 
You always strive to break down complicated tasks into small atomic changes.

This command coordinates a multiphase workflow by executing individual commands in sequence. Always complete a current phase first
before reading description of the next phase. Each phase must complete successfully before proceeding to the next phase.

Each phase is described as a slash command. To get the prompt for the slash command, read a file in `.claude/commands/<phase-name>.md`

## Workflow Overview

The complete workflow consists of these phases:

### Phase 1: `/fetch-repos <PR links>` - Repository Setup
Parse GitHub PR URLs, clone repositories, and set up PR branches for analysis.

### Phase 2: `/extract-intent <pairs of repository-path:pr-branch-name>` - Intent Analysis  
Analyze PRs to extract both strategic (wide) and tactical (narrow) transformation intents.

### Phase 3: `/map-recipes <intents>` - Recipe Mapping
Discover available OpenRewrite recipes and map extracted intents to appropriate recipes.

## Input Handling

* If GitHub PR URLs are provided as arguments, use those directly
* If no arguments provided, interactively prompt the user to paste/enter a list of GitHub PR URLs
* Accept multiple formats:
  * Full PR URLs: https://github.com/owner/repo/pull/123
  * Short format: owner/repo#123
  * Mixed lists with whitespace, commas, or newlines as separators

### Full Workflow
```
/rewrite-assist https://github.com/org/name/pull/123
```

### Interactive mode
```
/rewrite-assist
> Claude: Please enter GitHub PR URLs
> User: https://github.com/owner/repo/pull/123 https://github.com/owner/repo/pull/456
```

## Implementation Details

### Scratchpad Management
* Use `<yyyy-mm-dd-hh-MM>-rewrite-assist.md` scratchpad file located in .scratchpad directory
* Very first line of the scratchpad must be `Session ID: <id>`. Use `scripts/get-session-id.sh` command to retrieve session id.
* Log the execution of each phase, all commands with the reason why you execute it and its results
* Track overall progress and any issues encountered across phases

### Error Handling
* If any phase fails, stop the workflow and report the failure
* Provide clear guidance on how to resume from a specific phase
* Log all errors and recovery steps in the scratchpad

### Success Criteria
* All phases complete successfully
* Well-documented workflow progress in scratchpad
* Actionable recommendations for recipe deployment or refinement