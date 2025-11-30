# Intent Tree

## Strategic Goal
* Upgrade Dropwizard from version 2.1.12 to version 3.0.0

## Tactical Goals

### Update Java version in Gradle build configuration
* Change Java toolchain version
  * Change `languageVersion` from `JavaLanguageVersion.of(11)` to `JavaLanguageVersion.of(17)` in build.gradle

### Update Dropwizard dependency versions in build.gradle
* Change Dropwizard core dependencies from 2.1.12 to 3.0.0
  * Change `io.dropwizard:dropwizard-core` from version 2.1.12 to 3.0.0
  * Change `io.dropwizard:dropwizard-jdbi3` from version 2.1.12 to 3.0.0
  * Change `io.dropwizard:dropwizard-auth` from version 2.1.12 to 3.0.0
  * Change `io.dropwizard:dropwizard-configuration` from version 2.1.12 to 3.0.0
  * Change `io.dropwizard:dropwizard-testing` from version 2.1.12 to 3.0.0

### Migrate Dropwizard package imports in Java source files
* Update Dropwizard core package imports
  * Change import from `io.dropwizard.Application` to `io.dropwizard.core.Application` in TaskApplication.java
  * Change import from `io.dropwizard.setup.Bootstrap` to `io.dropwizard.core.setup.Bootstrap` in TaskApplication.java
  * Change import from `io.dropwizard.setup.Environment` to `io.dropwizard.core.setup.Environment` in TaskApplication.java
  * Change import from `io.dropwizard.Configuration` to `io.dropwizard.core.Configuration` in TaskConfiguration.java

### Remove @Override annotations from specific methods
* Remove @Override annotation from initialize() method in TaskApplication.java
* Remove @Override annotation from run() method in TaskApplication.java
