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
You MUST NOT try to improve or add anything on top of what PR is doing. Always assume PR changes is the state the the user desires and work with PR changes only.

### Phase 3: Recipe Mapping
Discover available OpenRewrite recipes and map extracted intents to appropriate recipes.

### Phase 4: Recipe validation
Test each recipe produced on the previous phase and make the final decision on what recipe is the final version.

ALWAYS use specialized subagents to perform the validation. You MUST let subagent know what options current task belongs to
(e.g. `this recipe is called option 1`, `this recipe is called option 2`)
NEVER validate recipes concurrently. Shared workspace is used and concurrent validations will be unreliable and lead to obscure bugs.

### Phase 5: Final decision

Based on the results, choose the final recommended recipe and generate result artifacts.

**Output Directory**: Create `result/` subdirectory in the scratchpad directory. Make sure it is created before any
attempts to use it.

**CRITICAL**: The following 3 files MUST be generated in EXACTLY the specified formats. These files are parsed by automated analysis scripts.
For the recommended recipe, you MUST only use yml and diff files saved to the scratchpad by subagents. If the files are not there,
you MUST NOT try to acquire them in any other way such as running gradle command, or create files that you assume are correct. In this case you
must clearly state that the task is failed and don't do anything else.

#### Required Files
Assuming you've already created scratchpad directory `.scratchpad/<yyyy-mm-dd-hh-MM>/` at the start of the workflow

**1. `.scratchpad/<yyyy-mm-dd-hh-MM>/result/pr.diff`** - Original PR diff
MUST be a result of `git diff` command execution
```bash
cd .workspace/<repo-name>
git diff <default-branch> <pr-branch> --output=.scratchpad/<yyyy-mm-dd-hh-MM>/result/pr.diff -- . ':!gradle/wrapper/gradle-wrapper.jar' ':!gradlew' ':!gradlew.bat'
```
- Format: Unified diff format (output of `git diff`)
- Purpose: Ground truth for comparison
- Note: Excludes generated/binary Gradle wrapper files (gradle-wrapper.jar, gradlew, gradlew.bat)

**2. `.scratchpad/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.yaml`** - Final recipe YAML
- Format: Valid OpenRewrite recipe YAML
- Content: The SINGLE recommended recipe composition
- Must be syntactically valid and executable

**3. `.scratchpad/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.diff`** - Recipe output from main branch
MUST be copied from the subagent's validated recipe diff file (e.g., `option-1-recipe.diff`, `recipe-option-2.diff`, etc.)
```bash
cp .scratchpad/<yyyy-mm-dd-hh-MM>/<subagent-recipe-diff-file> .scratchpad/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.diff
```
- Format: Unified diff format (from OpenRewrite rewrite.patch)
- Purpose: Result of OpenRewrite recipe execution for empirical validation
- Source: Must be the exact file produced by the validator subagent that validated the chosen recipe
- **CRITICAL**: Copy the subagent's output file directly. Do NOT generate this with git diff.

**4. other output files**
**Human-Readable Analysis**: Any comparison summaries, assessments, or detailed analysis should go in:
- The main scratchpad file (rewrite-assist-scratchpad.md)
- OR: A separate `result/analysis.md` file

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
* **CRITICAL**: Before reporting success, verify ALL 3 required files exist in result/ directory:
  - `.scratchpad/<yyyy-mm-dd-hh-MM>/result/pr.diff`
  - `.scratchpad/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.yaml`
  - `.scratchpad/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.diff`

  If ANY file is missing, the workflow has FAILED. Do NOT report success.