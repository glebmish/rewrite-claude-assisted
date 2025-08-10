# OpenRewrite Recipe Assistant

## Project Structure
- Java 21 project using Gradle
- OpenRewrite 8.37.1 framework
- JUnit 5 for testing

## Bash Commands

### Changing directory
ALWAYS use full path whenever you use `cd` command

### Cloning repositories
Always clone repositories to the .workspace directory and use repository name as directory name
Always use `git@` links for cloning
Always use shallow clone: `git clone --depth 1 {repo-url} {directory}`
When you want to create worktrees use: `git worktree add ../{repository-name-}-{branch-name} {branch}`
Fetch PRs using: `git fetch origin pull/{pr-number}/head:pr-{pr-number}`

### Current date and time
* `date +"%Y-%m-%d"` - get formatted date. If a different format is needed, you may modify this command.
* `date +"%Y-%m-%d-%H-%M"` - get formatted date and time. If a different format is needed, you may modify this command.

### Using java and gradle
ALWAYS check the version of default `java` binary and compare it with the version set in project build.gradle
Use `update-alternatives --config java` to see all available versions and locate the version matching the one in build.gradle
Prefix and java and gradle command for non-default java versions with `JAVA_HOME=<path-to-java>`, e.g. `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ./gradlew clean build`
For Java 8 projects use Java 11 jdk

### Scratchpad Management

* At the beginning of main session get current date and time and create `.scratchpad/<yyyy-mm-dd-hh-MM>` directory.
All scratchpad, context and analysis files for the given session and subagent sessions must be saved to this directory.
* Pass the context on what the current directory is to each subagent. They must use this existing directory.
* Use `scripts/get-session-id.sh` command to retrieve session id.
* Very first line of each scratchpad must be `Session ID: <id>`.

ALWAYS keep the following types of scratchpads
* Slash command execution log:
  * Use `<yyyy-mm-dd-hh-MM>-<command-name>-<session-id>.md` scratchpad file name
  * If there's already a file for the given session id, keep writing to this file
  * Append only, you cannot modify lines that were added before.
  * Make it very comprehensive, detailed and truthful even when you execute multiple commands in a row.
  * Log the execution of each phase, all commands with the reason why you execute it and its results
  * Track overall progress and any issues encountered across phases
* Context scratchpad:
  * Use `<yyyy-mm-dd-hh-MM>-context.md` scratchpad file located in .scratchpad directory
  * Use this scratchpad to maintain context across main agent and subagents
  * All subagents must read this file on start
  * All subagents may append to this file
  * It must be clearly stated what subagents contributed each part of the scratchpad
