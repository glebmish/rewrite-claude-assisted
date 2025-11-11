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

        // Get FIRST-LEVEL dependencies only (matching markdown generator approach)
        // They use: recipeConf.resolvedConfiguration.firstLevelModuleDependencies
        // This gets only direct dependencies, not transitive ones
        val config = configurations.getByName(configName)
        val firstLevelJars = config.resolvedConfiguration.firstLevelModuleDependencies
            .flatMap { dep -> dep.moduleArtifacts }
            .map { it.file }
            .filter { it.name.endsWith(".jar") }

        // Also get ALL jars for the classloader (dependencies)
        val allJars = config.files.filter { it.name.endsWith(".jar") }
        val allJarPaths = allJars.map { it.toPath() }

        println("  Total JAR files in configuration: ${allJars.size}")
        println("  First-level recipe JARs to scan: ${firstLevelJars.size}")
        println()
        println("  First 10 first-level JARs:")
        firstLevelJars.take(10).forEach { println("    - ${it.name}") }
        if (firstLevelJars.size > 10) println("    ... and ${firstLevelJars.size - 10} more")

        // Create a classloader from ALL JARs (for dependencies)
        // IMPORTANT: Pass null as parent to create an isolated classloader
        // This prevents classloader conflicts between our URLClassLoader and Gradle's classloader
        val classloader = URLClassLoader(
            allJarPaths.map { it.toUri().toURL() }.toTypedArray(),
            null  // No parent - isolated classloader like markdown generator
        )

        // Use scanRuntimeClasspath() with thread context classloader
        // (scanJar() causes classloader conflicts even with thread context classloader trick)
        println()
        println("→ Scanning runtime classpath with thread context classloader...")

        val originalClassLoader = Thread.currentThread().contextClassLoader
        val env = try {
            Thread.currentThread().contextClassLoader = classloader
            Environment.builder()
                .scanRuntimeClasspath()
                .build()
        } finally {
            Thread.currentThread().contextClassLoader = originalClassLoader
        }

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
