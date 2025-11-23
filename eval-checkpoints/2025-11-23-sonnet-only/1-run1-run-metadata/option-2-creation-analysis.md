# Option 2: Broad/Comprehensive Approach Analysis

## Recipe Selection Rationale

**Primary Recipe**: `org.openrewrite.java.migrate.UpgradeToJava17`
- Industry-standard comprehensive migration recipe from OpenRewrite's rewrite-migrate-java module
- Orchestrates multiple specialized recipes for complete Java 17 modernization
- Maintained by OpenRewrite team, ensuring compatibility and best practices
- Designed for teams wanting comprehensive coverage with minimal configuration

**Complementary Recipes**:
- `UpdateGradleWrapper` (version 7.x) - Required for Java 17 compatibility
- `FindAndReplace` (2x) - Dockerfile base image updates (no semantic parser available)

## Coverage Assessment

### What This Recipe Covers

**From UpgradeToJava17 (comprehensive coverage)**:

1. **Build Configuration** (via UpgradeBuildToJava17 → UpgradeJavaVersion)
   - ✅ sourceCompatibility: 11 → 17
   - ✅ targetCompatibility: 11 → 17
   - Updates Maven/Gradle language version settings

2. **Language Feature Modernization** (bonus transformations)
   - Pattern matching for instanceof
   - Text blocks adoption
   - String.formatted() usage
   - Serial annotations for serialVersionUID
   - Record import handling

3. **Deprecated API Replacements** (12+ recipes)
   - Removed Runtime.trace methods
   - Removed ToolProvider constructors
   - SSL/TLS deprecated APIs
   - File I/O finalize methods
   - RMI deprecated constants
   - And 7+ other deprecated API migrations

4. **Dependency Upgrades**
   - Guice → 5.x
   - Commons Codec → 1.17.x
   - MapStruct → 1.6.x
   - Lombok-MapStruct binding additions
   - SpotBugs Maven Plugin → 4.9.x

5. **Plugin Compatibility**
   - Via UpgradePluginsForJava17
   - Ensures build plugins support Java 17

6. **Java EE → Jakarta EE 8** (via Java8toJava11)
   - Migrates removed Java EE dependencies
   - Adds Jakarta EE replacements where needed

**From UpdateGradleWrapper**:
- ✅ Gradle wrapper: 6.7 → 7.x (covers 7.6)
- Updates gradle-wrapper.properties distributionUrl

**From FindAndReplace (2 instances)**:
- ✅ Dockerfile builder: openjdk:11-jdk-slim → eclipse-temurin:17-jdk-alpine
- ✅ Dockerfile runtime: openjdk:11-jre-slim → eclipse-temurin:17-jre-alpine

### What the PR Contains (Reference)

PR-specific changes:
1. build.gradle: sourceCompatibility/targetCompatibility 11 → 17 ✅
2. gradle-wrapper.properties: Gradle 6.7 → 7.6 ✅
3. Dockerfile: Base images 11 → 17 ✅
4. Authentication refactoring (NOT Java upgrade - IGNORED)

## Side Effects and Additional Changes

**Language Modernization** (bonus transformations):
- Code will be automatically refactored to use Java 17 language features where applicable
- instanceof checks converted to pattern matching
- Multi-line strings converted to text blocks (if multi-line)
- String concatenation may use formatted() method
- Serial fields get @Serial annotations

**Dependency Updates**:
- Third-party libraries upgraded to Java 17-compatible versions
- May introduce new API versions requiring code adjustments
- Build plugins updated to compatible versions

**API Migrations**:
- 12+ deprecated API patterns automatically replaced
- Affects SSL/TLS, File I/O, RMI, and other core Java APIs
- May change runtime behavior if deprecated APIs were used

**Java EE Dependencies**:
- If project uses Java EE, dependencies migrated to Jakarta EE 8
- Package names change from javax.* to jakarta.*

## Trade-offs of Broad Approach

### Advantages

1. **Comprehensive Coverage**
   - Single recipe handles most migration concerns
   - Leverages OpenRewrite team's expertise
   - Includes future-proofing language features

2. **Maintainability**
   - Official recipe receives ongoing updates
   - Bug fixes and improvements automatically available
   - Clear upgrade path to Java 21+ later

3. **Simplicity**
   - Minimal configuration required
   - One-command execution covers multiple areas
   - Reduced cognitive overhead for recipe composition

4. **Best Practices**
   - Applies industry-standard patterns
   - Modernizes code to Java 17 idioms
   - Ensures plugin compatibility

### Disadvantages

1. **Scope Creep**
   - Makes changes beyond what PR demonstrates
   - Language feature adoption may surprise developers
   - Dependency upgrades could introduce breaking changes

2. **Control Loss**
   - Cannot easily exclude specific sub-transformations
   - All-or-nothing for UpgradeToJava17 sub-recipes
   - May apply transformations not desired yet

3. **Testing Burden**
   - Broader changes require more comprehensive testing
   - Language feature changes need validation
   - Dependency upgrades may surface compatibility issues

4. **Risk Profile**
   - Higher chance of introducing subtle behavioral changes
   - Deprecated API replacements may have semantic differences
   - Multiple simultaneous changes harder to debug

5. **Text-Based Limitations**
   - Dockerfile updates use FindAndReplace (not LST-aware)
   - Cannot compose with other Docker recipes afterward
   - Simple string matching may miss edge cases

## Recommendation Context

**Best suited for**:
- Teams wanting comprehensive Java 17 adoption
- Greenfield migration starting fresh
- Projects ready to embrace modern Java patterns
- Organizations with robust testing infrastructure

**Less suitable for**:
- Incremental, cautious migrations
- Projects with legacy code compatibility requirements
- Teams wanting granular control over each change
- Situations requiring minimal disruption

## Recipe Dependencies

**Required Maven dependencies**:
```xml
<dependency>
  <groupId>org.openrewrite.recipe</groupId>
  <artifactId>rewrite-migrate-java</artifactId>
  <version>2.x.x</version>
</dependency>
```

**Required Gradle dependencies**:
```gradle
rewrite("org.openrewrite.recipe:rewrite-migrate-java:2.+")
```

## Validation Strategy

**Post-migration checks**:
1. Build succeeds with Java 17
2. All tests pass
3. Review language feature changes for correctness
4. Validate dependency upgrades don't break APIs
5. Test Docker images build and run
6. Verify Gradle wrapper works with Java 17
7. Check deprecated API replacements for behavioral equivalence
