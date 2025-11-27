# Project diary
Documenting my work on the project to see how my understanding of AI-assisted workflows grow in time

## Project goal
There's a framework called OpenRewrite. It enabled mass refactoring based on rules and code. It's a great tool to have in a large company, but learning curve is steeep!
Yes, they have a lot of existing recipes. But as soon as you want to do one step away from the existing recipes, you're cooked. Assembling a custom recipe from 100s of existing small steps is hard, writing code for new recipes in many times harder.
I want to build an AI-assisted workflow that handles most or all of the complexity of doing that. Rather then burning tokens and refactor code with AI, I want to use it to build a realiable recipe and then mass refactor with it 'for free'.

### Workflow
Here's the step-by-step workflow I have in mind:
1. User provides one or many PR links
2. Agent analyzes PRs and extract intent from there: a list of refactoring goals that user wants to achieve with these PRs
3. Agent presents the suggested list of goals and work with the User to tune this goals.
4. Agent breaks down the goals to small steps and matches as many of them to the existing OpenRewrite recipes.
5. For the missing steps agent implements custom recipes
6. Agent thoroughly test new atomic recipes and the composite recipe including comparison of the recipe output with original PRs
7. Agent produces ready-to-use composite recipe with all the necessary documentation, examples, etc

### Early design decisions
* The whole workflow is handled by Claude Code. That should ideally include setting up the workflow (installing cli tools, runnign docker images etc) and finishing the work with a new PR for custom recipes
* Token cost is one of the main improvement metrics
* Use current project as a place where workflow is defined and custom OpenRewrite recipes are saved
* Use temporary workspace directory for additional code repositories: existing openrewrite recipes, projects where initial PRs are opened, etc

### Challenges
* Context bloat - the workflow looks to be massive and it's well known that agent performance degrades as context grows
* Token expenditure - keep a close eye on amount of tokens spent and strive to reduce it. Ideally make it all work on Sonnet instead of Opus
* Testing and quality control
* Providing OpenRewrite knowledge efficiently for recipe breakdown and code generation
* Prompt design for workflow as a whole and specific parts of it, tools, MCPs

### Promising tools and techniques
* Task delegation to separate Claude Code instances
* Embeddings, vector DB and multi-query searches for sematic search of matching recipes
* MCPs, e.g. semantic search MCP
* Claude Code commands
* Test evals, automated test generation and result evaluations

## 2025-07-03
* Strating off with a tooling that's completely new to me - VSCode + Claude Code.
* Have almost nothing installed on this laptop, so when I asked Claude Code to generate scaffolding (gradle, .gitignore, etc) it started to fail. I had to intervene and setup missing tools manually (as it requires sudo)

## 2025-07-04
* To have some repos to test the workflow on, asked Claude to generate two outdated Java services, create github action configs and push them to GitHub. It did that with no issues at all
* Stared to design the workflow. Went for a custom slash command `/rewrite-assist`. Used Claude to generate initial prompt that accepts list of PRs, and clones repos. I'm surprised how detailed it is.
* Claude Code really struggled to clone them in the way I described: with different git worktrees for main and PR branch. That shows a room for improvement, it should probably be event more detailed. I asked Claude to dump session to a scratchpad for further analysis.
* Using ccusage to track how much tokens I use to get a feel of the potential costs. For now my Claude Pro subscption was enough, but it probably won't be.
* **Food for thought**: docs recommend to chain complex thought: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/chain-prompts . That goes against my initial idea of one large meta-prompt for the whole workflow. Will see how it will behave for the more complicated prompts

## 2025-07-05
* Improved cloning, seems like now it works well. Explaining general rules where it comes to cloning and worktree helped it apply them for specific cases.
* Trying to use cratchpads and so far don't like the level of details it prints. I'd expect it to be more of a debug log for everything Claude does, instead it's a short description of its actione.
* Trying to track costs for a single workflow run. Natively there's no way to do that when you're on subscription. Using ccusage, but it doesn't give a good breakdown on the cost of a session. Working around that by asking Claude to get before and after usage and calculate the costs.
* Claude really struggles to navigate, `cd` commands it executes often assume a wrong directory. Trying to work around that by instructing it to get back after the command (`cd -`). It doesn't always work, because sometimes it does multiple `cd` commands before trying to go back. Told it to initialize an env var for the root directory and use it when confused, but didn't see it being used yet.
* For some reason it tries to use gh cli to get diff instead of using locally clonned worktrees and diffing between them. Need to adjust that part.
* When I expect Claude to use current time, e.g. to create a new scratchpad, sometimes it understand to use current date and time, sometimes it puts a random time. Solved that by specifying that it must use **curent** date and time.

