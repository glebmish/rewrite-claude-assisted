# OpenRewrite Recipe Assistant

## Project Structure
- Java 21 project using Gradle
- OpenRewrite 8.37.1 framework
- JUnit 5 for testing

## Development Commands

### Changing directory
At the very beginning initialize CLAUDE_WORKDIR_ROOT variable to the current directory. At any time if you confused and `cd` commands fail it might be because you are in an unexpected directory. SIn this case switch to CLAUD_WORKDIR_ROOT directory and continue from there.
All comands that require you to change directory (use `cd`) must be suffix by changing back to the original directory (`cd -`)
If you decide that you need to stay in a directory, further path constructions should be done relative to the current directory (e.g. using `../` to go to the parent directory)

### Cloning repositories
Always clone repositories to the .workspace directory
Always use shallow clone: `git clone --depth 1 --branch {default-branch} {repo-url} {directory}`
Create worktrees using: `git worktree add {path} {branch}`
Fetch PRs using: `git fetch origin pull/{pr-number}/head:pr-{pr-number}`
If you plan to use worktrees, create a directory for all worktrees of a repository, clone main branch to main subdirectory and other branches in directories called after the branch name. Never create worktrees inside another repository.

### Build and Test
```bash
./gradlew build
./gradlew test
./gradlew clean build
```

### Running Tests
```bash
./gradlew test --info
```

### Check Dependencies
```bash
./gradlew dependencies
```

## Project Goals
- Analyze PRs to extract refactoring intent
- Generate custom OpenRewrite recipes
- Test recipes against original PR changes
- Minimize token usage while maintaining quality

## Key Dependencies
- `org.openrewrite:rewrite-java` - Java code transformations
- `org.openrewrite:rewrite-xml` - XML transformations  
- `org.openrewrite:rewrite-properties` - Properties file handling
- `org.openrewrite:rewrite-yaml` - YAML transformations
- `org.openrewrite:rewrite-json` - JSON transformations
- `org.openrewrite:rewrite-test` - Testing utilities

## Development Notes
- Use temporary workspace for external repositories
- Focus on token cost optimization
- Leverage existing OpenRewrite recipes where possible
- Test thoroughly before generating final recipes