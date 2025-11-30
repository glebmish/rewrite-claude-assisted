* Migrate from H2 to PostgreSQL and update dependencies
  * Update GitHub Actions dependencies
    * Upgrade actions/cache version
      * Change actions/cache version from v2 to v4 in .github/workflows/ci.yml
  * Update Docker base image
    * Change base image to Eclipse Temurin
      * Replace openjdk:17-jre-slim with eclipse-temurin:17-jre-alpine in Dockerfile
  * Migrate database from H2 to PostgreSQL
    * Update Gradle dependencies
      * Remove H2 database dependency
        * Remove com.h2database:h2:2.1.214 from build.gradle
      * Add PostgreSQL dependency
        * Add org.postgresql:postgresql:42.6.0 to build.gradle
      * Add Testcontainers dependencies for testing
        * Add org.testcontainers:testcontainers:1.17.6 to build.gradle
        * Add org.testcontainers:postgresql:1.17.6 to build.gradle
        * Add org.testcontainers:junit-jupiter:1.17.6 to build.gradle
    * Update database configuration in YAML
      * Change database driver class
        * Replace org.h2.Driver with org.postgresql.Driver in src/main/resources/config.yml
      * Update database connection properties
        * Replace user: sa with user: "{{ GET_ENV_VAR:DATABASE_USER }}" in src/main/resources/config.yml
        * Replace password: "" with password: "{{ GET_ENV_VAR:DATABASE_PASSWORD }}" in src/main/resources/config.yml
        * Replace url: jdbc:h2:mem:blog;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE with url: "{{ GET_ENV_VAR:DATABASE_URL }}" in src/main/resources/config.yml
      * Update Hibernate dialect
        * Replace hibernate.dialect: org.hibernate.dialect.H2Dialect with hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect in src/main/resources/config.yml
    * Update SQL migration scripts
      * Migrate SQL syntax from H2 to PostgreSQL
        * Replace BIGINT AUTO_INCREMENT with BIGSERIAL in src/main/resources/db/migration/V1__Create_posts_table.sql