### Early challenges
* It's very simple to break cloning logic. I think there are two reasons: complicated layout of worktrees and struggles with navigation (`cd`)
  * Simplifying layout and do not force using worktrees where it's not needed really helped.
  * Instructing Claude to use `pwd` often seems to reduce confusions and find correct commands quick.
* Level of details in scratchpad is far from enough. It should be super detailed for later evaluations.
    * Improved instruction for the scratchpad, now it is detailed. Still doesn't show everything, e.g. it doesn't say anything about it being confused about current working directory and fixing it with `pwd`, I could only see it in the terminal window.
* There are no articles and tools I could find on evaluating Claude Code, only on evaluating Claude API. That's especially difficult because there won't be any interactivity in evals and the whole workflow should be done autonomously from start to finish.

## 2025-07-06
* Cloning is very stable now. Logging to scratchpad is more detailed too.
* Added intent extraction and mappig to recipes. Generated prompt using Claude Opus and passing existing command and link to https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices . Result was pretty good.
* Asked Claude Opus to research OpenRewrite and compile a document. The result is high quality. I added it to `docs/` in the repo and ask Claude Code to read it before extracting the intent of the changes.
* It's now a bit too eager on the intent extraction, need to tune it to now assume that much (e.g. it now tries to match it to the business motivation of the change). During another run, it started to anlyze additional technical debt which wasn't touched in the PR.
* Mapping to recipes benefits from being able to list all recipes with `./gradlew rewriteDiscover`. This is a bare minimum though. It might benefit more from access to the source code for the recipes that match the intent. It might also benefit from a better matching with embeddings and vector DB - that can potentially reduce token usage and decrease latency.
  * Fixed build.gradle to actually discover all the recipes. There are now few thousands recipes include github actions specific ones.
* Testing on a simple case - Java 8 app where it's updated to Java 11 in Gradle and Github action. It was sucessfully matched to `org.openrewrite.gradle.UpdateJavaCompatibility` and `org.openrewrite.yaml.ChangePropertyValue` with correct arguments. No hallucinations there.
  * Arguments are very surprising because `rewriteDiscover` command doesn't show it. Is it coming from a general Claude knowledge or does it make any additional requests that are not in the scratchpad?
  * With a more complete list of recipes, it was able to find github actions specific recipe that is a better match.
* Another run on the same case failed, it couldn't match any recipes. It might be that an additional prompt I've added confused Claude and he started to search recipes in the current repo instead of looking at all available recipes. Here it is:
  * Write down how you've discovered each recipe that you use, arguments and other relevant knowldege. It can be your general pretraining knowledge or a knowledge acquired from runnig a command (e.g. `gradle` execution), reading a web page (e.g. one of the pages from OpenRewrite docs), cloning and analyzing a code
* I wasn't able to see it to the end as I've reached the usage limit, so I'm not sure if that was a dead end or not.
* Cost-wise so far it looks to be ~40 cents per run
* It's clear that evaluations should start early and be perfromed often. I'm almost at the point where I can start it. What I need it:
  * Focus on compiling existing recipes now, no new code
  * Teach Claude how to run the recipe it came up with on the main branch of the repo and compare with the PR. That is going to be the main success criteria.
  * Create a testest with >=20 different repos with PRs of a different difficulty levels.
* That will help me run manual evals. At some point I'll have to find a way to automate all of it.
* Asked Claude to create a very detailed spec for 5 slightly outdated apps and then asked Claude Code to create thouse apps. I'm now hitting usage limits, so I need to use scratchapd as a checkpoint and continue later.
* Generated recipe validation phase for rewrite-assist command. Tried it as it was generated and it's completely useful, couldn't run any validations. Heavy tuning needed.

## 2025-07-09
* Last few days spent generatind data for test evals. Mostly Claude churning through 10 services. Had to do a lot of cleanup and fixing after it, not great.
  * https://github.com/orgs/openrewrite-assist-testing-dataset/repositories
  * Need to generate some PRs on top of that
* Discovered that Claude Code saves all conversations a json files. Great for evals!

