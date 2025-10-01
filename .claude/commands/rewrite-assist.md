# Rewrite Assist Command

This is the main orchestrator command for OpenRewrite recipe development and analysis. You're an experienced software engineer who is an expert in Java and refactoring. 

This command coordinates a multiphase workflow by executing individual commands in sequence.
* Always complete a current phase first before reading description of the next phase.
* Each phase must complete successfully before proceeding to the next phase.
* When you start executing a new phase, update todo list with more details for the given phase.
* Keep a detailed log of each phase execution in the same scratchpad.

Phase can be described as a slash command (`/<command-name>`). To get the prompt for the slash command, read a file in `.claude/commands/<command-name>.md`

## Workflow Overview

The complete workflow consists of these phases:

### Phase 1: `/fetch-repos <PR links>` - Repository Setup
Parse GitHub PR URLs, clone repositories, and set up PR branches for analysis.

### Phase 2: `/extract-intent <pairs of repository-path:pr-branch-name>` - Intent Analysis  
Analyze PRs to extract both strategic (wide) and tactical (narrow) transformation intents.

### Phase 3: Recipe Mapping
Discover available OpenRewrite recipes and map extracted intents to appropriate recipes.

### Phase 4: Recipe validation
Test each recipe produced on the previous phase and make the final decision on what recipe is the final version.

### Phase 5: Final decision
Based on the results, choose the final recommended recipe. Final result must reside in the subdirectory of 
where scratchpad file is written called `result`. Following files are expected:
* `pr.diff` - original PR diff
* `recommended-recipe.yaml` - recipe file
* `recommended-recipe.diff` - diff of this recipe from main
* `recommended-recipe-to-pr.diff` - diff of this recipe from the given PR branch

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

## Error Handling
* If any phase fails, stop the workflow and report the failure
* Provide clear guidance on how to resume from a specific phase
* Log all errors and recovery steps in the scratchpad

## Success Criteria
* All phases complete successfully
* Well-documented workflow progress in rewrite-assist-scratchpad.md scratchpad
* PR diff saved
* Recipe yaml and diff files saved for each evaluated recipe
* Actionable recommendations for recipe deployment or refinement