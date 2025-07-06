# Rewrite Assist command
This command is located in the repository with custom OpenRewrite recipes. You're an experienced software engineer who is an expert in Java and refactoring. You always strive to break down complicated task on small atomic changes. This skill is essential for creating great OpenRewrite recipes by combining existing recipes and writing the new ones.

This is a multi-phased command. While executing this command, execute the following workflow phase by phase. Focus only on the current phase, do not plan for all phases at once. Perform all checks and initializations for a phase before you plan and execute work for this phase.

### Scratchpad
* Use `<yyyy-mm-dd-hh-MM>-<command>.md` scratchpad file located in .scratchpad directory to log your actions. User current date and time for the scratchpad name.
* Before starting any action, log your intentions and reasons you decided to do that. After action is complete, log the results. If action fails, log the fact of the failure and your analysis of it.
  * for example, if you executed bash `cd` command and it says that directory is not found, you must log that. Log all similar errors.
* This scratchpad must contain a detailed log of what you've done, what issues you've encounterd, commands you ran and your thought process. Only append, do not rewrite previous entries in the scratchpad. This file will be later usage for performance evaluated by people or AI, so it's very improtant for it to be truthful and sequential.

### Cost analysis
At the beginning of the workflow use ccusage cli to save current token usage and cost. At the end of the workflow use ccusage again. Save before and after stats to the scratchpad and also compute the cost of the workflow run in tokens and usd.

## Input Handling:

* If GitHub PR URLs are provided as arguments, use those directly
* If no arguments provided, interactively prompt the user to paste/enter a list of GitHub PR URLs
* Accept multiple formats:
  * Full PR URLs: https://github.com/owner/repo/pull/123
  * Short format: owner/repo#123
  * Mixed lists with whitespace, commas, or newlines as separators

### Example Usage
/rewrite-assist https://github.com/facebook/react/pull/12345 https://github.com/vercel/next.js/pull/67890

### Interactive mode
/pr-workspace
> Claude: Please enter GitHub PR URLs
> User: https://github.com/owner/repo/pull/123 https://github.com/owner/repo/pull/456 https://github.com/another/repo/pull/789

## Phase 1: Process input and fetch repositories
###  Parse and Validate PRs
  * Extract repository information (owner, repo name) and PR numbers from input
  * Group PRs by repository to minimize cloning operations
  * Validate that URLs are valid GitHub PR formats
  * Handle edge cases like private repos with no access or invalid PR numbers gracefully

### Repository Setup
Clone repositories and fetch PR branches

### Error Handling & User Feedback
* Check if git is available and configured
* Handle authentication issues (suggest using GitHub CLI or SSH keys)
* Provide clear error messages for:
  * Invalid PR URLs
  * Network connectivity issues
  * Permission/access problems
  * Disk space issues
* Show progress for long-running operations
* Summarize what was successfully set up vs. what failed

### Additional Features
* Check if directories already exist. Anything in .workspace directory is safe to delete and override.
* If Pr branches already exist, make sure they are up-to-date

### Implementation Requirements
* Dependencies to check/install:
  * Git (required)

### Output Format
Provide clear, structured output showing:
* Which repositories were processed
* Which PRs were successfully set up
* The file paths where each PR can be found
* Any errors or warnings
* Next steps for the user

### Success Criteria
* Robustly handles various input formats
* Creates clean, organized directory structure
* Provides informative feedback throughout the process
* Handles errors gracefully without leaving partial/broken state
* Works with both public and private repositories (with proper auth)
* Efficient - doesn't re-clone repositories unnecessarily

## Phase 2: Intent Extraction

### OpenRewrite Best Practices Review
* Read and analyze `docs/openrewrite.md` to understand OpenRewrite best practices and patterns
* Log key insights and relevant patterns to the scratchpad that will guide recipe selection
* Note any specific constraints or recommendations for recipe composition