### Eval ideas
* Start with a lite eval - 5 to 10 PRs with a small targeted change, no new recipes implementations yet
* Another instance of Claude analyzes each log and scores it.
* Main goal - `claude -p` achieves the same change as in PR by generating a yaml recipe and running it
  * That's called Correctness%
* Additional goals
  * Smoothness - how many tool use or thought errors happenned
  * Latency - how long it took
  * Cost efficiency - tokens spent
  * Repeatability - same PR = same result

## 2025-07-14
Starting to apply more elaborate approaches
* Discovered full Claude Code logs and decided to use them for evaluation. They're not in the workspace though, so had to do some work:
  * I want Claude Code to save Session ID in scratchpad, but itdoesn't know about its own session id, so I added a script to fetch it.
Assuming latest log for the give workspace is the correct one.
  * Log is located outside of the working directory and I don't want to just give access to all logs. Instead I added a script
to fetch a log based on session id. This script also calculates costs, so I no longer use ccusage for that.
* Moved cost analysis to a separate command. This new command fetches logs and uses scratchpad, logs and costs to analyze the run.
* Split one large slash command to multiple files. In the aggregate command I provide a series of commands to execute and explain
that to run a slash command it should find the prompt in the .claude directory. That seems to work well. Helps with maintainability and
Claude focus (one of the best practices)
* The whole workflow is very raw now and the next big goal is to instrument verification. It doesn't work at all now.

## 2025-08-03
* Moving from commands to subagents seem to improve the quality of execution. Great feature. It also takes care of:
  * focus on a current task - I tried to solve it with prompting and splitting command on multiple files
  * maintainability - similar to splitting command on different files
  * Using parallel execution where needed
  * Using think tool where needed - before it seems like once it's enabled it kept being enabled for further steps
* What subagents lack are the statefulness - the ability to pass comands to the same instance that have done a task before.
  * Would probably improve iterations - e.g. create recipe (agent 1), validate (agent 2), update based on feedback (agent 1), revalidate (agent 2)
  * I also sometimes ask Claude why it decided to do some weird thing and how I could improve the prompt to avoid it. 
Seems like with subagents the context of what subagent was doing is missing in the main conversation (that makes sense) and I cannot ask why it did that.
* Along with moving to subagents, also improving prompts:
  * better instructions for how recipes should be assembled. Specifically, prompting to challenge gaps and trying to find 
lower level recipes that can be used for these sections helped. BUT, now I see model trying to hack the recipe by ultra-focused 
text changes instead of semantically correct changes (e.g. `replace text A with text B` instead of `Update Java version in Gradle`)
* Cannot figure out how subagent history work. Seems like sometimes it's a separate session and sometimes it's saved to the
same session with `isSidechain=true`
* Fixed Gradle initscript for openrewrite and prompts for recipe validation. It is unreliable, but now it works _sometimes_
* Next primary goal - Github actions to run non interactive recipe creation based on a PR and collect artifacts. This is a major building block for evals.
* I'm absolutely sure now that embeddings to discovery recipes and some kind of document storage for full recipe documentation files will
significantly improve correctness and cost efficiency of the workflow. Some great tools for that:
  * Discovery mechanisms in OpenRewrite plugin. Existing tasks but most importantly the ability to write my own tasks 
that will print out necessary information for all recipes in the classpath.
  * Docs: https://github.com/openrewrite/rewrite-docs and docs generator: https://github.com/openrewrite/rewrite-recipe-markdown-generator
  * Important that these things allow me to extend data with custom recipes since they'll also be a part of the classpath during gradle execution
* Doing all of the development on Pro subscription means that I have to step away from the keyboard once limit is up :\
* Couple of things that would be useful as CC features:
  * ability to pass config that should be applied (to replace allowedTools flag that is less convenient)
  * visualizing subagent work as a tab that you can switch to

## 2025-09-29
* Had a long pause in project work and when I started again it hit me with failures. 
  * Looks like github actions don't checkout code automatically and the workflow there didn't base it on my prompts at all
  * Spend a lot of time looking for a rootcause
* Was able to run workflow in github by itself and more importantly generate a matrix and run a whole suite for evals
  * Just a single PR in the eval suite for now to figure out the evaluation criteria
  * Workflow works well
  * Artifacts are collected
  * Analysis of all work doesn't really work
