# Option 2: Surgical Targeted Approach

## Recipe Composition Strategy

**Approach**: Granular recipe composition with explicit recipes for each individual transformation. Maximizes clarity and control at the expense of verbosity.

## Recipe Mapping

### Goal 1: Database Migration

**Strategic Organization**: Each transformation explicitly mapped to single recipe step.

#### Dependency Management (100% coverage)
**5 Recipes**:
1. `RemoveDependency` - H2 removal
2. `AddDependency` - PostgreSQL driver
3. `AddDependency` - Testcontainers core
4. `AddDependency` - Testcontainers PostgreSQL
5. `AddDependency` - Testcontainers JUnit integration

**Rationale**: Each dependency change isolated for:
- Clear audit trail
- Independent rollback capability
- Explicit version control
- Conditional execution with `onlyIfUsing`

#### Configuration Updates (100% coverage)
**5 YAML Recipes**:
1. Driver class change
2. Hibernate dialect change
3. Username externalization
4. Password externalization
5. URL externalization

**Rationale**: One recipe per configuration property:
- Atomic changes
- Easier troubleshooting
- Can skip specific changes if needed
- Clear mapping to PR diff

#### SQL Migration (70% coverage)
**1 Text Recipe**:
- `FindAndReplace` for AUTO_INCREMENT → BIGSERIAL

**Rationale**: Specific file targeting (`V1__Create_posts_table.sql`) rather than wildcard.

**Limitation**: Still text-based due to lack of semantic SQL recipes.

#### Build File Comments (60% coverage)
**1 Text Recipe**:
- Comment update in build.gradle

**Rationale**: Cosmetic change included for PR completeness.

### Goal 2: Infrastructure Updates

#### GitHub Actions (75% coverage)
**1 Text Recipe**:
- Specific file targeting: `ci.yml`
- Exact version replacement: `@v2` → `@v4`

**Rationale**: More precise than YAML JSONPath approach. Targets exact string pattern.

**Alternative**: Could use YAML recipe but text replacement is simpler for this case.

#### Dockerfile (70% coverage)
**1 Text Recipe**:
- Base image change with specific file targeting

**Rationale**: Single-file transformation, exact string match.

## Coverage Analysis

### Complete Semantic Coverage (100%)
- All Gradle dependency operations
- All YAML configuration changes

### Partial Coverage (60-75%)
- SQL syntax (text fallback)
- GitHub Actions (text fallback)
- Dockerfile (text fallback)
- Comments (text fallback)

### Key Differences from Option 1

**Option 2 Advantages**:
1. **Explicit file targeting** - `V1__Create_posts_table.sql` vs `*.sql`
2. **Clear goal separation** - Comments indicate Goal 1 vs Goal 2
3. **Independent steps** - Each change can be enabled/disabled
4. **Audit-friendly** - One transformation per recipe line
5. **Easier debugging** - Identify which step failed

**Option 2 Disadvantages**:
1. **More verbose** - 14 recipe steps vs 6 layers
2. **Repetitive** - Multiple AddDependency calls
3. **Maintenance** - More lines to update
4. **Less composable** - Harder to reuse subsets

## Alternative Recipe Considerations

### Rejected Alternatives

**For GitHub Actions**:
- `org.openrewrite.github.ActionsSetupLatestVersion`
  - **Rejected**: Too broad, updates all actions not just cache
  - **Reason**: Want surgical change to single action version

**For YAML changes**:
- `org.openrewrite.yaml.MergeYaml`
  - **Rejected**: Overwrites rather than targeted updates
  - **Reason**: Need to preserve existing structure

**For Gradle dependencies**:
- `org.openrewrite.gradle.ChangeDependency`
  - **Rejected**: For coordinate changes, not removal/addition
  - **Reason**: H2 → PostgreSQL is different artifact, not version bump

### Custom Recipe Opportunities

If gaps need to be filled with custom recipes:

**1. PostgreSQL Migration Recipe**
```yaml
name: com.example.MigrateH2ToPostgreSQL
# Composite of all database-related changes
# Would encapsulate Goals 1.1-1.5
```

**2. SQL Dialect Converter**
```java
// Custom visitor to handle SQL syntax transformations
// Would parse SQL AST and convert H2-specific syntax
// Coverage: AUTO_INCREMENT, data types, functions
```

**3. Dockerfile Base Image Recipe**
```java
// Custom visitor for Dockerfile AST
// Would semantically understand FROM directives
// Could handle tags, platforms, multi-stage builds
```

## Trade-offs Analysis

### When to Choose Option 2

**Best for**:
- Regulated environments requiring change tracking
- Incremental migrations (enable changes gradually)
- Teams needing explicit approval per change
- High-risk migrations requiring rollback capability
- Custom recipe development (clear building blocks)

**Not ideal for**:
- Quick automated migrations
- Teams preferring concise recipes
- Standard migrations (no custom requirements)
- Environments with high recipe maintenance burden

## Testing Strategy

**Per-Recipe Validation**:
1. Run with single recipe enabled
2. Verify expected change only
3. Accumulate changes progressively
4. Test after each goal completion

**Rollback Capability**:
- Can disable individual recipes
- Revert specific changes without full rollback
- A/B testing different approaches

## Recipe Execution Order

**Critical Dependencies**:
1. Dependencies before configuration
2. Configuration before SQL changes
3. Infrastructure updates independent

**Rationale**: Each recipe is independently safe but logical ordering aids debugging.
