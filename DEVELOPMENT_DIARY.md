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

