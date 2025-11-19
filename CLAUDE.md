# OpenRewrite Recipe Assistant

## Project Structure
- Java 21 project using Gradle
- OpenRewrite 8.37.1 framework
- JUnit 5 for testing

## Bash Commands

### Main restrictions
NEVER UNDER ANY CIRCUMSTANCES use `>` or `>>` redirects for writing files. This commands will ALWAYS fail. Prefer using command line arguments to choose output.
If such argument is not available, use Write or Edit tools. Example: "Read(input_file) -> Write(input_file)" is GOOD, "Bash(cat input_file > output_file)" is BAD.
!I REPEAT AND REMEMBER IT AS IF YOU LIFE DEPENDS ON IT: NEVER UNDER ANY CIRCUMSTANCES use `>` or `>>` redirects for writing files!

### Using Edit tool

**CRITICAL**: The Edit tool requires the `old_string` to be UNIQUE in the file. If the string appears multiple times, the edit will FAIL.

**Best practices for reliable edits:**
1. **Use unique strings**: Include enough surrounding context to make the pattern unique
   - BAD: `---\n\n` (common separator, likely appears multiple times)
   - GOOD: `### Phase 5\n\nSome unique content\n---\n\n` (includes unique context)

2. **Verify uniqueness**: Before editing, check how many times the pattern appears:
   ```bash
   grep -c "pattern" file.md
   ```
   If count > 1, expand the pattern to include more unique context.

3. **Use structural markers**: For appending to end of file, use unique end-of-file markers:
   - Look for unique last lines (e.g., final section heading, signature, specific content)
   - Do NOT use generic separators or empty lines

4. **When appending to files**: Find a truly unique string at the end, such as:
   - Last section with specific content
   - Unique closing statement
   - Specific final line that won't be duplicated

5. **If pattern is still ambiguous**: Use Write tool to rewrite the entire file instead of Edit

### Changing directory
ALWAYS use full path whenever you use `cd` command.

If any of the commands you've executed might have changed working directory, establish current working directory with `pwd`
command first before attempting to run any other command. Track how this directory changes after command executions.

### Cloning repositories
Always clone repositories to the .workspace directory and use repository name as directory name
Always use `git@` links for cloning. Assume correct ssh keys are set up for you.
Always use shallow clone: `git clone --depth 1 {repo-url} {directory}`
Fetch PRs using: `git fetch origin pull/{pr-number}/head:pr-{pr-number}`
When you need to access repository files, clone it first and work with the cloned version. Avoid fetching files from web.

### Access to repository data on Github
ALWAYS use `gh` tool to access repositories. NEVER EVER use WebFetch tool even when the input you work with is an https link.
Prefer targeted commands over api commands, e.g. `gh pr` commands, not `gh api <pr-link>`
For complete PR data use this: `gh pr view <pr-link> --json number,headRefName,baseRefName,headRepositoryOwner,url`

### Current date and time
* `date +"%Y-%m-%d"` - get formatted date. If a different format is needed, you may modify this command.
* `date +"%Y-%m-%d-%H-%M"` - get formatted date and time. If a different format is needed, you may modify this command.

### Using java and gradle
ALWAYS check the version of default `java` binary and compare it with the version set in project build.gradle
Use `update-alternatives --config java` to see all available versions and locate the version matching the one in build.gradle
Prefix and java and gradle command for non-default java versions with `JAVA_HOME=<path-to-java>`, e.g. `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ./gradlew clean build`
For Java 8 projects use Java 11 jdk

When working with cloned repositories in .workspace directory, ALWAYS execute gradle commands from the repository root using `./gradlew`.
Example: `cd /path/to/.workspace/repo-name && ./gradlew build`
Never use gradle wrapper from a different location or assume gradle is globally installed.

### Scratchpad Management

* !!IMPORTANT!! When scratchpad file is passed to you in the initial prompt, append to this file and do not
attempt to resolve session or create a new file. If you've created any intermediate scratchpads, make sure their content
is transferred to the main scratchpad and intermediate files are deleted.
* At the beginning of main session get current date and time and create `.scratchpad/<yyyy-mm-dd-hh-MM>` directory.
All scratchpad, context and analysis files for the given session and subagent sessions must be saved to this directory.
* Pass the context on what the current directory is to each subagent. They must use this existing directory.
* !!IMPORTANT!! At the beginning of main session retrieve session ID using and save it to the scratchpad directory: `scripts/get-session-id.sh -o .scratchpad/<yyy-mm-dd-hh-MM>/session-id.txt`.
Do retry it with different path variations and ALWAYS fail fast if you are not able to execute this command.
* Your scratchpad is a detailed, chronological execution log, not a summary. It must be a completely honest record of your process.
You *must* log both successes and failures. When a tool call fails, you *must* log the error message from stderr and your
hypothesis about the cause of the failure before logging your next recovery attempt. Do not hide your mistakes. 
A detailed failure log is more valuable than a clean but misleading summary. Describing your struggles will help me to improve the workflow.

ALWAYS keep the following types of scratchpads
* Slash command execution log:
  * Use `<command-name>-scratchpad.md` scratchpad file name
  * If there's already a file for the given session id, keep writing to this file
  * Append only, you cannot modify lines that were added before.
  * Make it very comprehensive, detailed and truthful even when you execute multiple commands in a row.
  * Log the execution of each phase, all commands with the reason why you execute it and its results
  * Track overall progress and any issues encountered across phases
  * Use the same scratchpad file for all commands and subagents in the same session
* Context scratchpad:
  * Use `<command-name>-context.md` scratchpad file located in .scratchpad directory
  * Use this scratchpad to maintain context across main agent and subagents
  * All subagents must read this file on start
  * All subagents may append to this file
  * It must be clearly stated what subagents contributed each part of the scratchpad

### General direction
* Do not use subagents unnecessarily
* When tool use fails and this is a bash command with pipes, simplify it and try again before failing (even in strict mode)