* Many times fallen into the trap. When I don't really know how to implement something non-trivial and let Claude do something,
the result is not something useful to start with, but instead and overcomplicated mess that is a chore to get to a useful state.
That's what going on with suite analysis now. Fixing it.
* Coming up with a robust analysis of a single run. Should probably result in multiple files and should run as a part of
main evaluation action, not suite analysis. Suite analysis will only combine results, probably with a script, not a claude code command.

## 2025-01-11
* Spent unbelievable amount of time trying to make evals work. Main challenges:
  * Working around Pro subscription limits. Solutions:
    * Batching of runs + wait in between. Helped to eventually run all tests
    * Testing with haiku models first. Reduced costs and wait time significantly
    * Removing subjective evaluation. This one couldn't be downgraded to haiku to keep consistent "intelligence" baseline
between tests, so removing it was the only way for now.
    * Also, started to use Gemini for development a lot since all Claude limits went to running evals. It's worse,
but has huge allowance even on free account.
  * Bugs in Claude-generated scripts. Tbf it's mostly the lack of validation from me.
    * cost analysis script didn't have info on haiku 3.5 (which is surprisingly the model used in subagents with `model: haiku`)
    * cost analysis script matched on full model name, but turns out intermediate releases happen and do change suffix of the model name in logs.
Added prefix match.
    * seems like at some point output redirects (`echo 'a' > file`) were disallowed entirely and few of my commands broke.
Rewrote commands to pass output files into a command instead of redirection. Don't like it though, it goes against unix practices.
    * simplified precision calculations weren't correct.
      * Before: looked at PR diff and diff between recipe and PR. Calculated metrics based on added and removed lines. 
Didn't work because it was missing context of the main branch.
      * After: looking at PR diff and recipe diff (from main). Comparing changes. Has all context about main branch. Easier to set up. 
  * Complicated or unreliable workflows
    * Git worktrees seem to be hard to grasp. Or maybe actions that have to be done in both worktrees and main repo directory.
Removed it entirely since fixing one of the bugs made it unnecessary.
    * Output files were unreliable. Sometimes named differently, sometimes different content, etc. Added more precision to the prompts
to improve this. Still not 100%, but much better. Required files are mostly there, some non-essential or unnecessary files are less stable.
  * Test cases prep
    * Test cases were prepared before using Claude Code generation. On a closer look, most of the generated upgrade PRs were trash and had
to be completely rewritten.
  * General complexity of the eval setup: batches and aggregation as separate Github actions, removing duplicate runs and retries for aggregation, etc.
* MAJOR MILESTONE: first [full eval](eval-checkpoints/2025-11-01-haiku-only) has been executed. Some learnings:
  * Haiku 4.5 is significantly cheaper than Sonnet 4.5. Even more saw in subscription. Resulting dollar price difference seems not as significant as subscription consumption difference.
  * Some complicated steps need simplifications - worktrees, diff capture
  * Surprised to see a new SlashCommand tool. Always fails for some reason though with no details. Would be very useful.
  * `model: haiku` in subagents SOMEHOW uses Haiku 3.5, not Haiku 4.5. Annoying, because more precise `haiku-4-5` doesn't seem to work either.
  * Works awful on non-trivial PRs (>10 changed lines)

## 2025-11-18

* Few ideas to improve Claude Code, mostly for non-interactive mode. Maybe some were mentioned before
  * An easy way to continue remote session locally, like `--teleport` for CC on the Web, but for any session
  * Append tool to work around issues with Edit tool I constantly observe
  * Log tool that prints data to stderr while non-interactive Claude Code session is in progress
  * An ability for the model to stop the session and exit with a specific exit code
  * A specific documented exit code for cases when session ends due to session limit
  * Interactive mode: visualization for subagents - tabs or something like that
* Improved the workflow enough to successfully do eval with Sonnet model. Initially I planned to just switch the model and
do eval right away, but there turned out to be so many issues that I had to fix.
  * Turns out Haiku didn't event perform validation and all results were purely hypothetical including diff files that were
then analyzed for precision
  * Debugging and fixing validation was the most time-consuming part. Still buggy - more later in Sonnet eval comments.
  * Validation now is much more robust with a defined set of resulting artifacts and procedures to ensure clean environment, etc
  * Another thing to fix once validation was working is to remove over-eagerness of the main agent that
