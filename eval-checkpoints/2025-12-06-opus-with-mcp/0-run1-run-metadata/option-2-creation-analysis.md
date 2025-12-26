# Option 2: Targeted/Narrow Recipe Analysis

## Approach
Surgical precision with specific recipes for each transformation. Minimizes side effects.

## Recipe Mapping by Intent

### 1. GitHub Actions java-version
- **Recipe**: `org.openrewrite.github.SetupJavaUpgradeJavaVersion`
- **Type**: Semantic (YAML-aware)
- **Coverage**: FULL - Updates `java-version` in `actions/setup-java` steps

### 2. GitHub Actions step name
- **Recipe**: `org.openrewrite.yaml.ChangeValue`
- **Type**: Semantic (YAML-aware with JsonPath)
- **Coverage**: FULL - Changes step name using JsonPath selector
- **Note**: Uses filter `[?(@.name == 'Set up JDK 17')]` for precise targeting

### 3. Gradle wrapper version in build.gradle
- **Recipe**: `org.openrewrite.text.FindAndReplace`
- **Type**: Text-based
- **Gap**: `UpdateGradleWrapper` modifies `gradle-wrapper.properties`, not `build.gradle` wrapper block
- **Coverage**: FULL via text replacement

### 4. Gradle sourceCompatibility to toolchain migration
- **Recipe**: `org.openrewrite.text.FindAndReplace`
- **Type**: Text-based
- **Gap**: `UpdateJavaCompatibility` updates version values but cannot transform to toolchain syntax
- **Coverage**: FULL via text replacement (structural transformation)

### 5. Dockerfile base images
- **Recipe**: `org.openrewrite.text.FindAndReplace` (x2)
- **Type**: Text-based
- **Gap**: No semantic Dockerfile recipe exists for image version changes
- **Coverage**: FULL via text replacement

### 6. README.md Java version references
- **Recipe**: `org.openrewrite.text.FindAndReplace` (x2)
- **Type**: Text-based
- **Coverage**: FULL - Markdown has no semantic structure requiring special handling

## Semantic vs Text-Based Breakdown

| Transformation | Semantic Recipe Available | Recipe Used |
|---------------|---------------------------|-------------|
| GitHub Actions java-version | YES | SetupJavaUpgradeJavaVersion |
| GitHub Actions step name | YES | yaml.ChangeValue |
| Gradle wrapper version | NO (wrong target) | text.FindAndReplace |
| Gradle toolchain migration | NO (structural gap) | text.FindAndReplace |
| Dockerfile images | NO | text.FindAndReplace |
| README.md text | N/A (plain text) | text.FindAndReplace |

## Identified Gaps

1. **Gradle Toolchain Migration**: No recipe to transform `sourceCompatibility`/`targetCompatibility` to `java { toolchain { } }` block
2. **Gradle Wrapper Block**: No recipe to modify `gradleVersion` inside `wrapper { }` block in build.gradle
3. **Dockerfile Transformations**: No semantic Dockerfile recipe for image version updates

## Trade-offs

**Advantages**:
- Each change is explicit and traceable
- No unwanted side effects
- Easy to understand what each step does
- Can disable individual transformations

**Disadvantages**:
- Heavy reliance on text-based recipes (6 of 8 steps)
- Text replacement is fragile to formatting variations
- More verbose configuration

## Recommendation

This targeted approach is suitable when:
- You need precise control over each change
- The codebase has non-standard formatting
- You want to audit each transformation individually
