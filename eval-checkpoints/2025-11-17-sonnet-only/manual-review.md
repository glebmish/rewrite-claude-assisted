# Manual review

https://github.com/glebmish/rewrite-claude-assisted/actions/runs/19425122674

## General Observations

* After further analysis, haiku run turned out to be completely incorrect and mostly result in an hallucinated output, not actual verification happened.
* On haiku checkpoint I noted that better tool use visibility is not that important. In reality, it became the most
important change I've made for troubleshooting.
* I also used post-run Gemini assessment. Gemini CLI was chosen because of the generous free tier. Prompt is constant:
  ```
  Analyze workflow run in @tmp/2-run1-run-metadata/ . Pay special attention to the correctness of the required output files. Thoroughly analyze used tools and failed uses (you
  can see failed uses prefixed by '*' in claude-usage-stats.json. Cross-reference usages to the logs. Analyze which parts Claude particularly struggled with and which completely
  failed to do. See if there's any significant token wastage going on. See if actual log is correctly reflected in the scratchpad files. Do any additional validations and
  verifications that you find useful. Be thorough. Don't take workarounds and lies as "fixes" or "smart" decisions.
  ```
* Many fixes related to precision calculation: diff parsing failed for binary file diffs and changes to gradlew/gradlew.bat distorted
the result. Latter issue was fixed after test suite started and suite commit was set. Recalculated data is available
  * **There still seems to be a serious bug present**
* Manual precision stats calculation shown the following issues:
  * rewrite.patch contains duplicated diffs, only observed for gradle files (gradle-daemon.properties, gradle-daemon.jar, gradlew, gradlew.bat)
  * rewrite.gradle is included to the rewrite.patch in runs 2 and 4

## Evals observations


### Run 0
#### Tool failures
Impressive run with minimal failures and always-correct gradle rewrite calls
* `main - *Bash('gh pr view https://github.com/openrewrite-assist-testing-dataset/ecommerce-catalog/pull/2 --json number,headRefName,baseRefName,repository')`
  * happens pretty much always, it tries to use `repository` field that doesn't exist. Trivial to fix
* `main - *Edit(/__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/rewrite-assist-scratchpad.md)`
  * also one of the most common failures. Not that important to fix now, since for cost optimizations I'll be changing scratchpad usage completely
* `main - *Bash('ls -lh /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/ && echo \"\" && echo \"Verifying required files:\" && test -f /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/pr.diff && echo \"\u2713 pr.diff exists\" || echo \"\u2717 pr.diff MISSING\" && test -f /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/recommended-recipe.yaml && echo \"\u2713 recommended-recipe.yaml exists\" || echo \"\u2717 recommended-recipe.yaml MISSING\" && test -f /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/recommended-recipe.diff && echo \"\u2713 recommended-recipe.diff exists\" || echo \"\u2717 recommended-recipe.diff MISSING\"')`
  * logs `Error: This Bash command contains multiple operations. The following parts require approval: test -f /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/pr.diff, test -f /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/recommended-recipe.yaml, test -f /__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-00/result/recommended-recipe.diff`
  * Logging is good, fixing is trivial. My guess is that kind of complex commands is an agent attempt to save on context use and it might go away during cost optimization changes.

#### Scratchpad and output
* HUUUGE - almost 2k lines, and that seems to be one of the most pressing issues and a source of instability and hacks agent employs to save context
  * Saying that, actual content seems useful. All phases are there. But nobody would read 2k lines, I haven't.
* *-context file is abandoned early and don't have a lot of useful information. The original intent was to provide context for subagents,
but it's content now is not doing that. It's written just once and never read by any subagent.
* Output claim on coverage is not consistent with further diff analysis:
  * Claimed: `**95% coverage** of PR changes (vs 75% for broad approach)`
  * Reality (from recalculated json): precision: 1.0, recall: 0.5714, f1_score: 0.7273
  * Consider moving stats calculation to the main workflow so that agent can use that information

