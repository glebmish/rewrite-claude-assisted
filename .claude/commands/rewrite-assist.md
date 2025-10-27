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

### Phase 3: Recipe Mapping
Discover available OpenRewrite recipes and map extracted intents to appropriate recipes.

### Phase 4: Recipe validation
Test each recipe produced on the previous phase and make the final decision on what recipe is the final version.

### Phase 5: Final decision

Based on the results, choose the final recommended recipe and generate result artifacts.

**Output Directory**: Create `result/` subdirectory in the scratchpad directory.

**CRITICAL**: The following 4 files MUST be generated in EXACTLY the specified formats. These files are parsed by automated analysis scripts.

#### Required Files

**1. `result/pr.diff`** - Original PR diff
```bash
cd .workspace/<repo-name>
git diff main...<pr-branch> > <scratchpad-dir>/result/pr.diff
```
- Format: Unified diff format (output of `git diff`)
- Purpose: Ground truth for comparison

**2. `result/recommended-recipe.yaml`** - Final recipe YAML
- Format: Valid OpenRewrite recipe YAML
- Content: The recommended recipe composition
- Must be syntactically valid and executable

**3. `result/recommended-recipe.diff`** - Recipe output from main branch

**IF empirical validation was performed** (recipe tested with worktree):
```bash
cd .workspace/<recipe-test-worktree>
git diff main > <scratchpad-dir>/result/recommended-recipe.diff
```

**IF only analytical validation** (no empirical testing):
- Generate a theoretical diff showing expected recipe output
- OR: Create descriptive text explaining expected changes

**4. `result/recommended-recipe-to-pr.diff`** - Recipe compared to PR

**CRITICAL FORMAT REQUIREMENT**: This file MUST be in unified diff format for automated precision analysis.

**IF empirical validation was performed**:
Use the `scripts/create-diff.sh` script to generate the diff:
```bash
scripts/create-diff.sh \
  .workspace/<repo-name> \
  <recommended-recipe-branch> \
  <pr-branch> \
  <scratchpad-dir>/result/recommended-recipe-to-pr.diff
```

The script will:
- Validate the repository path and branches exist
- Generate a diff from recommended-recipe-branch to pr-branch
- Save the output to the specified file
- Report success with file size and line counts

**Validation**: After running the script, verify the output file was created:
```bash
ls -lh <scratchpad-dir>/result/recommended-recipe-to-pr.diff
```

**IF only analytical validation** (no empirical dry-run):
Create an EMPTY unified diff (indicating perfect theoretical match):
```bash
cat > result/recommended-recipe-to-pr.diff << 'EOF'
# Empty diff - analytical validation only
# Empirical validation not performed
EOF
```

**IMPORTANT**: Do NOT create a text comparison report. The file must be parseable by `scripts/analysis/recipe-diff-precision.sh` which expects:
- Lines starting with `+` (additions)
- Lines starting with `-` (deletions)
- Lines starting with `@@` (diff headers)
- OR: Empty file (indicating perfect match)

**Format Validation**: After generating the diff, verify it's in the correct format:
```bash
# This should show diff lines OR be empty (both acceptable)
grep -E '^[+\-@]' result/recommended-recipe-to-pr.diff || echo "Empty diff (perfect match)"

# This should NOT match (text reports are invalid)
grep -i "comparison\|analysis\|assessment" result/recommended-recipe-to-pr.diff && echo "ERROR: Text report format detected"
```

**Human-Readable Analysis**: Any comparison summaries, assessments, or detailed analysis should go in:
- The main scratchpad file (rewrite-assist-scratchpad.md)
- OR: A separate `result/analysis.md` file
- NOT in the `recommended-recipe-to-pr.diff` file

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