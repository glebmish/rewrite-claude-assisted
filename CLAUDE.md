# OpenRewrite Recipe Assistant

## Project Structure
- Java 21 project using Gradle
- OpenRewrite 8.37.1 framework
- JUnit 5 for testing

## Bash Commands

### Changing directory
When changing directory use `pwd` command often to make sure that working directory is what you expect. When using `cd` or any other command that uses working directory, always make sure that the directory is correct.

### Cloning repositories
Always clone repositories to the .workspace directory and use repository name as directory name
Always use shallow clone: `git clone --depth 1 {repo-url} {directory}`
When you want to create worktrees use: `git worktree add ../{repository-name-}-{branch-name} {branch}`
Fetch PRs using: `git fetch origin pull/{pr-number}/head:pr-{pr-number}`
