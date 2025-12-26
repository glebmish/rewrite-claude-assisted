# Gemini Evaluation Analysis: 2025-12-06-opus-with-mcp

This report provides a comprehensive analysis of the evaluation run performed on 2025-12-06 using the Opus model with the MCP framework.

## Overall Summary

The evaluation suite consisted of 5 test runs, all of which completed successfully. The agent demonstrated a strong ability to handle complex code modernization tasks, including framework migrations, Java version upgrades, and database migrations.

A key strength observed across all runs was the agent's iterative refinement process. By generating and evaluating multiple recipe options, the agent was able to progressively improve the quality of its changes, often arriving at a solution with high precision and recall.

The agent also exhibited a commendable conservative approach. In cases where it determined that a task was too complex to automate safely, it would perform the parts it was confident about and clearly document the remaining manual steps. This prioritization of safety and precision over blind automation is a sign of a mature and reliable system.

| Metric | Value |
|---|---|
| Total PRs | 5 |
| Total Runs | 5 |
| Workflow Success | 5 ✅ |
| Workflow Failed | 0  |
| Workflow Success Rate | 100.00% |
| Perfect Matches | 2 ✅ |
| Perfect Match Rate | 40.00% |

## Overall Comparison with Previous Run (2025-11-29-sonnet-with-mcp)

This section compares the evaluation run from 2025-12-06 (Opus) with the run from 2025-11-29 (Sonnet).

| Metric | 2025-12-06 (Opus) | 2025-11-29 (Sonnet) | Change |
|---|---|---|---|
| Perfect Matches | 2 | 1 | +1 |
| Total Cost | $49.86 | $27.09 | +$22.77 |
| Total Duration | 75.8 min | 83.7 min | -7.9 min |
| Avg. F1 Score | 0.71 | 0.85 | -0.14 |
| Avg. Precision | 0.92 | 0.90 | +0.02 |
| Avg. Recall | 0.67 | 0.83 | -0.16 |

**Analysis:** The Opus run had one more perfect match than the Sonnet run, but a lower average F1 score and recall. The Opus run was also significantly more expensive, but faster. The higher cost is likely due to the larger model size.

The comparison between the Opus and Sonnet models reveals a mixed bag of results. The Opus model performed better on the `ecommerce-catalog` and `task-management-api` tasks, achieving perfect scores where the Sonnet model did not. However, it performed significantly worse on the `weather-monitoring-service` and `simple-blog-platform` tasks.

The most surprising result is the large regression on the `weather-monitoring-service` task. It seems the Sonnet model was better able to handle the complex, dual-purpose nature of this task. However, as noted in the detailed analysis, Sonnet's aggressive approach left the code in a broken state. This highlights a key difference between the two models:

*   **Sonnet:** More aggressive, willing to attempt more complex refactorings even if it results in a broken state. This can be desirable if the goal is to automate as much as possible, even if it requires manual cleanup.
*   **Opus:** More conservative, prioritizing working code over completeness. This is desirable if the goal is to make safe, incremental changes.

The Opus model was more expensive but faster than the Sonnet model.

Overall, while the Opus model shows promise, it is not yet a clear winner over the Sonnet model. The choice of model may depend on the specific task and the desired trade-off between automation and safety.

## Test Runs

### 0-run1-run-metadata (`ecommerce-catalog`)

| Metric | 2025-12-06 (Opus) | 2025-11-29 (Sonnet) | Change |
|---|---|---|---|
| F1 Score | 1.0 | 0.8085 | **+0.1915** |
| Precision | 1.0 | 0.7308 | **+0.2692** |
| Recall | 1.0 | 0.9048 | **+0.0952** |

*   **Result and Analysis:**
    *   **Task:** Java 11 to 17 upgrade.
    *   **F1 Score:** 1.0
    *   **Precision:** 1.0
    *   **Recall:** 1.0
    *   **Analysis:** This was a perfect run. The agent was able to handle the Java version upgrade with 100% precision and recall. A significant improvement. The Opus run achieved a perfect score, while the Sonnet run had some false positives.
*   **Recipe Comparison:**
    *   **Opus:** Used a mix of semantic and text-based recipes. For the Gradle toolchain migration, it used a `FindAndReplace` recipe. It had separate `FindAndReplace` recipes for each change in the `README.md` file.
    *   **Sonnet:** Also used a mix of semantic and text-based recipes. It used the semantic `org.openrewrite.gradle.UpdateGradleWrapper` recipe to update the Gradle wrapper, which is a more robust approach than the `FindAndReplace` recipe used by Opus. It also used a more efficient `FindAndReplace` recipe for the `README.md` file.
    *   **Conclusion:** The Sonnet recipe was slightly more sophisticated, but the Opus recipe was more explicit and still achieved a perfect score.

### 1-run1-run-metadata (`weather-monitoring-service`)

| Metric | 2025-12-06 (Opus) | 2025-11-29 (Sonnet) | Change |
|---|---|---|---|
| F1 Score | 0.07 | 0.8198 | **-0.7498** |
| Precision | 1.0 | 0.9857 | +0.0143 |
| Recall | 0.03 | 0.7017 | **-0.6717** |

