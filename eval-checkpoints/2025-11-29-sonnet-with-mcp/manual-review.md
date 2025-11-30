# Manual review

https://github.com/glebmish/rewrite-claude-assisted/actions/runs/19662534794

## General observations

* Overall change compared to [2025-11-25-sonnet-with-mcp](../2025-11-25-sonnet-with-mcp):
  * Average cost: +31% (more expensive)
  * Average time: +42% (slower)
  * Recipe correctness:
    * Average precision: +39%
    * Average recall: +67%
    * Average f1: +66%
* Huge increase in recipe effectiveness why still being less expensive than early unoptimized workflow
  * Obvious limiting factor now is that the workflow only knows how to combine existing recipes. OpenRewrite allows code recipes that aren't touched here
* Changes from the previous eval:
  * Added instructions specific for the OpenRewrite MCP use
    * Multi-query RAG searches
  * Improvements for intent tree:
    * Requirement to check every intent on relevant recipes and attempt to replicate all changes
    * Save intent tree as a separate file for better structure and reuse
    * Additional pass during recipe generation to validate recipe arguments and fill in the gaps
  * Minor changes to increases chances it uses correct filepaths, etc
  * Added recipe effectiveness data to the workflow (executing script to see precision, recall and f1)
  * MAJOR: new recipe refinement phase that acts on the results of initial recipe validation, generates and validates a new recipe
  * ci/cd change: instead of relying on haiku to formulate status of the task based on lines from the agent log, introduced Log tool that the workflow uses
    * This log is visible in real-time in pipeline logs - progress can be seen
    * The use of it is unreliably, was mostly ignored. Used more with additional prompting to do so.

## Evals observations

### Run 0

#### Tool use errors
* absolute/relative paths confusion
* ls used outside the project (should've been Glob tool)

#### Recipe
False positives/false negatives:
* Did NOT upgrade wrapper.gradleVersion in build.gradle
  * Agent sees that, but brushes off as a known limitation of the gradle upgrade recipe instead of dealing with it
* Upgraded Gradle version info in README.md - correct, but wasn't needed based on the PR 
  * `Root Cause: The recipe includes explicit FindAndReplace for "Gradle 8.1" → "Gradle 8.5" which matches both locations. The original PR only updated the Prerequisites section, missing the Technology Stack section.`
  * So ultimately it is correct even though not identical to the recipe


### Run 1

#### Tool use errors
* Struggles to write to `option-2-recipe.yaml`, recovers well but has 5 tool use errors
* Uses redirects (`>`)
* absolute/relative paths confusion
* ls used outside the project (should've been Glob tool)

#### Recipe
With additional nudges, it does have a go at the code changes. It cannot complete difficult parts, but does remove files and document what else need to be done.
This is an example where code recipe is likely needed for the full coverage.
* `ApiKeyAuthenticator.java` and `ApiKeyAuthenticatorTest.java` and other classes - migration from String to BasicCredentials - skipped entirely
* Github Actions - overapplication with java version 11 to 17 bump - ultimately correct, but is not present in the PR

### Run 2

#### Tool use errors
* ls used outside the project (should've been Glob tool) - not sure why it keeps doing that
* `gh pr` command - wrong arguments - recovered easily

#### Recipe
This one is interesting - after trying a refined 3rd option it recommends option 2
* Missed a lot of expected Gradle upgrades - didn't add dependencies, didn't upgrade parameters for a plugin
* Would've probably get there with more iterations but with option 3 failing it didn't have a chance to improve much


### Run 3

#### Tool use errors
* ls used outside the project (should've been Glob tool) - not sure why it keeps doing that
* Uses redirects (`>`)

#### Recipe
* The only missing change is the removal of `@Override` in 2 places - probably a bad change anyway


### Run 4

#### Tool use errors
nothing new

#### Recipe
perfect recipe!
