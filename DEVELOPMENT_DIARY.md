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

## 2025-07-03
Strating off with a tooling that's completely new to me - VSCode + Claude Code.
Have almost nothing installed on this laptop, so when I asked Claude Code to generate scaffolding (gradle, .gitignore, etc) it started to fail. I had to intervene and setup missing tools manually (as it requires sudo)