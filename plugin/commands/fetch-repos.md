---
description: Clone repositories and fetch PR branches for analysis
---

# Fetch Repos Command

Your task is to setup environment for OpenRewrite recipe analysis.

## Input Handling

* If GitHub PR URLs are provided as arguments, use those directly
* If no arguments provided, interactively prompt the user to paste/enter a list of GitHub PR URLs
* Accept multiple formats:
  * Full PR URLs: https://github.com/owner/repo/pull/123
  * Short format: owner/repo#123
  * Mixed lists with whitespace, commas, or newlines as separators

### Example Usage
/fetch-repos https://github.com/org/name/pull/123

### Interactive mode
/fetch-repos
> Claude: Please enter GitHub PR URLs
> User: https://github.com/org/name/pull/123

## Parse and Validate PRs
* Extract repository information (owner, repo name) and PR numbers from input
* Group PRs by repository to minimize cloning operations
* Validate that URLs are valid GitHub PR formats
* Handle edge cases like private repos with no access or invalid PR numbers gracefully

## Repository Setup
* Clone repositories and fetch PR branches

## Error Handling & User Feedback
* Check if directories already exist. Anything in .workspace directory is safe to delete and override.
* Check if git is available and configured
* Handle authentication issues (suggest using GitHub CLI or SSH keys)
* Provide clear error messages for:
  * Invalid PR URLs
  * Network connectivity issues
  * Permission/access problems
  * Disk space issues
* Summarize what was successfully set up vs. what failed
* If PR branches already exist, make sure they are up-to-date

## Output Format
Provide clear, structured output showing:
* Which repositories were processed
* Which PRs were successfully set up
* The file paths where each PR can be found
* Any errors or warnings
