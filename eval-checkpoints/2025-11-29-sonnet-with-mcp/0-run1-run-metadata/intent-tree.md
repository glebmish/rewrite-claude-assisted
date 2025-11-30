# Intent Tree

* Upgrade Java 17 to Java 21
  * Upgrade Java version in Gradle
    * Migrate to java toolchain configuration
      * Remove `sourceCompatibility = '17'` from build.gradle
      * Remove `targetCompatibility = '17'` from build.gradle
      * Add java toolchain section with JavaLanguageVersion.of(21) to build.gradle
  * Upgrade Gradle wrapper version
    * Change gradleVersion in wrapper block from '8.1' to '8.5' in build.gradle
  * Upgrade Docker base images
    * Change builder stage base image from eclipse-temurin:17-jdk-alpine to eclipse-temurin:21-jdk-alpine in Dockerfile
    * Change runtime stage base image from eclipse-temurin:17-jre-alpine to eclipse-temurin:21-jre-alpine in Dockerfile
  * Upgrade GitHub Actions Java version
    * Change step name from "Set up JDK 17" to "Set up JDK 21" in .github/workflows/ci.yml
    * Change java-version from '17' to '21' in actions/setup-java@v4 in .github/workflows/ci.yml
  * Update documentation
    * Change "Java 17" to "Java 21" in Technology Stack section in README.md
    * Change "Java 17" to "Java 21" in Prerequisites section in README.md
