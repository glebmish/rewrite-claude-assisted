# Phase 4: Recipe Validation

## Validation Results

### Option 1 (Broad Approach)
- **Precision**: 64.52%
- **Recall**: 64.52%
- **F1 Score**: 64.52%

**Gaps**:
- GitHub Actions step name not updated
- Java toolchain syntax differs (uses sourceCompatibility instead of toolchain block)
- JUnit dependencies use aggregate artifact
- `application.mainClassName` not migrated
- `shadowJar.mainClassName` not added

**Over-applications**:
- Gradle wrapper scripts regenerated
- `Optional.isPresent()` → `isEmpty()` modernization
- Mockito upgraded 3.12.4 → 4.11.0
- SHA256 checksum added

### Option 2 (Narrow Approach)
- **Precision**: 80.0%
- **Recall**: 64.5%
- **F1 Score**: 71.4%

**Gaps**:
- Java toolchain syntax not used
- GitHub Actions step name not renamed
- `application { mainClassName }` not migrated
- `shadowJar { mainClassName }` not added
- Comment not updated

**Over-applications**:
- Dependency ordering differs
- Quote style differences

## Comparison

| Metric | Option 1 | Option 2 |
|--------|----------|----------|
| Precision | 64.52% | 80.0% |
| Recall | 64.52% | 64.5% |
| F1 Score | 64.52% | 71.4% |
| Extra changes | More | Fewer |

## Status: ✅ Complete
