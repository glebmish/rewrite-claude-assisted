/**
 * Gradle task to extract structured recipe metadata for embedding generation
 *
 * WHY THIS APPROACH:
 * ==================
 * This task is applied directly to the generator project using apply(from = "..."),
 * giving it access to the project's FULL dependency classpath, including:
 * - org.openrewrite:rewrite-java
 * - org.openrewrite:rewrite-spring
 * - org.openrewrite:rewrite-testing-frameworks
 * - org.openrewrite:rewrite-kotlin
 * - And all other recipe modules
 *
 * We use Environment.builder().scanJar() for each JAR in the runtimeClasspath
 * (matching the approach used by rewrite-recipe-markdown-generator) to ensure
 * we find ALL recipes (thousands), not just the ones in rewrite-core (~20).
 *
 * DEPENDENCIES:
 * =============
 * This script defines its own buildscript dependencies for Jackson and OpenRewrite.
 * Scripts applied with apply(from = "...") need their own buildscript block to use
 * external dependencies during compilation.
 *
 * HOW IT'S USED:
 * ==============
 * The 02b-generate-structured-data.sh script:
 * 1. Appends: apply(from = "path/to/this/file.gradle.kts") to build.gradle.kts
 * 2. Runs: ./gradlew extractRecipeMetadata -PoutputFile=/path/to/output.json
 * 3. Restores original build.gradle.kts using: git checkout -- build.gradle.kts
 *
 * This temporary modification ensures the task sees the same classpath as
 * the documentation generation task (./gradlew run).
 */

buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.openrewrite:rewrite-core:8.37.1")
        classpath("com.fasterxml.jackson.core:jackson-databind:2.18.0")
    }
}

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import org.openrewrite.config.Environment
import java.io.File
import java.net.URL
import java.net.URLClassLoader
import java.nio.file.Path

// Helper data class for JSON serialization
data class RecipeMetadata(
    val name: String,
    val displayName: String?,
    val description: String?,
    val tags: Set<String>,
    val recipeCount: Int,
    val isComposite: Boolean
)

tasks.register("extractRecipeMetadata") {
    group = "documentation"
    description = "Extract structured recipe metadata for embedding generation"

    // Make this task depend on the same dependencies as the 'run' task
    // This ensures all recipe JARs are on the classpath
    dependsOn(configurations.named("runtimeClasspath"))

    doLast {
        val outputFilePath = project.findProperty("outputFile") as String?
            ?: throw IllegalArgumentException("Property 'outputFile' must be specified (-PoutputFile=...)")

        val outputFile = File(outputFilePath)
        outputFile.parentFile?.mkdirs()

        println("========================================")
        println("Extracting Recipe Metadata")
        println("========================================")
        println("Output file: $outputFilePath")
        println()

        // Build the environment with all available recipes
        // We scan each JAR in the runtime classpath individually using scanJar()
        // This matches the approach used by rewrite-recipe-markdown-generator
        println("→ Loading OpenRewrite environment...")

        // Get all runtime classpath JARs (this includes all recipe dependencies)
        val runtimeJars = configurations.getByName("runtimeClasspath").files
            .filter { it.name.endsWith(".jar") }
            .map { it.toPath() }

        println("  Found ${runtimeJars.size} JAR files in runtimeClasspath")

        // Create a classloader from all the JARs
        val classloader = URLClassLoader(
            runtimeJars.map { it.toUri().toURL() }.toTypedArray(),
            ClassLoader.getSystemClassLoader()
        )

        // Scan each JAR individually and collect all descriptors
        // This matches the approach used by rewrite-recipe-markdown-generator
        val envBuilder = Environment.builder()
        runtimeJars.forEach { jarPath ->
            envBuilder.scanJar(jarPath, runtimeJars, classloader)
        }
        val env = envBuilder.build()

        // Get all recipe descriptors
        val allDescriptors = env.listRecipeDescriptors()
        println("✓ Found ${allDescriptors.size} recipe descriptors")
        println()

        // Extract metadata for each recipe
        println("→ Extracting metadata...")
        val metadataList = allDescriptors.map { descriptor ->
            RecipeMetadata(
                name = descriptor.name,
                displayName = descriptor.displayName,
                description = descriptor.description,
                tags = descriptor.tags ?: emptySet(),
                recipeCount = descriptor.recipeList.size,
                isComposite = descriptor.recipeList.isNotEmpty()
            )
        }

        // Write to JSON file
        println("→ Writing to JSON file...")
        val mapper = ObjectMapper()
        mapper.enable(SerializationFeature.INDENT_OUTPUT)
        mapper.writeValue(outputFile, metadataList)

        println("✓ Metadata extraction complete")
        println()
        println("========================================")
        println("Summary")
        println("========================================")
        println("Total recipes: ${metadataList.size}")
        println("Composite recipes: ${metadataList.count { it.isComposite }}")
        println("Leaf recipes: ${metadataList.count { !it.isComposite }}")
        println("Output size: ${outputFile.length() / 1024} KB")
        println()
    }
}
