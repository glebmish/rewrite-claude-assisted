# Intent Tree - PR #3

## Strategic Goal: Migrate from H2 to PostgreSQL Database

### Gradle Dependencies Changes
* Replace H2 with PostgreSQL
  * Remove `com.h2database:h2:2.1.214` dependency
  * Add `org.postgresql:postgresql:42.6.0` dependency
* Add Testcontainers for PostgreSQL testing
  * Add `org.testcontainers:testcontainers:1.17.6` to testImplementation
  * Add `org.testcontainers:postgresql:1.17.6` to testImplementation
  * Add `org.testcontainers:junit-jupiter:1.17.6` to testImplementation

### Configuration Changes (config.yml)
* Update database driver
  * Change `driverClass` from `org.h2.Driver` to `org.postgresql.Driver`
* Update database credentials to use environment variables
  * Change `user` from `sa` to `{{ GET_ENV_VAR:DATABASE_USER }}`
  * Change `password` from empty string to `{{ GET_ENV_VAR:DATABASE_PASSWORD }}`
  * Change `url` from `jdbc:h2:mem:blog;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE` to `{{ GET_ENV_VAR:DATABASE_URL }}`
* Update Hibernate dialect
  * Change `hibernate.dialect` from `org.hibernate.dialect.H2Dialect` to `org.hibernate.dialect.PostgreSQLDialect`

### SQL Migration Changes
* Update SQL syntax for PostgreSQL compatibility
  * Change `BIGINT AUTO_INCREMENT` to `BIGSERIAL` in V1__Create_posts_table.sql

## Strategic Goal: Update Infrastructure

### Dockerfile Changes
* Update base Docker image
  * Change `FROM openjdk:17-jre-slim` to `FROM eclipse-temurin:17-jre-alpine`

### GitHub Actions Changes
* Update action versions
  * Change `actions/cache@v2` to `actions/cache@v4` in .github/workflows/ci.yml
