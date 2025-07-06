# OpenRewrite Framework Guide for Claude Code Agent

## Executive Summary

This comprehensive guide enables a Claude Code agent to understand and implement OpenRewrite-based refactoring solutions. OpenRewrite is an open-source automated refactoring ecosystem that uses **Lossless Semantic Trees (LST)** to perform safe, type-aware code transformations at scale. The framework originated at Netflix and has been adopted by major organizations for framework migrations, security patches, and code modernization.

## Core OpenRewrite Architecture

### Lossless Semantic Tree (LST) Foundation

OpenRewrite's key innovation is the **LST**, which differentiates it from traditional AST-based tools. The LST is:

- **Type-attributed**: Contains complete type information, even for external dependencies
- **Format-preserving**: Maintains all whitespace, comments, and formatting details
- **Semantic-rich**: Captures deeper semantic relationships beyond syntax
- **Lossless**: No information is lost during parsing and transformation

**Key Advantage**: Unlike ASTs that lose formatting information, LSTs enable precise localized changes while preserving original code style and structure.

### Language-Specific LST Types

OpenRewrite supports multiple languages with specialized LST implementations:

- **Java LST (J)**: Full Java language support with type attribution
- **XML LST**: For XML, Maven POM, and Spring configuration files
- **YAML LST**: For YAML configuration files
- **Properties LST**: For .properties files
- **JSON LST**: For JSON configuration files
- **Groovy LST**: For Gradle build files and Groovy scripts
- **Kotlin LST**: For Kotlin source files

## Phase 1: Intent Extraction Best Practices

### Understanding Refactoring Intent

Intent extraction is about identifying the **what** and **why** of code changes. Common refactoring intents include:

**1. Framework Migration Intent**
- **Indicators**: Version changes in dependencies, package renames, API deprecations
- **Examples**: 
  - Spring Boot 2.7 → 3.0 (Jakarta namespace changes)
  - JUnit 4 → JUnit 5 (annotation and assertion changes)
  - Java EE → Jakarta EE (javax.* → jakarta.*)

**2. Language Version Upgrade Intent**
- **Indicators**: Compiler version changes, new language feature adoption
- **Examples**:
  - Java 8 → Java 11 (var keyword, new APIs)
  - Java 11 → Java 17 (records, pattern matching)
  - Java 17 → Java 21 (virtual threads, pattern improvements)

**3. Security Remediation Intent**
- **Indicators**: Vulnerable dependency updates, security pattern fixes
- **Examples**:
  - Log4j 2.x vulnerability patches
  - Hardcoded secrets removal
  - SQL injection prevention

**4. Code Quality Improvement Intent**
- **Indicators**: Static analysis fixes, code simplification patterns
- **Examples**:
  - Null safety improvements
  - Dead code removal
  - Method extraction for readability

### Intent Extraction Rules of Thumb

**Rule 1: Look for Patterns, Not Individual Changes**
- Single file changes rarely indicate systematic refactoring
- Multiple similar changes suggest automated transformation opportunity
- Consistent patterns across files indicate recipe potential

**Rule 2: Identify Scope and Granularity**
- **Project-wide**: Dependency updates, framework migrations
- **Package-level**: API reorganization, module restructuring
- **Class-level**: Design pattern implementation, inheritance changes
- **Method-level**: API usage updates, parameter modifications

**Rule 3: Recognize Common Transformation Types**
- **Type Changes**: Class renames, package migrations
- **Method Signature Changes**: Parameter additions/removals, return type changes
- **Annotation Updates**: Framework-specific annotation migrations
- **Configuration Changes**: Property renames, format migrations

## Phase 2: Visitor Patterns Deep Dive

### Core Visitor Types and Use Cases

#### 1. JavaVisitor - The Base Visitor

**When to use**: When you need full control over the visiting process
```java
public class CustomJavaVisitor extends JavaVisitor<ExecutionContext> {
    @Override
    public J visitCompilationUnit(J.CompilationUnit cu, ExecutionContext ctx) {
        // Visit entire compilation unit
        return super.visitCompilationUnit(cu, ctx);
    }
}
```

**Best for**:
- Complex multi-element transformations
- Custom traversal logic
- Performance-critical operations

#### 2. JavaIsoVisitor - The Type-Preserving Visitor

**When to use**: Most common choice for safe transformations
```java
public class TypeSafeVisitor extends JavaIsoVisitor<ExecutionContext> {
    @Override
    public J.MethodInvocation visitMethodInvocation(J.MethodInvocation method, ExecutionContext ctx) {
        // Type is preserved - returns J.MethodInvocation
        return super.visitMethodInvocation(method, ctx);
    }
}
```