*   **Result and Analysis:**
    *   **Task:** Upgrade Java from 11 to 17, upgrade Gradle, and refactor the authentication mechanism from a custom chained filter to a standard Dropwizard implementation.
    *   **F1 Score:** 0.07
    *   **Precision:** 1.00
    *   **Recall:** 0.03
    *   **Analysis:** This run is a prime example of the agent's conservative approach and iterative refinement process. The agent correctly identified that the authentication refactoring was a large, manual task that could not be automated with declarative recipes. It therefore focused on the automatable changes: upgrading Java, Gradle, and the Docker images. The agent generated three options, progressively refining the recipe to achieve 100% precision on the automatable parts of the task. The very low recall score is due to the evaluation framework comparing the agent's output to the entire PR, including the manual changes. This is a flaw in the evaluation, not the agent. A large regression in F1 score. The Sonnet run was more ambitious and attempted to automate the authentication refactoring, but left the code in a broken state (files were deleted, but the corresponding calls were not properly replaced). The Opus run, on the other hand, was more conservative and only performed the dependency upgrades, leaving the code in a working state but with a much lower recall. This highlights a trade-off between the two models: Sonnet's aggressiveness can lead to more complete but potentially broken solutions, while Opus's conservatism leads to safer but less complete solutions.
*   **Recipe Comparison:**
    *   **Opus:** Very conservative. It made only the safest changes and avoided anything that might break the build.
    *   **Sonnet:** More aggressive. It attempted to automate as much of the PR as possible, including deleting the old authentication files, which left the code in a broken state.
    *   **Conclusion:** This comparison perfectly illustrates the trade-off between the two models. Opus prioritized a working state, while Sonnet prioritized completeness.

### 2-run1-run-metadata (`user-management-service`)

| Metric | 2025-12-06 (Opus) | 2025-11-29 (Sonnet) | Change |
|---|---|---|---|
| F1 Score | 0.71 | 0.6786 | +0.0314 |
| Precision | 0.80 | 0.7600 | +0.0400 |
| Recall | 0.65 | 0.6129 | +0.0371 |

*   **Result and Analysis:**
    *   **Task:** Upgrade Java from 11 to 17, upgrade Gradle and a Gradle plugin, and migrate from JUnit 4 to JUnit 5.
    *   **F1 Score:** 0.71
    *   **Precision:** 0.80
    *   **Recall:** 0.65
    *   **Analysis:** The agent again demonstrated its iterative refinement process, generating three options and selecting the one with the best F1 score. The agent successfully handled the complex JUnit 4 to 5 migration, but it struggled with some of the `build.gradle` changes. The agent itself identified these as "Known Gaps" in the available OpenRewrite recipes. This run highlights the agent's dependence on the underlying tools. A slight improvement across all metrics. Both models struggled with the complexity of this task, but the Opus model performed slightly better.
*   **Recipe Comparison:**
    *   **Opus:** Very detailed and explicit. It used a large number of single-purpose recipes to control every aspect of the transformation.
    *   **Sonnet:** More high-level and less verbose. It used broader, multi-purpose recipes.
    *   **Conclusion:** The Opus recipe was more surgical and precise, which likely led to its slightly higher F1 score.

### 3-run1-run-metadata (`task-management-api`)

| Metric | 2025-12-06 (Opus) | 2025-11-29 (Sonnet) | Change |
|---|---|---|---|
| F1 Score | 1.0 | 0.9524 | +0.0476 |
| Precision | 1.0 | 1.0 | 0.0 |
| Recall | 1.0 | 0.9091 | **+0.0909** |

*   **Result and Analysis:**
    *   **Task:** Java 11 to 17 upgrade.
    *   **F1 Score:** 1.0
    *   **Precision:** 1.0
    *   **Recall:** 1.0
    *   **Analysis:** This was another perfect run, demonstrating the agent's ability to handle Java version upgrades flawlessly. An improvement. The Opus run achieved a perfect score, while the Sonnet run deliberately chose not to automate the removal of two `@Override` annotations.
*   **Recipe Comparison:**
    *   **Opus:** Very sophisticated. It defined a custom sub-recipe with a precondition to safely remove unnecessary `@Override` annotations. This is a very clever way to avoid the over-application problem.
    *   **Sonnet:** Simpler and less sophisticated. It explicitly avoided automating the removal of the `@Override` annotations.
    *   **Conclusion:** The Opus recipe was clearly superior, demonstrating more advanced reasoning capabilities.

### 4-run1-run-metadata (`simple-blog-platform`)

| Metric | 2025-12-06 (Opus) | 2025-11-29 (Sonnet) | Change |
|---|---|---|---|
| F1 Score | 0.78 | 1.0 | **-0.22** |
| Precision | 0.78 | 1.0 | **-0.22** |
| Recall | 0.78 | 1.0 | **-0.22** |

*   **Result and Analysis:**
    *   **Task:** Migrate the application from an H2 database to a PostgreSQL database.
    *   **F1 Score:** 0.78
    *   **Precision:** 0.78
    *   **Recall:** 0.78
    *   **Analysis:** The agent used its iterative refinement process to generate three options and select the best one. It correctly identified and implemented most of the necessary changes for the database migration, but it made some mistakes in the `build.gradle` file related to dependency management. This resulted in 5 false positives and 5 false negatives. A significant regression. The Sonnet run achieved a perfect score, while the Opus run struggled with dependency management in the `build.gradle` file. The Opus run's lower score is due to a combination of issues with dependency management (failing to remove the JUnit 4 dependency and using the wrong quote style) and missing comment changes.
*   **Recipe Comparison:**
    *   **Opus:** Used a mix of semantic and text-based recipes, preferring semantic recipes where possible.
    *   **Sonnet:** Almost entirely text-based. It used `FindAndReplace` for all the Gradle, YAML, SQL, and Dockerfile changes.
    *   **Conclusion:** The Opus recipe was far more sophisticated and robust. The fact that the Sonnet run achieved a perfect score with its brittle recipe is surprising and likely due to the simplicity of the repository. The Opus run's lower score is also surprising and warrants further investigation. This analysis confirms that the Opus model's more sophisticated approach is not always better. In this case, the simpler, text-based approach of the Sonnet model was more effective.
