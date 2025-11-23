# Manual review

https://github.com/glebmish/rewrite-claude-assisted/actions/runs/19611767789

## General observations

* Overall a huge success and much more complete and polished workflow. Ready for further tests with minimal changes.
* Main fixes since the previous eval:
  * Got read of single-file detailed scratchpad, use smaller and more structured separate files with clear requirements instead
    * Less file edit errors, reduced token consumption
  * Validation is executed as a script instead of series of steps for the agent to reproduce
    * More robust, better control on what files are included to the resulting diff, real recipe application instead of dry-run
  * Fixed precision script and aggregation script
  * Fixed a bizzare encoding error that led to corrupted diffs, but now I see this all over the logs `setlocale: LC_ALL: cannot change locale (en_US.UTF-8)`
  * An error that wasn't fixed: Claude Code subagents don't change working directory on `cd` even when `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=0` is set. Looks like a bug
* Overall improvement compared to [2025-11-17-sonnet-only](../2025-11-17-sonnet-only):
  * Average cost: -36.5% (more efficient)
  * Average time: -37% (quicker)
  * Recipe correctness: small improvement, however this was not the goal of the improvements for this eval
    * Average precision: +10%
    * Average recall: -1%
    * Average f1: +23
* Outlier run 2 had many tool errors and additional work, will be retested.

## Evals observations

### Run 0
#### Tool use errors
**none**

#### Phases and result
* phase1 to phase5 separate docs with good structure
* phase3 - good analysis of semantic vs text-based transformation, useful for making the decision between recipes
* phase4 - coverage % doesn't seem to be based in reality, post-workflow precision analysis shows different numbers, manual review confirms
  * phase4 doc and validation analysis doc don't mention code changes that aren't in the PR
  * it looks like if real numbers are taken into account, option 2 did a better job matching the PR (less over-application). However, option 1 was recommended.


### Run 1
This one has non-trivial code changes where Claude Code just gives up and not trying to write a recipe for it. As a result, only simple changes like java upgrade are included.

#### Tool use errors
* `get-session-id.sh` script is used with full path instead of relative path that is allowed. Not an error but more of a Claude Code restriction that is not useful.
* `wc` failed with `requires approval` once but somehow worked on the next call.
* 2x `validate-recipe.sh` is called with relative paths, even though it's required to use full paths.

#### Phases and result
* Well-structured docs, consistent set of files from run to run. 

### Run 2
This run is a complete outlier. It failed on first try, fixed validation script and restarted both validations.
Somehow this worked, although it's not clear why it didn't work the first time. `yq` call that it fixed does work
correctly with the recipe files.

#### Tool use errors
28 errors overall, here are the significant ones (actual failures from logs)
* Incorrectly detected Java 17 instead of Java 11 and got `Unsupported class file major version 61`
* `Error: 1:18: lexer: invalid input text \"\\\\!= null)\",` - encoding issue because of explicit `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"`??
  * '.name' works, but `.name | select(. != null)` doesn't

#### Phases and result
* Detailed analysis for failed runs was later overwritten by successful retries. If that will be repeating, should fix that to have all docs.
* phase2 doesn't write down intent tree as it's asked.

### Run 3
#### Tool use errors
* `get-session-id.sh` script is used with full path instead of relative path that is allowed. Not an error but more of a Claude Code restriction that is not useful.
* `git diff` after another successful git diff, unclear why it felt it needs to do that. Funny that `cd /...` failed, not `git diff`, and that's because cd with full path is not allowed
* `validate-recipe.sh` is called with relative paths, even though it's required to use full paths.
* `awk` not allowed


### Run 4
#### Tool use errors
* `Read(/.claude/commands/fetch-repos.md)` - incorrect path
* 2x `validate-recipe.sh` is called with relative paths, even though it's required to use full paths.
* Attempt to use redirects `>` for file write