# Manual review

https://github.com/glebmish/rewrite-claude-assisted/actions/runs/18999222631
This review is added by Gleb after evals were executed and saved to the repository.

### General observations

* **After further analysis, haiku run turned out to be completely incorrect and mostly result in an hallucinated output, not actual verification happened.**
* During execution, there was an intermittent issue with session-id.txt not being saved by CC. Need to look more into it.
  * Early observation for Sonnet eval - same issue occurs (and on the same test 3)
* This run tests workflow performance when only Haiku model is used. Haiku 4.5 is used by the main agent,
but Haiku 3.5 is used by subagents since it seems to be what `model: haiku` in subagent definition resolve to.
* Cost calculations were wrong and fell back to sonnet 4.5 for everything. Fixed script and recalculated results.
  * In each eval correct result is in claude-cost-stats-recalculated.json
  * For the aggregated result correct data is in suite-results-cost-recalculated.json and summary-cost-recalculated.md 
* Extraction of used tools is not working great which is to be expected. However it's not a part of aggregation, so I'll ignore it.
* Need to work on git worktree instructions - saw issues in 2 recipes, didn't check the rest. A lot of failed tool uses come from here.
* Tasks do use WebSearch. I plan to move it mostly to MCP usage where all the necessary recipe info will be present.
* SlashCommand tool doesn't work, figure out why. Cause of some tool use failures.
* Precision calculation was completely rewritten since the grep-based one wasn't enough to properly calculate FP and FN
  * New one compares pr diff with recommended recipe diff and doesn't need diff from pr to recipe. That will simplify things
  * Some tests miss recipe diff, need to work on that
* **Serious issues with recipe validation and truthfulness of the scratchpad** (validation failures weren't reported)

### Evals observations

#### [0-gradle-wrapper-version-and-plugin-version-upgrade](0-gradle-wrapper-version-and-plugin-version-upgrade)
* overall - great!
* I've noticed SlashCommand tool that I wasn't aware of before and I'd expect it to work with `/fetch-repos <pr url>`.
However it fails with `Error: Execute slash command: /fetch-repos` and CC has to manually find the file and read it
(this part is successful, it shows  that command exists)
* Intention extraction looks good and the intention tree it produces makes sense. There was a lot of help from PR name
and description though.
* Flawless resulting recipe on the correct abstraction level
* I see that CC struggles to create gitworktree to test the recipe. It wasn't created at all.
I'll wait until sonnet evals to see if that's just a task that's too complicated for haiku 3.5 or
a poor prompt.

#### [1-gradle-wrapper-upgrade](1-gradle-wrapper-upgrade)
* Same issue with `git worktree`, but seems like this one eventually created it.
* This test seems too simple and redundant - same is covered by 0
* Intent tree structure is a bit worse

#### [2-dockerfile-and-github-actions-java-bump](2-dockerfile-and-github-actions-java-bump)
* produced unnecessary file `intent-tree.json` and scratchpad is scattered across multiple files
* Unless these are actually the best matching recipes and there are no docker/github actions specific recipes,
the resulting recipe looks more like hacking the system - it's all text replacements.
* Format of resulting recipe yaml in wrong - it includes another recipe aside from the recommended one
* Intent tree is weirdly formatted but generally correct
* this one is the most expensive one, I wonder why

#### [3-java-11-to-17-with-auth-upgrade](3-java-11-to-17-with-auth-upgrade)
* a much more complicated PR with code changes and deleted files
* this run shows a bug in precision calculations, will have to fix and recalculate everything
  * Seems to related to delete files in PR that weren't deleted in the recipe. This inflates false positive countwould.
* missing Phase 1 (repo cloning) in the scratchpad

#### [4-junit-4-to-5-upgrade](4-junit-4-to-5-upgrade)
* Recipe seems to use correct junit5 task (`org.openrewrite.java.testing.junit5.JUnit4to5Migration`), but it didn't change any java code for some reason
* Diff from recipe to PR is completely wrong (empty while no java changes were actually made)
* It looks like workflow completely ignored changes and java files. Claude keeps saying that it achieved 100% coverage

#### [5-dropwizard-3-upgrade](5-dropwizard-3-upgrade)
* Doesn't seem like it was actually successful with recipe testing and instead it hallucinated recipe diff
  * **!Serious issue!**
  * **Also, scratchpad and output have no mention of any issues with verification**
* Less trivial PR with java code changes, recipe Claude came up with seems correct and well-structured

#### [6-h2-to-postgres-migration](6-h2-to-postgres-migration)
* **Also no actual recipe validation!**
* Validation issues were reported

#### [7-complicated-java-dropwizard-upgrade](7-complicated-java-dropwizard-upgrade)
* **Diff is completely wrong and is not an output of `git diff` at all**
* 

#### 8
#### 9

