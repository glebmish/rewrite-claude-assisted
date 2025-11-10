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

        // Debug: Check what configurations are available
        println("  Available configurations:")
        configurations.names.filter { it.contains("recipe", ignoreCase = true) || it == "runtimeClasspath" }
            .forEach { println("    - $it") }
        println()

        // Try to use the "recipe" configuration if it exists, otherwise fall back to runtimeClasspath
        val configName = if (configurations.findByName("recipe") != null) {
            println("  Using 'recipe' configuration (matches markdown generator approach)")
            "recipe"
        } else {
            println("  'recipe' configuration not found, using 'runtimeClasspath'")
            "runtimeClasspath"
        }

        // Get all JARs from the selected configuration
        val allJars = configurations.getByName(configName).files
            .filter { it.name.endsWith(".jar") }

        // Filter to only OpenRewrite recipe JARs (those that likely contain recipes)
        // Look for JARs with "rewrite" in the name
        val recipeJars = allJars.filter { jar ->
            jar.name.contains("rewrite", ignoreCase = true) ||
            jar.name.contains("moderne", ignoreCase = true)
        }.map { it.toPath() }

        // Keep all JARs for the classpath (needed for dependencies)
        val allJarPaths = allJars.map { it.toPath() }

        println("  Found ${allJars.size} total JAR files in runtimeClasspath")
        println()
        println("  First 10 JARs in runtimeClasspath:")
        allJars.take(10).forEach { println("    - ${it.name}") }
        if (allJars.size > 10) println("    ... and ${allJars.size - 10} more")
        println()
        println("  Filtering to ${recipeJars.size} recipe JARs to scan")
        recipeJars.take(10).forEach { println("    - ${it.fileName}") }
        if (recipeJars.size > 10) println("    ... and ${recipeJars.size - 10} more")

        // Create a classloader from all the JARs (for dependencies)
        val classloader = URLClassLoader(
            allJarPaths.map { it.toUri().toURL() }.toTypedArray(),
            ClassLoader.getSystemClassLoader()
        )

        // Scan only recipe JARs individually and collect all descriptors
        // This matches the approach used by rewrite-recipe-markdown-generator
        println()
        println("→ Scanning recipe JARs...")
        val envBuilder = Environment.builder()
        recipeJars.forEach { jarPath ->
            envBuilder.scanJar(jarPath, allJarPaths, classloader)
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
