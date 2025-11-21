# Rewrite Assist Command

This is the main orchestrator command for OpenRewrite recipe development and analysis. You're an experienced software engineer who is an expert in Java and refactoring. 

This command coordinates a multiphase workflow by executing individual commands in sequence.
* Always complete a current phase first before reading description of the next phase.
* Each phase must complete successfully before proceeding to the next phase.
* When you start executing a new phase, update todo list with more details for the given phase.
* Report complete but concise results of each phase and save it to phase<N>.md file (e.g. phase1.md)

At the beginning of the workflow get current date and time and create `.output/<yyyy-mm-dd-hh-MM>` directory. All output files
for the given session and subagent sessions must be saved to this directory.
* Pass the context on what the current directory is to each subagent. They must use this existing directory.

!!IMPORTANT!! At the beginning of main session retrieve session ID using and save it to the output directory:
`scripts/get-session-id.sh -o .output/<yyy-mm-dd-hh-MM>/session-id.txt`.
* On failures, retry it with different path variations and ALWAYS fail fast if you are not able to execute this command.

Phase can be described as a slash command (`/<command-name>`). Do NOT use SlashCommand tool for those, read the command file instead (in `.claude/commands`)

**CRITICAL VERBOSITY CONSTRAINTS:**
- Be concise and factual - avoid verbose explanations
- State findings clearly in bullet points, not prose
- Skip background information and theory
- Focus on actionable results and required outputs only
- Do NOT create supplementary documentation files beyond the required files

## Workflow Overview

The complete workflow consists of these phases:

### Phase 1: `/fetch-repos <PR links>` - Repository Setup
Parse GitHub PR URLs, clone repositories, and set up PR branches for analysis.

In this phase you MUST save PR diff to the output directory.
In the code block below <default-branch> means the branch that is used in the repository by default. It is usually named `main` or `master`.
IMPORTANT: save this file before continuing the workflow

```bash
# Save original PR diff for comparison
cd <repo_directory>
git diff <default_branch> pr-<pr_number> --output=<output_dir>/pr-<pr_number>.diff
```

### Phase 2: `/extract-intent <pairs of repository-path:pr-branch-name>` - Intent Analysis  
Analyze PRs to extract both strategic (wide) and tactical (narrow) transformation intents.
You MUST NOT try to improve or add anything on top of what PR is doing. Always assume PR changes is the state the the user desires and work with PR changes only.

### Phase 3: Recipe Mapping
Discover available OpenRewrite recipes and map extracted intents to appropriate recipes.
**IMPORTANT**: Recipe name in YAML must be fully qualified (e.g., `com.example.PRRecipe123Option1`)
ALWAYS use specialized subagent to perform the mapping.

As a result two files must be created:
* .output/<yyyy-mm-dd-hh-MM>/option-1-recipe.yaml
* .output/<yyyy-mm-dd-hh-MM>/option-2-recipe.yaml

### Phase 4: Recipe validation
Test each recipe produced on the previous phase and make the final decision on what recipe is the final version.

ALWAYS use specialized subagents to perform the validation. You MUST let subagent know what options current task belongs to
(e.g. `this recipe is called option 1`, `this recipe is called option 2`)

### Phase 5: Final decision

Based on the results, choose the final recommended recipe and generate result artifacts.
This step is CRITICAL and must never be skipped. Even when results are not conclusive and none of the tested recipes
provide a definitive best output, one of the recipes must be chosen for the final recommendation.
!Failure to complete this step constitutes the failure of the whole workflow!

**Output Directory**: Create `result/` subdirectory in the output directory. Make sure it is created before any
attempts to use it.

**CRITICAL**: The following 3 files MUST be generated in EXACTLY the specified formats. These files are parsed by automated analysis scripts.
For the recommended recipe, you MUST only use yml and diff files saved to the output directory by subagents. If the files are not there,
you MUST NOT try to acquire them in any other way such as running gradle command, or create files that you assume are correct. In this case you
must clearly state that the task is failed and don't do anything else.

#### Required Files
Assuming you've already created output directory `.output/<yyyy-mm-dd-hh-MM>/` at the start of the workflow

**1. `.output/<yyyy-mm-dd-hh-MM>/result/pr.diff`** - Original PR diff
MUST be a result of `git diff` command execution
```bash
cd .workspace/<repo-name>
git diff <default-branch> <pr-branch> --output=.output/<yyyy-mm-dd-hh-MM>/result/pr.diff
```
- Format: Unified diff format (output of `git diff`)
- Purpose: Ground truth for comparison

**2. `.output/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.yaml`** - Final recipe YAML
- Format: Valid OpenRewrite recipe YAML
- Content: The SINGLE recommended recipe composition
- Must be syntactically valid and executable

**3. `.output/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.diff`** - Recipe output from main branch
MUST be copied from the subagent's validated recipe diff file (e.g., `option-1-recipe.diff`, `option-2-recipe.diff`, etc.)
```bash
cp .output/<yyyy-mm-dd-hh-MM>/<subagent-recipe-diff-file> .output/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.diff
```
- Format: Unified diff format (from OpenRewrite execution)
- Purpose: Result of OpenRewrite recipe execution for empirical validation
- Source: Must be the exact file produced by the validator subagent that validated the chosen recipe
- **CRITICAL**: Copy the subagent's resulting file directly. Do NOT generate this with git diff.

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
* Log all errors and recovery steps in the reports

## Success Criteria
* All phases complete successfully
* Actionable recommendations for recipe deployment or refinement
* **CRITICAL**: Before reporting success, verify ALL expected files exist:
  * `.output/<yyyy-mm-dd-hh-MM>/session-id.txt` - captured Session ID
  - `.output/<yyyy-mm-dd-hh-MM>/option-<N>-recipe.yaml` - generated OpenRewrite recipes
  - `.output/<yyyy-mm-dd-hh-MM>/option-<N>-recipe.diff` - diffs from recipe validation
  - `.output/<yyyy-mm-dd-hh-MM>/option-<N>-analysis.diff` - analysis based on recipe validation results
  - `.output/<yyyy-mm-dd-hh-MM>/pr.diff` - original PR diff
  - `.output/<yyyy-mm-dd-hh-MM>/phase<N>.md` - reports for each phase
  - `.output/<yyyy-mm-dd-hh-MM>/result/pr.diff` - PR diff, must be copied from `.output/<yyyy-mm-dd-hh-MM>`
  - `.output/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.yaml` - recommended recipe, must be one of the options available in `.output/<yyyy-mm-dd-hh-MM>`
  - `.output/<yyyy-mm-dd-hh-MM>/result/recommended-recipe.diff` - diff from the validation of the recommended recipe, must be copied from `.output/<yyyy-mm-dd-hh-MM>`

If ANY file is missing, the workflow has FAILED. Do NOT report success.