tried to improve things on top of what OpenRewrite recipe does. More safeguards here to specify not to add anything more
than validation artifacts, have the final recommendation strictly be a copy of one of the validations, etc
  * Added changes to follow Claude Code updates - support for separate subagent log files.
  * Rewrote precision analysis to python and made it a more elaborate algorithm. Still incorrect...
  * Attempted to fix tool use errors by restricting redirections in bash (`>`, `>>`), it still uses them a lot
  * Other error - editing file with non-unique pattern - directions in CLAUDE.md didn't help either
  * Successfully made scratchpad more detailed. But now it sometimes too verbose and in other cases still not truthful enough.
* I had to drastically reduce eval size from 10 to 5 PRs due to subscription constraints - helped me do evals in a reasonable amount of time
* New Sonnet eval is not good enough, unfortunately. I was going to do eval with MCP right after this, but more work is needed. Major issues:
  * redirects in Bash and Edit tool failures are likely to be a fault of overflowing context trying to have everything in one file.
I'll try to structure outputs better, split on more files and make overall context consumption smaller
  * validation hits issues with rewrite.gradle script every time - for some reason BOM is not enough to specify
dependency versions and Claude has to fix it by adding versions manually. On the bright side, it's smart enough to
successfully do that.
  * precision script is still incorrect - combination of weird rewrite.patch artifact produced by OpenRewrite dry run and 
incorrect logic of counting total changes, true positives, false positives and false negatives.

## 2025-11-23
* Huge success with a new eval - fixes made the workflow much more efficient and robust (>35% efficiency increase)
  * Run 2 is an outlier that had many issues, will rerun it again to check if it's random, but also will work on a fix (probably encoding)
  * Retry showed that it is still problematic, will be fixed and tested in the next eval.
* Fixes made:
  * Got rid of scratchpad and single-file detailed log.
    * Significantly reduced write and edit issues and made results much more readable
  * Moved most of the validation to a script
    * More robust, allows for better control on run isolation and diff collection. As an added bonus, troubleshooting by the agent in case of error is easier
  * Fixed an issue with encoding that corrupted git diffs in openrewrite runs
    * As a side effect - logs are now polluted with encoding warns and it might've cause `yq` failure in run 2. Will investigate
* An error that wasn't fixed: Claude Code subagents don't change working directory on `cd` even when `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=0` is set. Looks like a bug
* This run showed some minor issues that I'll fix before MCP eval and some potential improvements for the future:
  * minor: improve java version detection, allow a few more commands, simplify `yc` command, fix lingering encoding issue
  * future:
    * provide precision analysis for the agent to make better decisions on the final recipe
    * provide data on which recipe belongs to which mvn dependency (and version) for dynamic list of dependencies in rewrite.gradle 
* Now fiiinaly starting tests with MCP. It was already implemented in parallel with bug fixes and now I'm merging it
  * The image is now incredibly fat because of embeddings library. Grew from 1.26GB to 8.75GB.
  * Moving to external embedding model would help. I'd probably have to pay for it.
  * MCP uses Postgres with embeddings for semantic search and documents for openrewrite recipes for detailed documentation.
Both are initialized from `rewrite-recipe-markdown-generator` repository that generates docs on OpenRewrite site.
  * Generator is used to get access to the structured data via gradle plugin and also so that it can later be extended with custom
dependencies for both docs and embeddings.
  * A data ingestion pipeline takes care of cloning repo, running postgres, generating and inserting data and creating a new image with data inside of it.
    * Database weighs 510MB (+70MB over pgvector/pgvector) 
  * MCP server connects to this database. Locally it also manages database lifecycle (start and stop). In tests, it's started separately by Github Actions

## 2025-11-27
* Ran and analyzed a new eval with MCP usage
  * Overall quality of the result decreased - probably due to rigid and limited use of MCP tools
  * Stability is great - no serious failures, few repeating issues that should be easy to fix with prompting.
  * Price is the same, but faster due to fetching data locally instead of using web search.
* Ideas where to go next to improve recipe quality:
  * Instruct intent mapping phase to write the intent tree to yaml and nudge recipe mapping phase to check every intent. That should help with minor changes that are missing.
  * Nudge to try and replicate every change in the PR, not only make it semantically the same. Also nudge to replicate complicated code changes (failing case now)
  * Extend mcp to accept multiple strings for semantic match and return the best matches overall
  * Include precision data to the workflow. Run precision calculation script as a part of validation and have Claude analyze it for actual coverage data.
  * Include a new refinement phase after 2 recipes to create the 3 combined recipe that learns from validation and coverage data of the first two attempts.
