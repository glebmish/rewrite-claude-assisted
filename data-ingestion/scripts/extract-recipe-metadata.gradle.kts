/**
 * Gradle init script to extract structured recipe metadata for embedding generation
 *
 * This script loads all OpenRewrite recipes and exports their metadata to a JSON file
 * that will be used for generating semantic embeddings.
 *
 * Usage:
 *   gradle --init-script extract-recipe-metadata.gradle.kts extractRecipeMetadata \
 *     -PoutputFile=/path/to/output.json
 */

initscript {
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
import org.openrewrite.config.RecipeDescriptor
import java.io.File

// Helper data classes for JSON serialization
data class RecipeMetadata(
    val name: String,
    val displayName: String?,
    val description: String?,
    val tags: Set<String>,
    val recipeCount: Int,  // Number of sub-recipes (0 for leaf recipes)
    val isComposite: Boolean
)

// Register a custom task to extract recipe metadata
gradle.rootProject {
    tasks.register("extractRecipeMetadata") {
        group = "documentation"
        description = "Extract structured recipe metadata for embedding generation"

        doLast {
            val outputFilePath = project.findProperty("outputFile") as String?
                ?: throw IllegalArgumentException("Property 'outputFile' must be specified")

            val outputFile = File(outputFilePath)
            outputFile.parentFile?.mkdirs()

            println("========================================")
            println("Extracting Recipe Metadata")
            println("========================================")
            println("Output file: $outputFilePath")
            println()

            // Build the environment with all available recipes
            println("→ Loading OpenRewrite environment...")
            val env = Environment.builder()
                .scanRuntimeClasspath()
                .build()

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
}
