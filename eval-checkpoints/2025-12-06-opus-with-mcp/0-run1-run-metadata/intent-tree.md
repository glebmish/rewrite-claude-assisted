# Intent Tree: PR #2 - Java 17 to Java 21 Upgrade

## Strategic Goal
* Upgrade Java 17 to Java 21

## Intent Tree

* Upgrade Java 17 to Java 21 [HIGH CONFIDENCE]
  * Upgrade Java version in Gradle build configuration [HIGH]
    * Migrate from sourceCompatibility/targetCompatibility to Java toolchain [HIGH]
      * Remove `sourceCompatibility = '17'` from build.gradle
      * Remove `targetCompatibility = '17'` from build.gradle
      * Add `java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }` block to build.gradle
    * Upgrade Gradle wrapper version [HIGH]
      * Change `gradleVersion` from '8.1' to '8.5' in wrapper block in build.gradle
  * Upgrade Docker base images [HIGH]
    * Update builder stage base image [HIGH]
      * Change `FROM eclipse-temurin:17-jdk-alpine` to `FROM eclipse-temurin:21-jdk-alpine` in Dockerfile
    * Update runtime stage base image [HIGH]
      * Change `FROM eclipse-temurin:17-jre-alpine` to `FROM eclipse-temurin:21-jre-alpine` in Dockerfile
  * Upgrade GitHub Actions CI workflow [HIGH]
    * Update Java version in setup-java action [HIGH]
      * Change step name from "Set up JDK 17" to "Set up JDK 21" in .github/workflows/ci.yml
      * Change `java-version: '17'` to `java-version: '21'` in .github/workflows/ci.yml
  * Update documentation [HIGH]
    * Update README.md Java version references [HIGH]
      * Change "Java: Java 17" to "Java: Java 21" in Technology Stack section
      * Change "Java 17" to "Java 21" in Prerequisites section

## Patterns Identified

1. **Consistent version change**: All occurrences of "17" related to Java are changed to "21"
2. **Modern Gradle configuration**: Uses Java toolchain instead of deprecated sourceCompatibility/targetCompatibility
3. **Multi-file coordination**: Changes span Dockerfile, CI, build.gradle, and README

## Potential Automation Challenges

1. **Gradle toolchain migration**: Structural change from property assignment to nested block requires careful handling
2. **Text-based changes in README**: Require text/markdown processing, not just code transformation
3. **Docker FROM instruction**: Requires Dockerfile-aware recipe or text-based transformation
4. **GitHub Actions YAML**: Requires YAML-aware transformation

## Edge Cases

- No edge cases identified - changes are straightforward version number updates
