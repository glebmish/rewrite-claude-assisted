# Phase 2: Intent Analysis

## PR Information
- **URL**: https://github.com/openrewrite-assist-testing-dataset/simple-blog-platform/pull/3
- **Title**: feat: Migrate from H2 to PostgreSQL and bump GH actions
- **Base Branch**: master
- **Head Branch**: feature/upgrade

## OpenRewrite Best Practices Review

Key insights from OpenRewrite documentation:
- Multi-file transformations require coordination across different file types (Java, Gradle, YAML, SQL)
- Recipe composition should layer: foundation → refinement → cleanup → validation
- Language-specific visitors needed: Gradle (dependencies), YAML (config), plain text (SQL, Dockerfile)
- Pattern matching vs surgical changes: This PR combines both database migration (pattern-based) and version bumps (surgical)
- Configuration changes require different visitor types: Properties/YAML visitors for config files

## Code Changes Analysis

### Files Modified
1. `.github/workflows/ci.yml` - GitHub Actions workflow
2. `Dockerfile` - Container image
3. `build.gradle` - Gradle dependencies
4. `src/main/resources/config.yml` - Database configuration
5. `src/main/resources/db/migration/V1__Create_posts_table.sql` - Database schema

### Change Patterns

**Database Migration Pattern:**
- H2 → PostgreSQL across multiple file types
- Consistent transformation pattern for database-specific elements
- Environment variable configuration for credentials

**Version Bump Pattern:**
- GitHub Actions cache action v2 → v4
- Docker base image change: openjdk → eclipse-temurin

## Intent Extraction

### Strategic Intent: Migrate database from H2 to PostgreSQL and update infrastructure dependencies

**Confidence Level: HIGH**

This is a dual-purpose PR with two independent strategic goals.

## Intents Tree

```
* Strategic Goal 1: Migrate from H2 embedded database to PostgreSQL
  * Update Gradle dependencies
    * Remove H2 database dependency
      * Remove line `implementation 'com.h2database:h2:2.1.214'` from build.gradle
    * Add PostgreSQL database dependency
      * Add line `implementation 'org.postgresql:postgresql:42.6.0'` in build.gradle
    * Add Testcontainers dependencies for testing
      * Add `testImplementation 'org.testcontainers:testcontainers:1.17.6'` in build.gradle
      * Add `testImplementation 'org.testcontainers:postgresql:1.17.6'` in build.gradle
      * Add `testImplementation 'org.testcontainers:junit-jupiter:1.17.6'` in build.gradle
  * Update database configuration in YAML
    * Change database driver class
      * Replace `driverClass: org.h2.Driver` with `driverClass: org.postgresql.Driver` in config.yml
    * Change database connection parameters
      * Replace `user: sa` with `user: "{{ GET_ENV_VAR:DATABASE_USER }}"` in config.yml
      * Replace `password: ""` with `password: "{{ GET_ENV_VAR:DATABASE_PASSWORD }}"` in config.yml
      * Replace `url: jdbc:h2:mem:blog;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE` with `url: "{{ GET_ENV_VAR:DATABASE_URL }}"` in config.yml
    * Change Hibernate dialect
      * Replace `hibernate.dialect: org.hibernate.dialect.H2Dialect` with `hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect` in config.yml
  * Update SQL migration scripts
    * Change auto-increment syntax from H2 to PostgreSQL
      * Replace `id BIGINT AUTO_INCREMENT PRIMARY KEY` with `id BIGSERIAL PRIMARY KEY` in V1__Create_posts_table.sql
  * Update comment in build.gradle
    * Replace comment `// H2 Database` with `// PostgreSQL` in build.gradle

* Strategic Goal 2: Update infrastructure dependencies
  * Update GitHub Actions workflow
    * Bump actions/cache version
      * Replace `uses: actions/cache@v2` with `uses: actions/cache@v4` in .github/workflows/ci.yml
  * Update Docker base image
    * Change from OpenJDK to Eclipse Temurin
      * Replace `FROM openjdk:17-jre-slim` with `FROM eclipse-temurin:17-jre-alpine` in Dockerfile
```

## Confidence Levels

**High Confidence Intents:**
- Database dependency swap (H2 → PostgreSQL): Pattern is clear and complete
- Configuration file updates: All database-related config changes are consistent
- SQL syntax changes: Standard H2 → PostgreSQL migration pattern
- GitHub Actions version bump: Simple version update
- Docker image change: Simple base image update

**Medium Confidence Intents:**
- None identified

**Low Confidence Intents:**
- None identified

## Pattern Analysis

**Consistent Patterns:**
1. Complete database stack migration (dependency → config → SQL schema)
2. Environment variable externalization for credentials
3. Addition of testing infrastructure (Testcontainers)

**Edge Cases:**
- No edge cases identified; changes are straightforward replacements

**Manual Adjustments:**
- Comment update in build.gradle (non-code change)
- Environment variable template syntax `{{ GET_ENV_VAR:... }}` is application-specific

## Automation Challenges

**High Automation Potential:**
- Gradle dependency changes (95% automatable via standard recipes)
- YAML configuration updates (90% automatable with custom patterns)
- SQL syntax changes (80% automatable with text replacement)
- Dockerfile base image change (70% automatable)
- GitHub Actions version bump (95% automatable)

**Low Automation Potential:**
- Environment variable template syntax is application-specific (requires custom recipe)
- Comment updates are cosmetic and typically excluded from automated recipes

## Recipe Mapping Considerations

**Recommended Recipe Types:**
1. **AddDependency** recipes for PostgreSQL and Testcontainers
2. **RemoveDependency** recipe for H2
3. **ChangePropertyKey/ChangePropertyValue** recipes for YAML config
4. **FindAndReplace** or custom visitor for SQL migration scripts
5. **UpgradeAction** or similar for GitHub Actions version
6. **FindAndReplace** for Dockerfile base image

**Recipe Composition Strategy:**
- Two separate recipe compositions recommended (one per strategic goal)
- OR: Single composite recipe with clear sections
- Testing recipes should validate PostgreSQL connectivity

**Preconditions Needed:**
- Check for H2 dependency presence before attempting migration
- Verify Dropwizard framework usage for config file structure

**Search Recipes Needed:**
- FindTypes for H2 Driver usage verification
- FindText for H2-specific SQL syntax patterns

## Potential Issues

1. **Runtime dependencies**: PostgreSQL driver must be available at runtime
2. **Database availability**: PostgreSQL instance must be running (not embedded like H2)
3. **SQL compatibility**: Other SQL files may need similar syntax updates
4. **Testing impact**: Tests may need PostgreSQL via Testcontainers
5. **Environment variables**: Runtime environment must provide DATABASE_USER, DATABASE_PASSWORD, DATABASE_URL

## Summary

This PR performs two independent infrastructure upgrades:
1. **Database migration** (H2 → PostgreSQL): Comprehensive, multi-file transformation affecting dependencies, config, and SQL
2. **Dependency updates**: Simple version bumps for GitHub Actions and Docker images

All changes follow clear patterns suitable for OpenRewrite automation with high confidence.
