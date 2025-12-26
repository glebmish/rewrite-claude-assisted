# Manual review

https://github.com/glebmish/rewrite-claude-assisted/actions/runs/19662534794

## General observations

* Overall change compared to [2025-11-29-sonnet-with-mcp](../2025-11-29-sonnet-with-mcp):
  * Average cost: +84%
  * Average time: -10%
  * Recipe correctness:
    * Average precision: +2%
    * Average recall: -16%
    * Average f1:  -16%
* At the first glance it's a disaster run with almost 2x the cost and worse performance
  * Looking deeper, the only underperforming test is the one that cannot be replicated by existing OpenRewrite recipe
  * Sonnet run delete the files that were supposed to be deleted, but couldn't update the rest - left the code in a broken state
  * Opus didn't touch those files - a lot of changes weren't replicated
  * On top of that Opus made 2 perfect recipes (and missed another one that Sonnet had as perfect)
  * Gemini analysis suggests that Opus used more elaborate and semantical recipes which sounds like those might be more robust for real use
* Changes from the previous eval:
  * **only** switched to opus in main agent and subagents

## Evals observations

### Run 0

#### Tool use errors
* 3x `ls -la /usr/lib/jvm/` - Claude Code blocks out of context ls commands - not sure I can do anything with that

#### Recipe
* Perfect score!
* Successfully upgraded wrapper version in build.gradle - that was missed in the previous run.


### Run 1

#### Tool use errors
* same ls errors
* gradle run first attempted with java 17, fixed by using java 11

#### Recipe
* Did not delete files that were deleted in PR - much worse result, but left the project in the working state

tbd
### Run 2

#### Tool use errors

#### Recipe



### Run 3

#### Tool use errors

#### Recipe



### Run 4

#### Tool use errors

#### Recipe