**Best for**:
- Method refactoring
- Type changes
- Import modifications
- Most general-purpose transformations

#### 3. JavaTemplate - The Pattern-Based Transformation

**When to use**: For inserting or replacing code with complex structures
```java
JavaTemplate template = JavaTemplate.builder("#{any(java.lang.String)}.isEmpty()")
    .imports("java.lang.String")
    .build();
```

**Best for**:
- Adding new code blocks
- Complex expression replacements
- Method body transformations
- Maintaining proper formatting

### Language-Specific Visitors

#### XML Visitors
```java
public class XmlIsoVisitor<P> extends XmlVisitor<P> {
    @Override
    public Xml.Tag visitTag(Xml.Tag tag, P p) {
        // Transform XML elements
        return super.visitTag(tag, p);
    }
}
```

**Use cases**:
- Maven POM transformations
- Spring XML configuration updates
- General XML refactoring

#### YAML Visitors
```java
public class YamlIsoVisitor<P> extends YamlVisitor<P> {
    @Override
    public Yaml.Mapping.Entry visitMappingEntry(Yaml.Mapping.Entry entry, P p) {
        // Transform YAML key-value pairs
        return super.visitMappingEntry(entry, p);
    }
}
```

**Use cases**:
- Application configuration updates
- CI/CD pipeline modifications
- Kubernetes manifest transformations

#### Properties Visitors
```java
public class PropertiesVisitor<P> extends TreeVisitor<Properties, P> {
    @Override
    public Properties.Entry visitEntry(Properties.Entry entry, P p) {
        // Transform property entries
        return super.visitEntry(entry, p);
    }
}
```

**Use cases**:
- Application property migrations
- Configuration key renames
- Value standardization

#### Groovy/Gradle Visitors
```java
public class GroovyIsoVisitor<P> extends GroovyVisitor<P> {
    @Override
    public G.CompilationUnit visitCompilationUnit(G.CompilationUnit cu, P p) {
        // Transform Gradle build scripts
        return super.visitCompilationUnit(cu, p);
    }
}
```

**Use cases**:
- Gradle dependency updates
- Build configuration modernization
- Plugin migrations

### Specialized Visitor Patterns

#### ScanningRecipe - Two-Phase Transformation
**When to use**: When you need to analyze the entire codebase before making changes

**Phase 1 - Scanning**:
- Collect information across all files
- Build dependency graphs
- Identify transformation candidates

**Phase 2 - Transformation**:
- Apply changes based on collected data
- Ensure consistency across files
- Handle cross-file dependencies

**Best for**:
- Unused code removal
- Dependency analysis
- Cross-file refactoring
- Impact analysis

#### Preconditions - Conditional Visitors
**When to use**: To limit recipe application to specific contexts

Types of preconditions:
- **File-based**: Only apply to certain file types or paths
- **Content-based**: Only apply when specific patterns exist
- **Dependency-based**: Only apply when certain libraries are present

## Phase 3: Recipe Selection Strategy

### Understanding Recipe Granularity

#### Broad/General Recipes
These recipes perform comprehensive transformations across multiple aspects:

**Example: UpgradeSpringBoot_3_0**
- Updates all Spring Boot dependencies
- Migrates javax to jakarta namespaces  
- Updates configuration properties
- Adapts deprecated APIs
- Modifies build configurations

**When to use broad recipes**:
- Starting a major migration
- Ensuring comprehensive coverage
- When all changes are desired
- Team lacks detailed knowledge

#### Narrow/Specific Recipes
These recipes target precise transformations:

**Example: ChangeGradleJavaLanguageVersion**
- Only modifies `sourceCompatibility` and `targetCompatibility`
- Leaves other build configurations untouched
- Very predictable outcome

**When to use specific recipes**:
- Surgical precision needed
- Gradual migration approach
- Risk mitigation important
- Custom requirements exist

### Recipe Mapping Best Practices

#### 1. Start with Recipe Discovery

**Search strategies**:
- Use recipe catalog websites
- Search by framework name + version
- Look for recipe tags matching your intent
- Check recipe descriptions for coverage

**Example discovery patterns**:
- "spring boot 3" → finds Spring Boot migration recipes
- "junit 5" → finds JUnit migration recipes  
- "java 17" → finds Java version upgrade recipes
- "log4j" → finds security remediation recipes

