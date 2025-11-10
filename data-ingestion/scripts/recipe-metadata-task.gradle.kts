/**
 * Gradle task file to extract structured recipe metadata for embedding generation
 *
 * This is NOT an init script - it should be applied to the generator project
 * so it has access to all the project's recipe dependencies.
 *
 * Usage in the generator project's build.gradle.kts:
 *   apply(from = "path/to/recipe-metadata-task.gradle.kts")
 *
 * Then run:
 *   ./gradlew extractRecipeMetadata -PoutputFile=/path/to/output.json
 */

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.SerializationFeature
import org.openrewrite.config.Environment
import java.io.File

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
        // This will scan the runtime classpath which includes all the project dependencies
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