#### Gemini analysis
* Highlights that struggles are highlighted in the scratchpad. Good, truthfulness of the scratchpad differs randomly between runs.
  * `Crucially, the agent did not fail silently or lie. It correctly identified this discrepancy in the rewrite-assist-scratchpad.md as a "GAP IDENTIFIED" and a "KEY          
  DIFFERENCE". In its final summary, it correctly labels this as an "Acceptable Gap" and explains the functional equivalence, demonstrating a deep understanding of the     
  problem and the tools' limitations.`
* For this run Gemini praises high cache reads while it usually highlights it as a main wastage point.
  * This cache reads are likely scratchpad management.
* `The agent's qualitative analysis in the scratchpad is more valuable than these raw scores, as it correctly explains why the numbers are what they are. It understands the    █
  nuance behind the metrics`
  * Good insight, but I need to work on making the insights more readable, not buried withing a huge file


### Run 1
Did not refactor most of the application code, that was the main challenge of the test (`**Authentication refactoring** (business logic changes) - **NOT AUTOMATABLE**`)
This run shows a critical error in precision calculation. Somehow it shows 0 true positive changes when almost all changes in gradle-wrapper.properties,
build.gradle and Dockerfile are correct.

#### Tool failures
* `main - *Bash('gh pr view https://github.com/openrewrite-assist-testing-dataset/ecommerce-catalog/pull/2 --json number,headRefName,baseRefName,repository')`
  * happens pretty much always, it tries to use `repository` field that doesn't exist. Trivial to fix
* Multiple of `Edit` for the scratchpad file
  * frequent scratchpad edit issue
  * main agent and subagents are affected
* `Read` failures where agent mixed up `/.workspace/rewrite-claude-assisted/.scratchpad/2025-11-15-19-29/rewrite-assist-context.md` (wrong)
with `/__w/rewrite-claude-assisted/rewrite-claude-assisted/.scratchpad/2025-11-15-19-29/rewrite-assist-context.md` (correct). Recovered easily
* Multiple of `openrewrite-recipe-validator - *Bash('JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 ./gradlew rewriteDryRun --init-script rewrite.gradle')`
  * Dependencies versions in rewrite.gradle not present - supposed to rely on BOM for that. Need to look into why BOM is not sufficient.
    Recovered by setting explicit versions.
  * Agent forgot to replace `<...>` placeholders with actual values
* Multiple of `Bash` with `>` and `>>` for write operations and `<()` for input from commands
  * often see this one, I think it's a result of an overly large scratchpad file, context economy and failures to edit the file with better tools
* Some workdir confusion in cd and file access

#### Scratchpad and output
* Random new files like `phase5-complete.md` etc
* Context file is useless again, although this time it was read by subagents
* Main scratchpad is just ~850 lines, although phase5 was moved out to separate files this time.

#### Gemini analysis
* `High Cache Reads: The cache_read_input_tokens count is extremely high (~12.8 million). This is primarily due to the agent repeatedly reading the entire                       
  rewrite-assist-scratchpad.md file, which grows larger with each step. This pattern is highly inefficient.`
* `The automated analysis reported a recall of 0 and an F1-score of 0, which is completely misleading.` - correct, a serious calculation bug seems to be there.


### Run 2

#### Tool failures
_no new failures_

#### Scratchpad and output

* Scratchpad in one piece now
* ~1400 lines

#### Gemini analysis

* Highlights a lack of truthfulness in the scratchpad


### Run 3

#### Tool failures
Only new failures

* `WebFetch` permission not granted - trivial fix

#### Scratchpad and output

* ~1400 lines

#### Gemini analysis

* Highlights a lack of truthfulness in the scratchpad


### Run 4

#### Tool failures
_no new failures_

#### Scratchpad and output

* Scratchpad split on multiple files without instructions to do so

#### Gemini analysis