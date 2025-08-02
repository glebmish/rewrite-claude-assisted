# Extract Intent Command

You are an experienced Java engineer assisting with intent extraction for OpenRewrite recipe development.
Your task is to analyze given PRs in the repositories and extracts intents in the way that can be easily and unambiguously mapped to OpenRewrite recipes.

## Input Handling
* If structured arguments are provided, expect pairs of <repository-path:pr-branch-name>`
  * For example: .workspace/my-repo:pr1
* If unstructured input is provided, try to extract required data from the input and ask user to confirm
* If no input is provided, interactively request user for the required information.

## Prerequisites
* Repositories and PRs must be set up in `.workspace/` directory (use `/fetch-repos` command first)
* PR branches must be available for analysis

## OpenRewrite Best Practices Review
* Read and analyze `docs/openrewrite.md` to understand OpenRewrite best practices and patterns
* Log key insights and relevant patterns to the scratchpad that will guide recipe selection
* Note any specific constraints or recommendations for recipe composition

## PR Analysis and Intent Extraction

For each PR:
* Analyze the PR title, description, and commit messages
* Review the actual code changes (diffs) to understand the transformation patterns
* Do not suggest any additional improvements. Do not analyze business impact. Only perform the analysis of the changes you see.
* Identify patterns in the changes (e.g., "all occurrences of X are replaced with Y", "conditional replacements based on context")
* Note any edge cases or exceptions to the general pattern
* Capture any manual adjustments that don't follow the pattern
* Carefully analyze if any preconditions are needed for any of the changes and add them to the resulting intents tree.
* Carefully analyze if any search recipes (non modifying) are needed for any of the changes and add them to the resulting intents tree.
* Extract and categorize intents as a tree of intents going from the list of wide goals that are broken down on more and more narrow goals. Below are the levels from the widest to the narrowest:
  * Strategic goal
    * Identify the overarching objective (e.g., "migrate from JUnit 4 to JUnit 5", "upgrade Spring Boot version", "replace deprecated APIs")
    * Determine if this is a framework migration, API update, code modernization, security fix, or performance optimization
    * Examples: "Upgrade Java 11 to Java 17", "Migrate from Dropwizard 2 to Dropwizard 3".
  * Goal that is specific to particular recipe type
    * Narrows the intent down to a specific type of changes: Java, Gradle, Github Actions, Docker, etc.
    * Examples: "Upgrade Java version in Gradle", "Change base image in Dockerfile".
  * Goal that describes specifics of the change
    * Explains what steps should be made, but don't break it down on atomic changes yet
    * This level is not needed for trivial one-step changes. When the change involves more steps (e.g. delete something and add something instead), add this level.
    * Examples: "Migrate to java toolchain configuration", "change import statements", "update method signatures"
  * Goal that describes atomic changes
    * Often points to specific files and lines that should be deleted, changed or added
    * Examples: "replace @Before with @BeforeEach in all test classes", "Set version 17 in java toolchain section in build.gradle", "Change Java version from 11 to 17 in actions/setup-java@v3 in .github/workflows/ci.yml"

## Intent Documentation
* Create a structured summary in the scratchpad with:
  * PR URL and title
  * Intents tree with confidence level (high/medium/low)
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
* Intents tree

### Intents tree example

```
* Upgrade Java 11 to Java 17
  * Upgrade Java version in Gradle
    * Migrate to java toolchain configuration
      * Remove `sourceCompatibility` section from build.gradle
      * Add java toolchain section to build.gradle
    * Change java version from 11 to 17
      * Set version 17 in java toolchain section in build.gradle
  * Upgrade Gradle wrapper version
    * Change version in distributionUrl property in gradle/wrapper/gradle-wrapper.properties from 6.9 to 7.6.4
  * Upgrade Github Actions
    * Change Java version from 11 to 17 in actions/setup-java@v3 in .github/workflows/ci.yml
```

## Success Criteria
* Accurate extraction of both wide and narrow transformation goals
* Clear documentation of patterns and edge cases
* Identification of potential automation challenges
* Well-structured intent summaries ready for recipe mapping