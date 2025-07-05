# Project diary
Documenting my work on the project to see how my understanding of AI-assisted workflows grow in time

## Project goal
There's a framework called OpenRewrite. It enabled mass refactoring based on rules and code. It's a great tool to have in a large company, but learning curve is steeep!
Yes, they have a lot of existing recipes. But as soon as you want to do one step away from the existing recipes, you're cooked. Assembling a custom recipe from 100s of existing small steps is hard, writing code for new recipes in many times harder.
I want to build an AI-assisted workflow that handles most or all of the complexity of doing that. Rather then burning tokens and refactor code with AI, I want to use it to build a realiable recipe and then mass refactor with it 'for free'.\

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
Strating off with a tooling that's completely new to me - VSCode + Claude Code.
Have almost nothing installed on this laptop, so when I asked Claude Code to generate scaffolding (gradle, .gitignore, etc) it started to fail. I had to intervene and setup missing tools manually (as it requires sudo)

## 2025-07-04
To have some repos to test the workflow on, asked Claude to generate two outdated Java services, create github action configs and push them to GitHub. It did that with no issues at all
Stared to design the workflow. Went for a custom slash command `/rewrite-assist`. Used Claude to generate initial prompt that accepts list of PRs, and clones repos. I'm surprised how detailed it is.
Claude Code really struggled to clone them in the way I described: with different git worktrees for main and PR branch. That shows a room for improvement, it should probably be event more detailed. I asked Claude to dump session to a scratchpad for further analysis.
Using ccusage to track how much tokens I use to get a feel of the potential costs. For now my Claude Pro subscption was enough, but it probably won't be.
Food for thought: docs recommend to chain complex thought: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/chain-prompts . That goes against my initial idea of one large meta-prompt for the whole workflow. Will see how it will behave for the more complicated prompts

## 2025-07-05
Improved cloning, seems like now it works well. Explaining general rules where it comes to cloning and worktree helped it apply them for specific cases.
Trying to use cratchpads and so far don't like the level of details it prints. I'd expect it to be more of a debug log for everything Claude does, instead it's a short description of its actione.
Trying to track costs for a single workflow run. Natively there's no way to do that when you're on subscription. Using ccusage, but it doesn't give a good breakdown on the cost of a session. Working around that by asking Claude to get before and after usage and calculate the costs.
Claude really struggles to navigate, `cd` commands it executes often assume a wrong directory. Trying to work around that by instructing it to get back after the command (`cd -`). It doesn't always work, because sometimes it does multiple `cd` commands before trying to go back. Told it to initialize an env var for the root directory and use it when confused, but didn't see it being used yet.
For some reason it tries to use gh cli to get diff instead of using locally clonned worktrees and diffing between them. Need to adjust that part.