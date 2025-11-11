/**
 * Gradle task to extract structured recipe metadata using the markdown generator's approach
 *
 * WHY THIS APPROACH:
 * ==================
 * This implementation follows the official rewrite-recipe-markdown-generator approach:
 * - Creates an isolated URLClassLoader with all recipe JARs
 * - Uses Environment.scanJar() to discover recipes from each first-level JAR
 * - Extracts metadata using RecipeDescriptor.listRecipeDescriptors()
 * - NO dependency on rewrite-gradle-plugin internals
 * - Stable, documented, and officially supported approach
 *
 * KEY DIFFERENCES FROM OLD IMPLEMENTATION:
 * ========================================
 * OLD: Used reflection to hack into rewrite-gradle-plugin's internal classloader
 * NEW: Creates our own isolated classloader and uses public Environment API
 *
 * This matches how the markdown generator works (see RecipeLoader.kt in that repo)
 *
 * DEPENDENCIES:
 * =============
 * Requires rewrite-core for Environment and RecipeDescriptor classes
 * Requires Jackson for JSON serialization
 * Requires the "recipe" configuration with all recipe modules
 *
 * HOW IT'S USED:
 * ==============
 * The 02b-generate-structured-data.sh script runs: ./gradlew extractRecipeMetadata
 * The task reads from "recipe" configuration and outputs JSON to build/recipe-metadata.json
 */

buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        // OpenRewrite core for Environment and RecipeDescriptor
        // IMPORTANT: Must match the version used by the markdown generator (8.64.0)
        // Version mismatch causes recipe validation errors
        classpath("org.openrewrite:rewrite-core:8.64.0")
        // Jackson for JSON serialization
        classpath("com.fasterxml.jackson.core:jackson-databind:2.18.0")
    }
}

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import org.openrewrite.config.Environment
import java.net.URL
import java.net.URLClassLoader
import java.nio.file.Path

tasks.register("extractRecipeMetadata") {
    group = "documentation"
    description = "Extract structured recipe metadata using isolated classloader approach"

    // Depend on the recipe configuration being resolved
    val recipeConfig = configurations.findByName("recipe")
        ?: throw IllegalStateException("'recipe' configuration not found. Ensure it's created in build.gradle.kts")

    dependsOn(recipeConfig)

    doLast {
        val outputFile = project.layout.buildDirectory.file("recipe-metadata.json").get().asFile
        outputFile.parentFile?.mkdirs()

        println("========================================")
        println("Extracting Recipe Metadata")
        println("========================================")
        println("Output file: ${outputFile.absolutePath}")
        println()

        // Get first-level recipe JARs (modules we directly depend on)
        val firstLevelJars = recipeConfig.resolvedConfiguration.firstLevelModuleDependencies
            .flatMap { dep -> dep.moduleArtifacts }
            .map { it.file }
            .filter { it.name.endsWith(".jar") }

        // Get ALL JARs including transitive dependencies for the classloader
        val allJars = recipeConfig.files.filter { it.name.endsWith(".jar") }

        println("→ Loading recipes from ${firstLevelJars.size} first-level modules")
        println("  (${allJars.size} total JARs including transitive dependencies)")
        println()

        // Log first few JARs for debugging
        println("  First 10 first-level JARs:")
        firstLevelJars.take(10).forEach { println("    - ${it.name}") }
        if (firstLevelJars.size > 10) {
            println("    ... and ${firstLevelJars.size - 10} more")
        }
        println()

        // Create URLClassLoader with all JARs
        // IMPORTANT: Use buildscript classloader as parent!
        // In Gradle task context, buildscript classes (Recipe, Environment, etc.)
        // must be shared between our classloader and recipe classloader.
        // The markdown generator uses null parent because it runs standalone,
        // but in Gradle we need to share buildscript classes.
        val buildscriptClassLoader = org.openrewrite.config.Environment::class.java.classLoader
        val classloader = URLClassLoader(
            allJars.map { it.toURI().toURL() }.toTypedArray(),
            buildscriptClassLoader  // Use buildscript classloader as parent
        )

        println("→ Scanning JARs for recipes...")

        // Collect all recipe descriptors by scanning each first-level JAR
        // This matches the approach in RecipeLoader.kt:75-102
        val allRecipeDescriptors = firstLevelJars.flatMap { jarFile ->
            try {
                // Create a separate environment for each JAR
                val jarPath = jarFile.toPath()
                val allJarPaths = allJars.map { it.toPath() }

                // Use Environment.scanJar() with dependencies and classloader
                // This is the documented, stable API for recipe discovery
                val env = Environment.builder()
                    .scanJar(jarPath, allJarPaths, classloader)
                    .build()

                val descriptors = env.listRecipeDescriptors()
                println("  ✓ ${jarFile.name}: ${descriptors.size} recipes")

                descriptors
            } catch (e: Exception) {
                println("  ✗ ${jarFile.name}: Failed to scan - ${e.message}")
                emptyList()
            }
        }

        println()
        println("✓ Found ${allRecipeDescriptors.size} total recipe descriptors")
        println()

        // Extract metadata from descriptors
        // We use Maps instead of data classes to avoid classloader issues
        println("→ Extracting metadata...")
        val metadataList = allRecipeDescriptors.map { descriptor ->
            // Extract option metadata
            val options = descriptor.options.map { option ->
                mapOf(
                    "name" to option.name,
                    "type" to option.type,
                    "displayName" to option.displayName,
                    "description" to option.description,
                    "example" to option.example?.toString(),
                    "valid" to option.valid?.toString(),
                    "required" to option.isRequired,
                    "value" to option.value?.toString()
                )
            }

            // Extract recipe list (for composite recipes)
            val recipeList = descriptor.recipeList.map { it.name }

            // Build metadata map with all fields
            mapOf(
                "name" to descriptor.name,
                "displayName" to descriptor.displayName,
                "description" to descriptor.description,
                "tags" to descriptor.tags.toList(),
                "estimatedEffortPerOccurrence" to descriptor.estimatedEffortPerOccurrence?.toString(),
                "options" to options,
                "recipeList" to recipeList,
                "recipeCount" to recipeList.size,
                "isComposite" to recipeList.isNotEmpty()
            )
        }

        // Write to JSON file
        println("→ Writing to JSON file...")
        val mapper = ObjectMapper()
        mapper.enable(SerializationFeature.INDENT_OUTPUT)
        mapper.writeValue(outputFile, metadataList)

        // Statistics
        val compositeRecipes = metadataList.count { it["isComposite"] as Boolean }
        val leafRecipes = metadataList.count { !(it["isComposite"] as Boolean) }

        println("✓ Metadata extraction complete")
        println()
        println("========================================")
        println("Summary")
        println("========================================")
        println("Total recipes: ${metadataList.size}")
        println("Composite recipes: $compositeRecipes")
        println("Leaf recipes: $leafRecipes")
        println("Output size: ${outputFile.length() / 1024} KB")
        println()

        if (metadataList.isEmpty()) {
            throw GradleException("No recipes found! Check that 'recipe' configuration has dependencies")
        }
    }
}
