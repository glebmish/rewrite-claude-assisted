# Map Recipes Command

This command discovers OpenRewrite recipes and maps extracted intents to appropriate recipes. You're an experienced software engineer who is an expert in Java and refactoring.

## Input handling
* Expect a tree of goals going from the widest to narrowest

## Recipe Discovery Setup
* Execute `./gradlew rewriteDiscover` to generate the comprehensive list of available recipes
* Parse and index the output, organizing recipes by:
  * Category/namespace (e.g., org.openrewrite.java.spring.*)
  * Type of transformation
  * Target framework/library versions
* Log the total number of discovered recipes and major categories to the scratchpad

## Intent-to-Recipe Matching

For each extracted intent from previous phase:

### Direct Recipe Matching
* Search for recipes that directly address the wide goal
* Use keyword matching, regex patterns, and semantic similarity
* Score matches based on:
  * Exact name match
  * Description relevance
  * Category alignment
  * Version compatibility

### Composite Recipe Analysis
* For intents without direct recipe matches, identify combinations of existing recipes
* Analyze if narrow goals can be achieved by:
  * Sequencing multiple recipes
  * Configuring recipe parameters
  * Using precondition recipes

### Gap Analysis
* Document intents that cannot be addressed by existing recipes
* Categorize gaps as:
  * Requires custom recipe development
  * Needs recipe parameter tuning
  * Outside OpenRewrite scope
  * Requires manual intervention

## Repository Analysis (if needed)
When existing recipes are insufficient:
* Use repository source code
* Analyze the codebase structure to understand:
  * Build system and dependencies
  * Code patterns and conventions
  * Potential recipe application challenges
* Use static analysis to validate recipe applicability

## Recipe Recommendation Report
Create a structured mapping in the scratchpad

Write down how you've discovered each recipe that you use, arguments and other relevant knowledge. It can be your general pretraining 
knowledge or knowledge acquired from running a command (e.g. `gradle` execution), reading a web page (e.g. one of the pages from OpenRewrite docs), cloning and analyzing code.

## Validation and Testing Preparation
* For high-confidence matches, prepare recipe YAML configurations
* Document test scenarios to validate recipe effectiveness
* Note any prerequisites (dependency versions, file structures) for recipe execution

## Error Handling
* Handle missing or corrupted `rewriteDiscover` output
* Manage cases where recipe discovery times out or fails
* Provide fallback strategies when automated matching is inconclusive
* Log all matching attempts and their outcomes for debugging

## Output Format
For each intent, provide:
* Matched recipes with confidence scores
* Recommended recipe configurations
* Identified gaps requiring custom development
* Next steps for recipe validation

## Success Criteria
* Comprehensive recipe discovery and indexing
* Accurate mapping of intents to appropriate recipes
* Clear documentation of recipe sources and reasoning
* Well-prepared configurations ready for validation testing