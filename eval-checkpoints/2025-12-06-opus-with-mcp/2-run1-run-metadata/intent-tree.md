# Intent Tree - PR #3

## Strategic Intent: Upgrade Java 11 to Java 17 with JUnit 4 to JUnit 5 Migration

### 1. Upgrade Java Version (Java 11 → Java 17)
- **1.1 Update Gradle Build Configuration**
  - **1.1.1 Migrate to Java Toolchain**
    - Remove `sourceCompatibility = JavaVersion.VERSION_11`
    - Remove `targetCompatibility = JavaVersion.VERSION_11`
    - Add `java { toolchain { languageVersion = JavaLanguageVersion.of(17) } }`
  - **1.1.2 Update Shadow Plugin**
    - Change version from `6.1.0` to `7.1.2`
  - **1.1.3 Update Application Configuration**
    - Change `mainClassName` to `mainClass` in `application` block
    - Add `mainClassName` property in `shadowJar` block
- **1.2 Upgrade Gradle Wrapper**
  - Change `distributionUrl` from `gradle-6.9-bin.zip` to `gradle-7.6.4-bin.zip` in `gradle/wrapper/gradle-wrapper.properties`
- **1.3 Update GitHub Actions CI**
  - Change step name from "Set up JDK 11" to "Set up JDK 17" in `.github/workflows/ci.yml`
  - Change `java-version` from `'11'` to `'17'` in `.github/workflows/ci.yml`

### 2. Migrate JUnit 4 to JUnit 5
- **2.1 Update Gradle Dependencies**
  - Remove `testImplementation 'junit:junit:4.13.2'`
  - Add `testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.1'`
  - Add `testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.1'`
- **2.2 Update Test Runner Configuration**
  - Change `useJUnit()` to `useJUnitPlatform()` in `test` block
- **2.3 Update Test Source Files**
  - **2.3.1 Change Imports**
    - Replace `import org.junit.Before;` with `import org.junit.jupiter.api.BeforeEach;`
    - Replace `import org.junit.Test;` with `import org.junit.jupiter.api.Test;`
    - Replace `import static org.junit.Assert.*;` with `import static org.junit.jupiter.api.Assertions.*;`
  - **2.3.2 Update Annotations**
    - Replace `@Before` with `@BeforeEach`

## Confidence Levels
| Intent | Confidence |
|--------|------------|
| Java 11 → 17 via toolchain | High |
| Gradle 6.9 → 7.6.4 | High |
| Shadow plugin 6.1.0 → 7.1.2 | High |
| JUnit 4 → JUnit 5 migration | High |
| Test annotation changes | High |
| CI workflow updates | High |

## Patterns Identified
1. **Gradle modernization pattern**: Moving from `sourceCompatibility/targetCompatibility` to Java toolchain
2. **Gradle 7.x compatibility**: `mainClassName` → `mainClass` in application plugin
3. **JUnit 5 migration pattern**: Standard annotation and import replacements
4. **Version alignment**: All version changes are consistent with Java 17 compatibility
