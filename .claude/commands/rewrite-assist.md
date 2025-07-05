# Rewrite Assist command
This command is located in the repository with custom OpenRewrite recipes. You're an experienced software engineer who is an expert in Java and refactoring. You always strive to break down complicated task on small atomic changes. This skill is essential for creating great OpenRewrite recipes by combining existing recipes and writing the new ones.

This is a multi-phased command. While executing this command, execute the following workflow phase by phase. Focus only on the current phase, do not plan for all phases at once. Perform all checks and initializations for a phase before you plan and execute work for this phase.

### Scratchpad
* Use `<yyyy-mm-dd-hh-mm>-<command>.md` scratchpad file located in .scratchpad directory to log your actions. User current date and time for the scratchpad name. 
* Before starting any action, log your intentions and reasons you decided to do that. After action is complete, log the results. If action fails, log the fact of the failure and your analysis of it.
  * for example, if you executed bash `cd` command and it says that directory is not found, you must log that. Log all similar errors. 
* This scratchpad must contain a detailed log of what you've done, what issues you've encounterd, commands you ran and your thought process. Only append, do not rewrite previous entries in the scratchpad. This file will be later usage for performance evaluated by people or AI, so it's very improtant for it to be truthful and sequential.

### Cost analysis
At the beginning of the workflow use ccusage cli to save current token usage and cost. At the end of the workflow use ccusage again. Save before and after stats to the scratchpad and also compute the cost of the workflow run in tokens and usd.

## Input Handling:

* If GitHub PR URLs are provided as arguments, use those directly
* If no arguments provided, interactively prompt the user to paste/enter a list of GitHub PR URLs
* Accept multiple formats:
  * Full PR URLs: https://github.com/owner/repo/pull/123
  * Short format: owner/repo#123
  * Mixed lists with whitespace, commas, or newlines as separators

### Example Usage
/rewrite-assist https://github.com/facebook/react/pull/12345 https://github.com/vercel/next.js/pull/67890

### Interactive mode
/pr-workspace
> Claude: Please enter GitHub PR URLs
> User: https://github.com/owner/repo/pull/123 https://github.com/owner/repo/pull/456 https://github.com/another/repo/pull/789

## Phase 1: Process input and fetch repositories
###  Parse and Validate PRs
  * Extract repository information (owner, repo name) and PR numbers from input
  * Group PRs by repository to minimize cloning operations
  * Validate that URLs are valid GitHub PR formats
  * Handle edge cases like private repos with no access or invalid PR numbers gracefully

### Repository Setup
Clone repositories and fetch PR branches

### Error Handling & User Feedback
* Check if git is available and configured
* Handle authentication issues (suggest using GitHub CLI or SSH keys)
* Provide clear error messages for:
  * Invalid PR URLs
  * Network connectivity issues
  * Permission/access problems
  * Disk space issues
* Show progress for long-running operations
* Summarize what was successfully set up vs. what failed

### Additional Features
* Check if directories already exist. Anything in .workspace directory is safe to delete and override.
* If Pr branches already exist, make sure they are up-to-date

### Implementation Requirements
* Dependencies to check/install:
  * Git (required)

### Output Format
Provide clear, structured output showing:
* Which repositories were processed
* Which PRs were successfully set up
* The file paths where each PR can be found
* Any errors or warnings
* Next steps for the user

### Success Criteria
* Robustly handles various input formats
* Creates clean, organized directory structure
* Provides informative feedback throughout the process
* Handles errors gracefully without leaving partial/broken state
* Works with both public and private repositories (with proper auth)
* Efficient - doesn't re-clone repositories unnecessarily
