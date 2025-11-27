# Phase 2: Intent Extraction

## PR Information
- **URL**: https://github.com/openrewrite-assist-testing-dataset/simple-blog-platform/pull/3
- **Title**: feat: Migrate from H2 to PostgreSQL and bump GH actions
- **Base Branch**: master
- **PR Branch**: feature/upgrade

## Strategic Intent (High-Level Goal)
Migrate database from H2 to PostgreSQL and update CI/CD infrastructure

## Tactical Intents Tree

### 1. Migrate database from H2 to PostgreSQL
**Confidence**: High

#### 1.1 Update Gradle dependencies
- **1.1.1** Remove H2 database dependency `com.h2database:h2:2.1.214` from build.gradle
- **1.1.2** Add PostgreSQL JDBC driver dependency `org.postgresql:postgresql:42.6.0` to build.gradle
- **1.1.3** Add Testcontainers dependencies for PostgreSQL testing:
  - `org.testcontainers:testcontainers:1.17.6`
  - `org.testcontainers:postgresql:1.17.6`
  - `org.testcontainers:junit-jupiter:1.17.6`

#### 1.2 Update database configuration in YAML
- **1.2.1** Change `driverClass` from `org.h2.Driver` to `org.postgresql.Driver` in src/main/resources/config.yml
- **1.2.2** Change `hibernate.dialect` from `org.hibernate.dialect.H2Dialect` to `org.hibernate.dialect.PostgreSQLDialect` in config.yml
- **1.2.3** Replace hardcoded H2 connection properties with environment variable placeholders:
  - `user: sa` → `user: "{{ GET_ENV_VAR:DATABASE_USER }}"`
  - `password: ""` → `password: "{{ GET_ENV_VAR:DATABASE_PASSWORD }}"`
  - `url: jdbc:h2:mem:blog;...` → `url: "{{ GET_ENV_VAR:DATABASE_URL }}"`

#### 1.3 Update SQL migration scripts
- **1.3.1** Change auto-increment syntax from H2 to PostgreSQL in V1__Create_posts_table.sql:
  - `id BIGINT AUTO_INCREMENT PRIMARY KEY` → `id BIGSERIAL PRIMARY KEY`

#### 1.4 Update Docker configuration
- **1.4.1** Change base image from `openjdk:17-jre-slim` to `eclipse-temurin:17-jre-alpine` in Dockerfile

### 2. Update GitHub Actions infrastructure
**Confidence**: High

#### 2.1 Bump GitHub Actions versions
- **2.1.1** Update `actions/cache` from v2 to v4 in .github/workflows/ci.yml

## Pattern Analysis

### Pattern 1: Database Driver Replacement
- **Type**: Dependency swap + configuration update
- **Scope**: Multiple files (build.gradle, config.yml, SQL scripts)
- **Consistency**: All H2 references replaced with PostgreSQL equivalents
- **Exceptions**: None detected

### Pattern 2: Configuration Security Enhancement
- **Type**: Hardcoded credentials replacement
- **Scope**: config.yml
- **Consistency**: All database credentials moved to environment variables
- **Exceptions**: None

### Pattern 3: SQL Dialect Translation
- **Type**: Syntax transformation
- **Scope**: SQL migration files
- **Consistency**: H2-specific syntax replaced with PostgreSQL equivalents
- **Note**: Only AUTO_INCREMENT → BIGSERIAL transformation visible in this PR

### Pattern 4: Container Image Modernization
- **Type**: Base image update
- **Scope**: Dockerfile
- **Consistency**: Single change from deprecated OpenJDK image to Temurin

### Pattern 5: GitHub Actions Version Bump
- **Type**: Action version update
- **Scope**: GitHub workflows
- **Consistency**: Single action updated (cache v2 → v4)

## OpenRewrite Mapping Considerations

### Multi-Language Transformation Requirements
1. **Gradle (Groovy)**: Dependency management changes
2. **YAML**: Configuration property updates
3. **SQL**: Dialect-specific syntax transformations
4. **Dockerfile**: Base image replacement
5. **GitHub Actions YAML**: Action version updates

### Preconditions Needed
- Project uses Dropwizard framework
- Current database is H2
- Target database is PostgreSQL
- Uses Flyway/Liquibase migrations
- Has GitHub Actions CI/CD

### Potential Challenges for Automation
1. **Environment variable placeholder syntax**: The template syntax `{{ GET_ENV_VAR:VAR_NAME }}` is non-standard and may be application-specific
2. **SQL migration completeness**: Only one migration file visible; may need analysis of all SQL files
3. **Docker image selection**: Choice of eclipse-temurin:17-jre-alpine is opinionated (alpine vs slim, temurin vs others)
4. **Testcontainers integration**: Requires understanding of existing test structure

## Confidence Levels
- Database migration intent: **High** (clear, consistent changes)
- Configuration externalization: **High** (explicit pattern)
- SQL dialect translation: **Medium** (limited visibility of all migrations)
- Container modernization: **High** (straightforward replacement)
- GitHub Actions update: **High** (simple version bump)