#### 2. Evaluate Recipe Fit

**Assessment criteria**:
- **Coverage**: Does it handle all your patterns?
- **Side effects**: What else does it change?
- **Dependencies**: Required libraries or versions?
- **Configurability**: Can you customize behavior?

**Red flags**:
- Recipe description is vague
- No test coverage shown
- Handles too many unrelated concerns
- No configuration options

#### 3. Recipe Composition Strategy

**Layering approach**:
1. **Foundation layer**: Broad migration recipes
2. **Refinement layer**: Specific adjustments
3. **Cleanup layer**: Formatting and imports
4. **Validation layer**: Static analysis

**Example composition for Java 8 → Java 21**:
```yaml
recipeList:
  # Foundation: Core language migration
  - org.openrewrite.java.migrate.Java8toJava11
  - org.openrewrite.java.migrate.Java11toJava17  
  - org.openrewrite.java.migrate.Java17toJava21
  
  # Refinement: Specific feature adoption
  - org.openrewrite.java.migrate.UseTextBlocks
  - org.openrewrite.java.migrate.UseRecords
  
  # Cleanup: Code organization
  - org.openrewrite.java.OrderImports
  - org.openrewrite.java.RemoveUnusedImports
  
  # Validation: Quality checks
  - org.openrewrite.staticanalysis.CommonStaticAnalysis
```

### Recipe Selection Decision Tree

**For Framework Migrations:**
1. Check for official framework migration recipe
2. If exists → use it as foundation
3. If not → compose from specific recipes
4. Add framework-specific cleanup recipes
5. Include static analysis for validation

**For Security Remediations:**
1. Look for CVE-specific recipes first
2. Check security-focused recipe modules
3. Consider dependency upgrade recipes
4. Add security scanning recipes
5. Include compliance validation

**For Code Quality:**
1. Start with static analysis recipe bundles
2. Add specific pattern fixes
3. Include formatting standardization
4. Consider readability improvements
5. Add metric validation

## Phase 4: Recipe Type Categories

### 1. Search Recipes (Non-modifying)
**Purpose**: Find code patterns without changing them

**Common search recipes**:
- `FindTypes`: Locate usage of specific classes
- `FindMethods`: Find method invocations
- `FindAnnotations`: Locate annotated elements
- `FindText`: Search for text patterns

**Use cases**:
- Impact analysis before refactoring
- Compliance checking
- Dependency analysis
- Technical debt assessment

### 2. Refactoring Recipes (Code transformation)
**Purpose**: Transform code structure while preserving behavior

**Categories**:
- **Type refactoring**: Class renames, package moves
- **Method refactoring**: Signature changes, extractions
- **Field refactoring**: Encapsulation, type changes
- **Pattern refactoring**: Design pattern implementation

### 3. Migration Recipes (Framework/version upgrades)
**Purpose**: Adapt code to new framework versions or APIs

**Characteristics**:
- Often composite recipes
- Include multiple transformation types
- Handle breaking changes
- Update configurations

### 4. Static Analysis Recipes (Code quality)
**Purpose**: Improve code quality and maintainability

**Common improvements**:
- Null safety enhancements
- Resource leak prevention
- Code simplification
- Performance optimizations

### 5. Security Recipes (Vulnerability remediation)
**Purpose**: Fix security vulnerabilities and prevent issues

**Focus areas**:
- Dependency vulnerabilities
- Injection prevention
- Cryptography updates
- Secret management

### 6. Formatting Recipes (Code style)
**Purpose**: Standardize code formatting and organization

**Scope**:
- Import organization
- Whitespace normalization
- Naming conventions
- Comment formatting

## Phase 5: Multi-File Recipe Patterns

### Handling Different File Types

#### Java + Maven POM Coordination
```yaml
recipeList:
  # Update Java code
  - org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_0
  
  # Update Maven configuration
  - org.openrewrite.maven.UpgradeParentVersion:
      groupId: org.springframework.boot
      artifactId: spring-boot-starter-parent
      newVersion: 3.0.x
      
  # Update properties
  - org.openrewrite.maven.ChangePropertyValue:
      key: java.version
      newValue: 17
```

#### Java + Gradle Build Coordination
```yaml
recipeList:
  # Update Java code
  - org.openrewrite.java.migrate.javax.JavaxMigrationToJakarta
  
  # Update Gradle configuration  
  - org.openrewrite.gradle.UpdateGradleWrapper:
      version: 8.x
      
  - org.openrewrite.gradle.plugins.UpgradePluginVersion:
      pluginId: org.springframework.boot
      newVersion: 3.0.x
```

