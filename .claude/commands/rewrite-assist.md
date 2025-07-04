# Rewrite Assist command
## Input Handling:

If GitHub PR URLs are provided as arguments, use those directly
If no arguments provided, interactively prompt the user to paste/enter a list of GitHub PR URLs
Accept multiple formats:
Full PR URLs: https://github.com/owner/repo/pull/123
Short format: owner/repo#123
Mixed lists with whitespace, commas, or newlines as separators
Core Functionality
1. Parse and Validate PRs
Extract repository information (owner, repo name) and PR numbers from input
Group PRs by repository to minimize cloning operations
Validate that URLs are valid GitHub PR formats
Handle edge cases like private repos with no access or invalid PR numbers gracefully
2. Repository Setup
For each unique repository:

## Directory Structure:

.workspace/
├── owner-repo-name/          # Main repo directory
│   ├── main/                 # Default branch worktree
│   └── pr-123/               # PR branch worktree
│   └── pr-456/               # Another PR branch worktree
└── another-owner-repo/
    ├── main/
    └── pr-789/

## Git Operations:

* Create .workspace directory if it doesn't exist
* For each repository:
  * Create directory named {owner}-{repo-name} in .workspace
  * Shallow clone the repository's default branch (usually main or master)
  * Set up the main branch as a git worktree in main/ subdirectory
* For each PR in that repository:
  * Fetch the PR branch: git fetch origin pull/{pr-number}/head:pr-{pr-number}
  * Create a worktree for the PR branch in pr-{pr-number}/ subdirectory

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
* Check if directories already exist and ask before overwriting
* Option to update existing PR branches if they already exist
* Display a summary of created worktrees and their paths
* Optionally open the workspace in the user's preferred editor/IDE

## Implementation Requirements
* Dependencies to check/install:
  * Git (required)
  * GitHub CLI (gh) for authentication (optional but recommended)

## Commands to use:

### Shallow clone
git clone --depth 1 --branch {default-branch} {repo-url} {directory}

### Set up worktrees
git worktree add {path} {branch}

### Fetch PR
git fetch origin pull/{pr-number}/head:pr-{pr-number}

## Output Format
Provide clear, structured output showing:
* Which repositories were processed
* Which PRs were successfully set up
* The file paths where each PR can be found
* Any errors or warnings
* Next steps for the user

## Example Usage
/rewrite-assist https://github.com/facebook/react/pull/12345 https://github.com/vercel/next.js/pull/67890

### Interactive mode
/pr-workspace
> Please enter GitHub PR URLs
> https://github.com/owner/repo/pull/123 https://github.com/owner/repo/pull/456 https://github.com/another/repo/pull/789

## Success Criteria
* Robustly handles various input formats
* Creates clean, organized directory structure
* Provides informative feedback throughout the process
* Handles errors gracefully without leaving partial/broken state
* Works with both public and private repositories (with proper auth)
* Efficient - doesn't re-clone repositories unnecessarily