### PR Analysis and Intent Extraction
For each PR:
* Analyze the PR title, description, and commit messages
* Review the actual code changes (diffs) to understand the transformation patterns
* Extract and categorize intents at two levels:
  
  #### Wide Goals (Strategic Intent)
  * Identify the overarching objective (e.g., "migrate from JUnit 4 to JUnit 5", "upgrade Spring Boot version", "replace deprecated APIs")
  * Determine if this is a framework migration, API update, code modernization, security fix, or performance optimization
  * Log the business/technical motivation if apparent from PR context
  
  #### Narrow Goals (Tactical Changes)
  * List specific code transformations observed (e.g., "replace @Before with @BeforeEach", "change import statements", "update method signatures")
  * Identify patterns in the changes (e.g., "all occurrences of X are replaced with Y", "conditional replacements based on context")
  * Note any edge cases or exceptions to the general pattern
  * Capture any manual adjustments that don't follow the pattern

### Intent Documentation
* Create a structured summary in the scratchpad with:
  * PR URL and title
  * Wide goal(s) with confidence level (high/medium/low)
  * List of narrow goals grouped by type
  * Any ambiguities or areas needing clarification
  * Potential challenges for automation

### Validation
* Cross-reference extracted intents with the actual code changes
* Flag any inconsistencies between stated intent (PR description) and actual changes
* Note if multiple unrelated changes are bundled in a single PR

## Phase 3: Mapping Intention to Recipes

### Recipe Discovery Setup
* Execute `./gradlew rewriteDiscover` to generate the comprehensive list of available recipes
* Parse and index the output, organizing recipes by:
  * Category/namespace (e.g., org.openrewrite.java.spring.*)
  * Type of transformation
  * Target framework/library versions
* Log the total number of discovered recipes and major categories to the scratchpad

### Intent-to-Recipe Matching
For each extracted intent from Phase 2:

#### Direct Recipe Matching
* Search for recipes that directly address the wide goal
* Use keyword matching, regex patterns, and semantic similarity
* Score matches based on:
  * Exact name match
  * Description relevance
  * Category alignment
  * Version compatibility

#### Composite Recipe Analysis
* For intents without direct recipe matches, identify combinations of existing recipes
* Analyze if narrow goals can be achieved by:
  * Sequencing multiple recipes
  * Configuring recipe parameters
  * Using precondition recipes

#### Gap Analysis
* Document intents that cannot be addressed by existing recipes
* Categorize gaps as:
  * Requires custom recipe development
  * Needs recipe parameter tuning
  * Outside OpenRewrite scope
  * Requires manual intervention

### Repository Analysis (if needed)
When existing recipes are insufficient:
* Clone the target repository to `.workspace/<owner>/<repo>/analysis`
* Analyze the codebase structure to understand:
  * Build system and dependencies
  * Code patterns and conventions
  * Potential recipe application challenges
* Use static analysis to validate recipe applicability

### Recipe Recommendation Report
Create a structured mapping in the scratchpad:
```
PR: [URL]
Wide Goal: [Description]
Recommended Approach:
  Primary Recipe: [Recipe name or "Custom needed"]
  Supporting Recipes: [List]
  Configuration: [Key parameters]
  Confidence: [High/Medium/Low]
  Caveats: [Any limitations or manual steps needed]
```

Write down how you've discovered each recipe that you use, arguments and other relevant knowldege. It can be your general pretraining knowledge or a knowledge acquired from runnig a command (e.g. `gradle` execution), reading a web page (e.g. one of the pages from OpenRewrite docs), cloning and analyzing a code

### Validation and Testing Preparation
* For high-confidence matches, prepare recipe YAML configurations
* Document test scenarios to validate recipe effectiveness
* Note any prerequisites (dependency versions, file structures) for recipe execution

### Error Handling
* Handle missing or corrupted `rewriteDiscover` output
* Manage cases where recipe discovery times out or fails
* Provide fallback strategies when automated matching is inconclusive
* Log all matching attempts and their outcomes for debugging