#### Application Code + Configuration Files
```yaml
recipeList:
  # Update Java annotations
  - org.openrewrite.java.spring.ChangeSpringPropertyKey:
      oldPropertyKey: spring.profiles
      newPropertyKey: spring.config.activate.on-profile
      
  # Update YAML configuration
  - org.openrewrite.yaml.ChangePropertyKey:
      oldPropertyKey: spring.profiles
      newPropertyKey: spring.config.activate.on-profile
      
  # Update properties files
  - org.openrewrite.properties.ChangePropertyKey:
      oldPropertyKey: spring.profiles  
      newPropertyKey: spring.config.activate.on-profile
```

## Phase 6: Testing Strategies by Recipe Type

### Testing Search Recipes
- Verify correct pattern identification
- Test edge cases and variations
- Ensure no false positives
- Validate performance on large codebases

### Testing Refactoring Recipes
- Confirm behavior preservation
- Test with different code styles
- Verify type safety maintained
- Check compilation success

### Testing Migration Recipes
- Test against multiple source versions
- Verify all deprecations handled
- Check backward compatibility needs
- Validate with real project structures

### Testing Static Analysis Recipes
- Ensure issues correctly identified
- Verify fixes don't break code
- Test idempotency
- Check for over-correction

## Implementation Best Practices

### 1. Recipe Development Workflow

**Step 1: Define Clear Intent**
- What specific transformation is needed?
- What patterns should be matched?
- What should be excluded?
- What are the edge cases?

**Step 2: Choose Appropriate Visitor**
- JavaIsoVisitor for most Java transformations
- ScanningRecipe for cross-file analysis
- Language-specific visitors for other files
- JavaTemplate for complex replacements

**Step 3: Implement Incrementally**
- Start with simple cases
- Add complexity gradually
- Test each increment
- Handle edge cases last

**Step 4: Optimize for Performance**
- Minimize tree traversals
- Use efficient matching patterns
- Cache expensive computations
- Return early when possible

### 2. Error Handling Philosophy

**Do No Harm Principle**:
- If unsure, don't transform
- Preserve original code on errors
- Log warnings for skipped transformations
- Never produce invalid code

**Graceful Degradation**:
- Handle missing dependencies
- Work with partial type information
- Skip unsupported patterns
- Continue with other files

### 3. Recipe Composition Guidelines

**Ordering Matters**:
1. Structural changes first (renames, moves)
2. API updates second
3. Code cleanup third
4. Formatting last

**Avoid Conflicts**:
- Don't combine overlapping transformations
- Separate analysis from modification
- Use preconditions to prevent conflicts
- Test composed recipes thoroughly

### 4. Documentation Standards

**Essential Documentation**:
- Clear display name and description
- Concrete before/after examples
- Preconditions and limitations
- Configuration options explained
- Tags for discoverability

**Example Documentation Pattern**:
```yaml
displayName: Migrate to JUnit 5
description: |
  Migrates JUnit 4 tests to JUnit 5, including:
  - Annotation changes (@Test, @Before, @After)
  - Assertion method updates
  - Exception testing patterns
  - Parameterized test conversion
tags:
  - testing
  - junit
  - migration
estimatedEffortPerOccurrence: PT5M
```

## Performance Optimization Guidelines

### Memory Management
- Use `ListUtils.map()` instead of streams for LST operations
- Return the same LST instance when no changes made
- Avoid creating unnecessary objects
- Use JavaTemplate for complex constructions

### Execution Efficiency
- Design single-pass visitors when possible
- Use preconditions to skip irrelevant files
- Implement early termination conditions
- Cache regex patterns and matchers

### Scalability Considerations
- Test with large codebases
- Monitor memory usage
- Optimize for common cases
- Consider parallel execution impacts

## Summary: Key Success Factors

1. **Clear Intent**: Understand exactly what needs transformation
2. **Right Tool**: Choose appropriate visitor and recipe type
3. **Incremental Approach**: Build complexity gradually
4. **Thorough Testing**: Cover edge cases and variations
5. **Good Documentation**: Enable easy discovery and usage
6. **Performance Focus**: Optimize for large-scale execution
7. **Error Resilience**: Handle unexpected cases gracefully

This guide provides comprehensive coverage of OpenRewrite concepts, patterns, and best practices for implementing high-quality automated refactoring solutions.