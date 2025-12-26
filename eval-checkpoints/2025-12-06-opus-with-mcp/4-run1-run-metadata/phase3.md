# Phase 3: Recipe Mapping

## Option 1 - Broad Approach
- **Recipe Name**: `com.example.PR3Option1`
- **Strategy**: Use broader, general recipes where available
- **Recipe Count**: 13 recipes total

## Option 2 - Narrow Approach
- **Recipe Name**: `com.example.PR3Option2`
- **Strategy**: Use specific, targeted recipes for precise control
- **Recipe Count**: 14 recipes total

## Recipe Coverage Summary

| Category | Recipes Used | Semantic? |
|----------|-------------|-----------|
| Gradle Dependencies | `RemoveDependency`, `AddDependency` (x4) | Yes |
| YAML Configuration | `ChangeValue` (x5) | Yes |
| SQL Migration | `FindAndReplace` | No (text-based) |
| Dockerfile | `FindAndReplace` | No (text-based) |
| GitHub Actions | `ChangeActionVersion` | Yes |

## Identified Gaps
- No semantic recipe for H2→PostgreSQL SQL syntax migration
- No semantic recipe for Dockerfile FROM instruction updates

## Output Files
- `option-1-recipe.yaml`
- `option-1-creation-analysis.md`
- `option-2-recipe.yaml`
- `option-2-creation-analysis.diff`

## Status: SUCCESS
