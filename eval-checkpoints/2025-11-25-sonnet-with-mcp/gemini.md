# Comprehensive Evaluation Report: `sonnet-with-mcp` vs. `sonnet-only`

## Executive Summary

This report analyzes and compares two evaluation runs: `2025-11-25-sonnet-with-mcp` (Sonnet model with Model Context Protocol) and `2025-11-23-sonnet-only` (Sonnet model without MCP). Both evaluations assessed the model's performance on the same 5 Pull Request (PR) tasks.

While both runs had a 100% workflow success rate and 0% "perfect match" rate, there were significant differences in performance, cost, and agent strategy. The `sonnet-with-mcp` run was faster on average (11.7 vs 14.5 minutes/run) but had a negligibly higher cost.

Performance, as measured by F1-score, was a mixed bag. The `sonnet-with-mcp` agent achieved a near-perfect score on one task (`task-management-api`, F1 0.95) where its use of high-level, structured recipes was highly effective. However, the `sonnet-only` agent performed significantly better on other tasks (`ecommerce-catalog`, F1 0.47 vs 0.17) by generating more comprehensive, surgical recipes that included direct text replacements for files like `Dockerfile` and `README.md`.

This suggests a key trade-off: **the `sonnet-with-mcp` agent is more adept at using high-level, pre-defined tools but may fail on tasks requiring changes outside the scope of those tools. The `sonnet-only` agent appears to be more flexible, falling back to lower-level file manipulations, which can be more effective for heterogeneous tasks but may be less robust.**

---

## Comparative Analysis: 'Sonnet with MCP' vs. 'Sonnet Only'

### Overall Suite Results Comparison

| Metric                  | `sonnet-with-mcp` (2025-11-25) | `sonnet-only` (2025-11-23) | Delta (MCP - Only) |
|-------------------------|--------------------------------|------------------------------|----------------------|
| Workflow Success Rate   | 100.00%                        | 100.00%                      | 0.00%                |
| Perfect Match Rate      | 0%                             | 0%                           | 0.00%                |
| Total Duration          | 58.5 minutes                   | 72.7 minutes                 | -14.2 minutes        |
| **Avg Duration/Run**    | **11.7 minutes**               | **14.5 minutes**             | **-2.8 minutes**     |
| Total Cost              | $20.64                         | $20.58                       | +$0.06               |
| Avg Cost/Run            | $4.12                          | $4.11                        | +$0.01               |

### Detailed F1-Score Comparison by Run

| Repo                       | PR | `sonnet-with-mcp` F1 Score | `sonnet-only` F1 Score | Winner          |
|----------------------------|----|----------------------------|------------------------|-----------------|
| `ecommerce-catalog`        | #2 | 0.17                       | **0.47**               | `sonnet-only`   |
| `weather-monitoring-service` | #3 | 0.03                       | **0.06**               | `sonnet-only`   |
| `user-management-service`  | #3 | **0.71**                   | 0.68                   | `sonnet-with-mcp` |
| `task-management-api`      | #3 | **0.95**                   | 0.80                   | `sonnet-with-mcp` |
| `simple-blog-platform`     | #3 | 0.70                       | **0.76**               | `sonnet-only`   |

---

## Detailed Comparison of Each Test Run

This section provides a detailed, run-by-run comparison of the agent's strategy and performance.

### 1. `ecommerce-catalog/2` (Java 17 -> 21 Upgrade)

*   **`sonnet-with-mcp` (F1: 0.17):** Relied on high-level recipes (`UpgradeToJava21`, `UpdateGradleWrapper`). It explicitly noted that changes to the `Dockerfile` and `README.md` were outside its capabilities and required manual updates. This led to a very low recall and a poor F1 score.
*   **`sonnet-only` (F1: 0.47):** Generated a more comprehensive recipe that included **surgical text replacements** for the `Dockerfile` and `README.md`. This flexibility allowed it to address the full scope of the task more effectively, resulting in higher recall and a significantly better F1 score.
*   **Conclusion:** The `sonnet-only` agent's flexibility won. It succeeded by falling back to basic file editing where high-level tools were insufficient.

### 2. `weather-monitoring-service/3` (Java 11 -> 17 & Auth Refactor)

