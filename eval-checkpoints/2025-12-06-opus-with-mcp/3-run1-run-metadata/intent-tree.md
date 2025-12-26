# Intent Tree: PR #3 - Dropwizard 3 Upgrade

## Strategic Goal: Upgrade to Dropwizard 3.0.0 [HIGH CONFIDENCE]

### 1. Upgrade Java Version in Gradle [HIGH CONFIDENCE]
* Change Java toolchain version
  * Change `JavaLanguageVersion.of(11)` to `JavaLanguageVersion.of(17)` in build.gradle

### 2. Upgrade Dropwizard Dependencies [HIGH CONFIDENCE]
* Update Dropwizard version from 2.1.12 to 3.0.0
  * Change `io.dropwizard:dropwizard-core:2.1.12` to `io.dropwizard:dropwizard-core:3.0.0`
  * Change `io.dropwizard:dropwizard-jdbi3:2.1.12` to `io.dropwizard:dropwizard-jdbi3:3.0.0`
  * Change `io.dropwizard:dropwizard-auth:2.1.12` to `io.dropwizard:dropwizard-auth:3.0.0`
  * Change `io.dropwizard:dropwizard-configuration:2.1.12` to `io.dropwizard:dropwizard-configuration:3.0.0`
  * Change `io.dropwizard:dropwizard-testing:2.1.12` to `io.dropwizard:dropwizard-testing:3.0.0`

### 3. Update Dropwizard Core Import Statements [HIGH CONFIDENCE]
* Change package imports from `io.dropwizard` to `io.dropwizard.core`
  * Change `import io.dropwizard.Application` to `import io.dropwizard.core.Application`
  * Change `import io.dropwizard.setup.Bootstrap` to `import io.dropwizard.core.setup.Bootstrap`
  * Change `import io.dropwizard.setup.Environment` to `import io.dropwizard.core.setup.Environment`
  * Change `import io.dropwizard.Configuration` to `import io.dropwizard.core.Configuration`

### 4. Remove @Override Annotations from Application Methods [HIGH CONFIDENCE]
* Remove `@Override` annotation from `initialize(Bootstrap<TaskConfiguration> bootstrap)` method
* Remove `@Override` annotation from `run(TaskConfiguration configuration, Environment environment)` method

---

## Files Changed
- `build.gradle` - Version updates
- `src/main/java/com/example/tasks/TaskApplication.java` - Import changes, @Override removals
- `src/main/java/com/example/tasks/TaskConfiguration.java` - Import change

## Confidence Summary
- All intents: HIGH CONFIDENCE - Clear, unambiguous changes visible in diff
