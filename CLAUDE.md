# OpenRewrite Recipe Assistant

This project helps create custom OpenRewrite recipes using AI assistance to analyze PRs and generate reliable refactoring rules.

## Project Structure
- Java 21 project using Gradle
- OpenRewrite 8.37.1 framework
- JUnit 5 for testing
- Located at: `/home/glebmish/projects/rewrite-claude-assisted`

## Development Commands

### Build and Test
```bash
./gradlew build
./gradlew test
./gradlew clean build
```

### Running Tests
```bash
./gradlew test --info
```

### Check Dependencies
```bash
./gradlew dependencies
```

## Project Goals
- Analyze PRs to extract refactoring intent
- Generate custom OpenRewrite recipes
- Test recipes against original PR changes
- Minimize token usage while maintaining quality

## Key Dependencies
- `org.openrewrite:rewrite-java` - Java code transformations
- `org.openrewrite:rewrite-xml` - XML transformations  
- `org.openrewrite:rewrite-properties` - Properties file handling
- `org.openrewrite:rewrite-yaml` - YAML transformations
- `org.openrewrite:rewrite-json` - JSON transformations
- `org.openrewrite:rewrite-test` - Testing utilities

## Development Notes
- Use temporary workspace for external repositories
- Focus on token cost optimization
- Leverage existing OpenRewrite recipes where possible
- Test thoroughly before generating final recipes