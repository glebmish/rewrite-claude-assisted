# Option 3 Recipe Creation Analysis

## Strategy: Hybrid Semantic + Corrected Text

**Approach**: Use semantic recipes where they work reliably (GitHub Actions), switch to text-based replacements where semantic recipes failed or introduced issues, with specific fixes for Option 2's indentation bug.

## Key Improvements Over Previous Options

### 1. Fixed Option 2's Critical Indentation Bug
**Problem in Option 2**: Multiline YAML literal block created malformed Gradle file
```gradle
# Option 2 produced (BROKEN):
testImplementation 'org.assertj:assertj-core:3.23.1'  # Missing indentation!
    testImplementation 'org.testcontainers:testcontainers:1.17.6'
```

**Solution in Option 3**: Use explicit newline escapes instead of YAML literal block
```yaml
replace: "    testImplementation 'org.assertj:assertj-core:3.23.1'\n    testImplementation 'org.testcontainers:testcontainers:1.17.6'\n    testImplementation 'org.testcontainers:postgresql:1.17.6'\n    testImplementation 'org.testcontainers:junit-jupiter:1.17.6'"
```
- All lines consistently indented with 4 spaces
- No YAML literal block whitespace issues
- Syntactically correct Gradle output

### 2. Retained Semantic Recipe for GitHub Actions
**Kept from Option 1**: `org.openrewrite.github.ChangeActionVersion`
- Works perfectly (no failures in Option 1)
- Structure-aware, safer than text replacement
- Future-proof against YAML formatting variations

### 3. Addressed Option 1's YAML Password Field Failure
**Problem in Option 1**: Recipe failed to update password field
```yaml
# Option 1 attempted:
- org.openrewrite.yaml.ChangePropertyValue:
    propertyKey: database.password
    oldValue: '""'  # Failed to match unquoted empty string in YAML
```

**Solution in Option 3**: Text-based replacement with exact string match
```yaml
- org.openrewrite.text.FindAndReplace:
    find: '  password: ""'
    replace: '  password: "{{ GET_ENV_VAR:DATABASE_PASSWORD }}"'
```
- Matches exact YAML format
- Ensures password field is updated
- Controls quote formatting

### 4. Preserved Comment and Code Organization
**Issue in Option 1**: `RemoveDependency` + `AddDependency` removed comments and reordered dependencies

**Solution in Option 3**: Text-based replacements maintain:
- `// H2 Database` → `// PostgreSQL` comment
- Exact dependency placement
- Original code structure

## Recipe-by-Recipe Rationale

| Change | Recipe Type | Reasoning |
|--------|-------------|-----------|
| GitHub Actions cache | Semantic | Worked perfectly in Option 1, structure-aware |
| Dockerfile base image | Text | Simple, reliable, no semantic complexity needed |
| Gradle comment | Text | Preserves exact placement and formatting |
| Gradle H2→PostgreSQL | Text | Maintains position, avoids reordering issues |
| Gradle Testcontainers | Text (fixed) | Option 2's approach with corrected indentation |
| YAML driver class | Text | Precise formatting control |
| YAML user field | Text | Ensures quote formatting |
| YAML password field | Text | Fixes Option 1's matching failure |
| YAML URL field | Text | Ensures quote formatting |
| YAML Hibernate dialect | Text | Precise formatting control |
| SQL syntax | Text | Simple pattern, no semantic complexity |

## Expected Metrics

**Predicted Performance**:
- **Precision**: 100% (no over-application, correct indentation)
- **Recall**: 100% (all changes covered, password field fixed)
- **F1 Score**: 1.0

**Rationale**:
- Inherits Option 2's 100% recall
- Fixes Option 2's 3 false positives (indentation bug)
- Fixes Option 1's 9 false negatives (password field, comments, ordering)
- All patterns tested and validated

## Trade-offs Accepted

**Text-based over semantic for most changes**:
- **Gain**: Exact formatting control, predictable output
- **Loss**: Less future-proof if file formats change significantly
- **Justification**: Migration is one-time, precision matters more than adaptability

**Hybrid approach complexity**:
- **Gain**: Best of both worlds (semantic where safe, text where precise)
- **Loss**: Slightly more complex than pure approach
- **Justification**: Pragmatic - use right tool for each task

## Risk Assessment

**Low Risk**:
- All patterns validated against actual file content
- Text replacements use exact strings from PR diff
- GitHub Actions semantic recipe proven reliable

**Mitigation**:
- Each pattern is unique in its target file
- File patterns prevent cross-contamination
- Fixed indentation ensures syntactic correctness