*   **`sonnet-with-mcp` (F1: 0.03):** Correctly identified that the "Authentication refactoring" was complex application logic unsuited for its recipes. It focused on the infrastructure updates but its recipe was not very precise.
*   **`sonnet-only` (F1: 0.06):** Also correctly identified the authentication refactor as manual work. Its recipe for the infrastructure portion was slightly more accurate than the MCP agent's.
*   **Conclusion:** Both agents failed on the core task, which was the complex refactoring. The very low F1 scores for both reflect this. The minor difference is negligible; this task was largely beyond the scope of either agent's automated capabilities.

### 3. `user-management-service/3` (Multi-faceted Upgrade)

*   **`sonnet-with-mcp` (F1: 0.71):** Handled a complex (Java, JUnit, Gradle) upgrade by composing recipes. It created two options and chose the "Surgical Precision" approach specifically to get a "cleaner output" and "minimal over-application". This shows sophisticated reasoning about code quality.
*   **`sonnet-only` (F1: 0.68):** Also chose a surgical approach, but more out of necessity, as its "Broad" option caused "critical build.gradle failures". Its final recipe had more known gaps than the MCP agent's.
*   **Conclusion:** The `sonnet-with-mcp` agent's win, though slight, is significant. Its more robust recipe composition and ability to reason about the quality of the output gave it an edge in this purely code-based, structured migration.

### 4. `task-management-api/3` (Dropwizard 2 -> 3 Upgrade)

*   **`sonnet-with-mcp` (F1: 0.95):** This was the star performance for the MCP agent. The task was a complex but highly structured framework migration. The agent composed a comprehensive recipe that it validated at 90% coverage and deemed "production-ready". The near-perfect F1 score confirms its assessment and strategy were correct.
*   **`sonnet-only` (F1: 0.80):** Also correctly identified how to build the recipe from smaller pieces. However, while it claimed 100% coverage, it also noted its precision was only 75% due to adding extra, safe but unnecessary `@Override` removals.
*   **Conclusion:** This run perfectly illustrates the strength of the `sonnet-with-mcp` agent. For complex but structured migrations, its superior recipe composition and validation lead to a much more precise result with fewer extraneous changes.

### 5. `simple-blog-platform/3` (H2 -> PostgreSQL Migration)

*   **`sonnet-with-mcp` (F1: 0.70):** The agent created a "Surgical" recipe that it claimed had 100% coverage with "minor cosmetic differences". The resulting 0.70 F1 score shows this self-assessment was inaccurate and it missed significant changes.
*   **`sonnet-only` (F1: 0.76):** This agent's performance was more impressive despite a lower claimed coverage (71%). It provided a much deeper analysis, identifying a "Critical Issue" in its own recipe—a precondition that blocked it from adding the required PostgreSQL dependencies. It even correctly suggested the fix.
*   **Conclusion:** The `sonnet-only` agent wins here due to superior analysis. While its generated recipe was incomplete, its understanding of *why* it was incomplete was more accurate and insightful than the MCP agent's overly optimistic and incorrect self-assessment.

## Final Observations and Conclusions

1.  **A Tale of Two Strategies:** The comparison reveals a fundamental difference in how the agent operates with and without MCP. `sonnet-with-mcp` acts as a **tool-using specialist**, excelling when a high-level tool fits the job (`task-management-api`) but failing otherwise. `sonnet-only` acts as a **flexible generalist**, capable of falling back to more basic, surgical file edits when high-level tools are insufficient (`ecommerce-catalog`).

2.  **Performance is Task-Dependent:** Neither agent is universally better. The best performer depends on the nature of the task. For pure, structured code changes, `sonnet-with-mcp`'s approach is faster and more precise. For mixed tasks involving configuration, documentation, or other non-standard files, `sonnet-only`'s flexibility gives it an edge.

3.  **The Cost of Sophistication:** The more sophisticated tooling of `sonnet-with-mcp` can sometimes be a hindrance, leading it to ignore problems it cannot solve with its advanced tools. The "simpler" agent can be more successful by tackling every part of the problem it can identify, even if it requires more basic methods.

4.  **Potential for a Hybrid Approach:** The ideal agent would combine both strengths: leveraging high-level tools when appropriate, but also generating surgical, file-based edits for the gaps that those tools leave behind, coupled with the deep self-analysis demonstrated by the `sonnet-only` agent.
