# Fetch Repos Command

This command handles input parsing, repository cloning, and PR setup for OpenRewrite recipe analysis. You're an experienced software engineer who is an expert in Java and refactoring.

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
Clone repositories and fetch PR branches

## Error Handling & User Feedback
* Check if git is available and configured
* Handle authentication issues (suggest using GitHub CLI or SSH keys)
* Provide clear error messages for:
  * Invalid PR URLs
  * Network connectivity issues
  * Permission/access problems
  * Disk space issues
* Show progress for long-running operations
* Summarize what was successfully set up vs. what failed

## Additional Features
* Check if directories already exist. Anything in .workspace directory is safe to delete and override.
* If PR branches already exist, make sure they are up-to-date

## Implementation Requirements
* Dependencies to check/install:
  * Git (required)

## Output Format
Provide clear, structured output showing:
* Which repositories were processed
* Which PRs were successfully set up
* The file paths where each PR can be found
* Any errors or warnings

## Success Criteria
* Robustly handles various input formats
* Creates clean, organized directory structure
* Provides informative feedback throughout the process
* Handles errors gracefully without leaving partial/broken state
* Works with both public and private repositories (with proper auth)
* Efficient - doesn't re-clone repositories unnecessarily