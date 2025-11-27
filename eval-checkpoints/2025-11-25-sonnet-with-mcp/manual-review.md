# Manual review

https://github.com/glebmish/rewrite-claude-assisted/actions/runs/19662534794

## General observations

* The main addition was the introduction of MCP that has tools for RAG search on intent and full documentation fetch for recipes
* Surprising to see overall worse results. That might stem from too rigid use of the MCP where web search was more flexible
* Overall change compared to [2025-11-23-sonnet-only](../2025-11-23-sonnet-only):
  * Average cost: exactly the same
  * Average time: -20% (quicker)
    * I guess it's thanks to MCP local document fetches that replace slower web searches
  * Recipe correctness: small improvement, however this was not the goal of the improvements for this eval
    * Average precision: -3%
    * Average recall: -17%
    * Average f1: -8%
* Main fixes since the previous eval:
  * More robust Java version definition - fixes cases where wrong java version used on the first attempt to validate
  * Test 2 failure was happening because Gradle and Java versions there were significantly older than in other tests.
    * Fixed rewrite.gradle init script to support it
  * Simplified `yq` usage since there were some errors with that too 

## Evals observations

### Run 0

#### Tool use errors
* Attempted to use full path to run `get-session-id.sh`, failed on permissions
* Overcomplicated `yq` usage with `>`, `&&`, `||`: `> dev/null` required approval.
* `ls` to check the existence of the JVM led to `For security, Claude Code may only list files in the allowed working directories for this session`
* Tried to edit file before reading it - valid
* Attempted to use relative filepath from incorrect directory even though specifically instructed to use full paths

#### Phases and result
* Overshoot with the changes because an overly broad recipe was used - touched java files even though PRs wasn't changing code at all.

### Run 1

#### Tool use errors
* Attempted to use relative filepath from incorrect directory even though specifically instructed to use full paths

#### Phases and result
* Refuses to do code changes. And since most of this PR is code, scores very low.

### Run 2

#### Tool use errors
* Attempted to use full path to run `get-session-id.sh`, failed on permissions
* `ls` to check the existence of the JVM led to `For security, Claude Code may only list files in the allowed working directories for this session`
* Attempted to use relative filepath from incorrect directory even though specifically instructed to use full paths

#### Phases and result
* Replacing `sourceCompatibility` to modern `toolchain.languageVersion` is still a struggle
* Ignores changes in the comments and strings like Github Action step name - reduces score

### Run 3

#### Tool use errors
* Attempted to use full path to run `get-session-id.sh`, failed on permissions
* Tried to edit file before reading it - valid
* `awk` permissions failure, although it is allowed

### Phases and result
* A very high scoring run - 0.95 F1 score
* Original PR removed `Override` in one file - this one doesn't do that. It's semantically correct, but lowers the score.

### Run 4
#### Tool use errors
* Attempted to use full path to run `get-session-id.sh`, failed on permissions
* Attempted to use relative filepath from incorrect directory even though specifically instructed to use full paths
* Redirects use in bash

#### Phases and result
* Doesn't put gradle dependency to the same plus + (what counts for a missed change) doesn't add comment for it
* Uses slightly different format in config `{{ GET_ENV_VAR:DATABASE_USER }}` instead of `"{{ GET_ENV_VAR:DATABASE_USER }}"`