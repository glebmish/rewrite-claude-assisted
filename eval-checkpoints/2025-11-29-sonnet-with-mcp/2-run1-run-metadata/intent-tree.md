# Intent Tree

## PR: feat: Migrate to JUnit 5, upgrade Gradle and Java version

* Upgrade Java 11 to Java 17
  * Update Java version in Gradle build configuration
    * Migrate to Java toolchain configuration
      * Remove `sourceCompatibility = JavaVersion.VERSION_11` from build.gradle:10
      * Remove `targetCompatibility = JavaVersion.VERSION_11` from build.gradle:11
      * Add `toolchain` block with `languageVersion = JavaLanguageVersion.of(17)` in build.gradle:11-13
  * Update Java version in GitHub Actions CI workflow
    * Change step name from "Set up JDK 11" to "Set up JDK 17" in .github/workflows/ci.yml:9
    * Change java-version from '11' to '17' in actions/setup-java@v3 in .github/workflows/ci.yml:13

* Upgrade Gradle wrapper version
  * Change distributionUrl from gradle-6.9-bin.zip to gradle-7.6.4-bin.zip in gradle/wrapper/gradle-wrapper.properties:3

* Migrate from JUnit 4 to JUnit 5
  * Update JUnit dependencies in build.gradle
    * Remove comment "// Testing - JUnit 4" at build.gradle:45
    * Add comment "// Testing - JUnit 5" at build.gradle:47
    * Remove `testImplementation 'junit:junit:4.13.2'` from build.gradle:47
    * Add `testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.1'` in build.gradle:49
    * Add `testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.1'` in build.gradle:50
  * Update test configuration in build.gradle
    * Replace `useJUnit()` with `useJUnitPlatform()` in test block at build.gradle:68
  * Update JUnit annotations in test files
    * Replace import `org.junit.Before` with `org.junit.jupiter.api.BeforeEach` in UserResourceTest.java:4
    * Replace import `org.junit.Test` with `org.junit.jupiter.api.Test` in UserResourceTest.java:5
    * Replace import `static org.junit.Assert.*` with `static org.junit.jupiter.api.Assertions.*` in UserResourceTest.java:7
    * Replace annotation `@Before` with `@BeforeEach` in UserResourceTest.java:104

* Update Gradle shadow plugin version
  * Change shadow plugin version from '6.1.0' to '7.1.2' in build.gradle:4

* Update Gradle application configuration
  * Replace deprecated `mainClassName` with `mainClass` in application block at build.gradle:57
  * Add explicit `mainClassName` to shadowJar block at build.gradle:64 (for shadow plugin compatibility)
