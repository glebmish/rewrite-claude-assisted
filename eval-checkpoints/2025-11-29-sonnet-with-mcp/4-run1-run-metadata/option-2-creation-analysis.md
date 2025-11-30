# Option 2: Text-Based Migration Recipe Analysis

## Approach Difference from Option 1

**Option 1 Strategy**: Semantic recipes with text fallbacks
- Used type-aware recipes: `org.openrewrite.yaml.ChangePropertyValue`, `org.openrewrite.gradle.AddDependency`, `org.openrewrite.gradle.RemoveDependency`
- Understood file structure and semantics
- Only used text replacement for Dockerfile and SQL where no semantic recipe exists

**Option 2 Strategy**: Pure text-based replacements
- Uses `org.openrewrite.text.FindAndReplace` for ALL transformations
- Treats all files as plain text with exact string matching
- No semantic understanding of file formats

## Key Differences

### GitHub Actions
- **Option 1**: `org.openrewrite.github.ChangeActionVersion` - understands GitHub Actions YAML structure
- **Option 2**: Text replacement of `uses: actions/cache@v2` → `uses: actions/cache@v4`

### Gradle Dependencies
- **Option 1**:
  - `RemoveDependency` - semantically removes H2 and preserves file structure
  - `AddDependency` - adds dependencies in appropriate configuration blocks
- **Option 2**:
  - Direct string replacement of entire dependency lines including indentation
  - Multi-line replacement to add all Testcontainers dependencies at once
  - Replaces comment line separately

### YAML Configuration
- **Option 1**: `org.openrewrite.yaml.ChangePropertyValue` - understands YAML path hierarchy
- **Option 2**: Exact string matching including indentation (e.g., `  driverClass: org.h2.Driver`)

### SQL Migration
- **Both**: Use text replacement (no semantic SQL recipe available)

## Trade-offs

### Option 2 Advantages
- **Simplicity**: Single recipe type, easier to understand
- **Predictability**: Exact string matches, no surprises
- **Control**: Precisely defines what changes, including whitespace
- **Debugging**: Easy to verify what will be replaced
- **No dependencies**: Doesn't rely on semantic parsers

### Option 2 Disadvantages
- **Fragility**: Breaks if indentation/formatting differs
- **Limited scope**: Won't find semantically equivalent variations
- **Whitespace sensitive**: Extra spaces break matches
- **No validation**: Won't catch malformed YAML/Gradle syntax
- **Multi-file risk**: If file structure varies across projects, won't match

### Option 1 Advantages
- **Robustness**: Works regardless of formatting/indentation
- **Semantic awareness**: Understands file structure
- **Safer**: Won't break file syntax
- **Flexible**: Handles variations in code style

### Option 1 Disadvantages
- **Complexity**: Multiple recipe types to understand
- **Less predictable**: Semantic recipes may modify formatting
- **Dependency management**: Relies on OpenRewrite's parsers

## Recommendation Context

**Use Option 2 when**:
- File formats are consistent and well-controlled
- Exact string patterns are known and stable
- Simplicity is preferred over robustness
- Quick migrations with minimal dependencies

**Use Option 1 when**:
- File formats may vary across projects
- Need to handle different code styles
- Want semantic validation
- Building reusable migration recipes
