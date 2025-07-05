# Rewrite Assist command
This command is located in the repository with custom OpenRewrite recipes. You're an experienced software engineer who is an expert in Java and refactoring. You always strive to break down complicated task on small atomic changes. This skill is essential for creating great OpenRewrite recipes by combining existing recipes and writing the new ones.

While executing this command, execute the following workflow step-by-step.
Save your thought process and all other output to scratchpad md files located in .scratchpad directory. They must be prefixed with current date and time.

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
> Please enter GitHub PR URLs
> https://github.com/owner/repo/pull/123 https://github.com/owner/repo/pull/456 https://github.com/another/repo/pull/789

## Step 1: Process input and fetch repositories
###  Parse and Validate PRs
  * Extract repository information (owner, repo name) and PR numbers from input
  * Group PRs by repository to minimize cloning operations
  * Validate that URLs are valid GitHub PR formats
  * Handle edge cases like private repos with no access or invalid PR numbers gracefully

### Repository Setup
All repositories must be fetched into .workspace directory that is ignored by .gitignore

### Directory Structure:

.workspace/
├── owner-repo-name/          # Main repo directory
│   ├── main/                 # Default branch worktree
│   └── pr-123/               # PR branch worktree
│   └── pr-456/               # Another PR branch worktree
└── another-owner-repo/
    ├── main/
    └── pr-789/

### Operations:

* Create .workspace directory if it doesn't exist
* For each repository:
  * Create directory named {owner}-{repo-name} in .workspace
  * Shallow clone the repository's default branch (usually main or master)
  * Set up the main branch as a git worktree in main/ subdirectory
* For each PR in that repository:
  * Fetch the PR branch: git fetch origin pull/{pr-number}/head:pr-{pr-number}
  * Create a worktree for the PR branch in pr-{pr-number}/ subdirectory

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
* Check if directories already exist and ask before overwriting
* Option to update existing PR branches if they already exist
* Display a summary of created worktrees and their paths
* Optionally open the workspace in the user's preferred editor/IDE

### Implementation Requirements
* Dependencies to check/install:
  * Git (required)
  * GitHub CLI (gh) for authentication (optional but recommended)

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

### Step 2: Analyze diff changes, think about why this changes were made and compile a list of goals that are targeted