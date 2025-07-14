# Extract Intent Command

This command analyzes PRs and extracts transformation intents for OpenRewrite recipe development. You're an experienced software engineer who is an expert in Java and refactoring.

## Input Handling
* If structured arguments are provided, expect pairs of <repository-path:pr-branch-name>`
  * For example: .workspace/my-repo:pr1
* If unstructured input is provided, try to extract required data from the input and ask user to confirm
* If no input is provided, interactively request user for the required information.

## Prerequisites
* Repositories and PRs should be set up in `.workspace/` directory (use `/fetch-repos` command first)
* PR branches should be available for analysis

## OpenRewrite Best Practices Review
* Read and analyze `docs/openrewrite.md` to understand OpenRewrite best practices and patterns
* Log key insights and relevant patterns to the scratchpad that will guide recipe selection
* Note any specific constraints or recommendations for recipe composition

## PR Analysis and Intent Extraction

For each PR:
* Analyze the PR title, description, and commit messages
* Review the actual code changes (diffs) to understand the transformation patterns
* Extract and categorize intents as a tree of intents going from the list of wide goals that are broken down on more and more narrow goals:
  
  ### Wide Goals (Strategic Intent)
  * Identify the overarching objective (e.g., "migrate from JUnit 4 to JUnit 5", "upgrade Spring Boot version", "replace deprecated APIs")
  * Determine if this is a framework migration, API update, code modernization, security fix, or performance optimization
  * Log the business/technical motivation if apparent from PR context
  
  ### Narrow Goals (Tactical Changes)
  * List specific code transformations observed (e.g., "replace @Before with @BeforeEach", "change import statements", "update method signatures")
  * Identify patterns in the changes (e.g., "all occurrences of X are replaced with Y", "conditional replacements based on context")
  * Note any edge cases or exceptions to the general pattern
  * Capture any manual adjustments that don't follow the pattern

## Intent Documentation
* Create a structured summary in the scratchpad with:
  * PR URL and title
  * Wide goal(s) with confidence level (high/medium/low)
  * List of narrow goals grouped by type
  * Any ambiguities or areas needing clarification
  * Potential challenges for automation

## Validation
* Cross-reference extracted intents with the actual code changes
* Flag any inconsistencies between stated intent (PR description) and actual changes
* Note if multiple unrelated changes are bundled in a single PR

## Output Format
For each analyzed PR, provide:
* Summary of strategic and tactical intents
* Confidence levels for each extracted intent
* Identified patterns and exceptions
* Recommendations for next steps (recipe mapping)

## Success Criteria
* Accurate extraction of both wide and narrow transformation goals
* Clear documentation of patterns and edge cases
* Identification of potential automation challenges
* Well-structured intent summaries ready for recipe mapping