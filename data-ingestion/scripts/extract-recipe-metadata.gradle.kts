buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("org.openrewrite:rewrite-core:8.64.0")
        classpath("com.fasterxml.jackson.core:jackson-databind:2.18.0")
    }
}

import com.fasterxml.jackson.databind.ObjectMapper
import org.openrewrite.config.RecipeDescriptor
import org.gradle.internal.service.ServiceRegistry

/**
 * Custom task that leverages rewrite-gradle-plugin's infrastructure
 * to discover all recipes and extract their metadata.
 *
 * This task uses the plugin's proper classloader isolation to avoid
 * conflicts and discover all ~4939 recipes.
 */
tasks.register("extractRecipeMetadata") {
    group = "rewrite"
    description = "Extract detailed metadata for all discovered recipes"

    // Depend on rewrite configuration to ensure all dependencies are resolved
    dependsOn(configurations.getByName("rewrite"))

    doLast {
        println("Extracting recipe metadata using rewrite-gradle-plugin infrastructure...")

        // Get the project parser from the rewrite plugin
        // This uses the plugin's proper classloader isolation
        val rewriteDiscoverTask = tasks.getByName("rewriteDiscover")
        val projectParserGetter = rewriteDiscoverTask.javaClass.getDeclaredMethod("getProjectParser")
        projectParserGetter.isAccessible = true
        val projectParser = projectParserGetter.invoke(rewriteDiscoverTask)

        // Get recipe descriptors using the plugin's infrastructure
        val listRecipeDescriptorsMethod = projectParser.javaClass.getMethod("listRecipeDescriptors")
        @Suppress("UNCHECKED_CAST")
        val recipeDescriptors = listRecipeDescriptorsMethod.invoke(projectParser) as Collection<RecipeDescriptor>

        println("✓ Found ${recipeDescriptors.size} recipe descriptors")

        // Convert to JSON-friendly format
        val recipes = recipeDescriptors.map { descriptor ->
            val options = descriptor.options.map { option ->
                mapOf(
                    "name" to option.name,
                    "type" to option.type,
                    "displayName" to option.displayName,
                    "description" to option.description,
                    "example" to option.example,
                    "valid" to option.valid,
                    "required" to option.required,
                    "value" to option.value
                )
            }

            val recipeList = descriptor.recipeList.map { it.name }

            mapOf(
                "name" to descriptor.name,
                "displayName" to descriptor.displayName,
                "description" to descriptor.description,
                "tags" to descriptor.tags,
                "estimatedEffortPerOccurrence" to descriptor.estimatedEffortPerOccurrence?.toString(),
                "causesAnotherCycle" to descriptor.causesAnotherCycle,
                "options" to options,
                "recipeList" to recipeList
            )
        }

        // Statistics
        val compositeRecipes = recipes.filter { (it["recipeList"] as List<*>).isNotEmpty() }
        val leafRecipes = recipes.filter { (it["recipeList"] as List<*>).isEmpty() }

        println("Total recipes: ${recipes.size}")
        println("Composite recipes: ${compositeRecipes.size}")
        println("Leaf recipes: ${leafRecipes.size}")

        // Write to JSON file
        val outputFile = project.layout.buildDirectory.file("recipe-metadata.json").get().asFile
        outputFile.parentFile.mkdirs()

        val mapper = ObjectMapper()
        mapper.writerWithDefaultPrettyPrinter().writeValue(outputFile, recipes)

        println("✓ Metadata written to: ${outputFile.absolutePath}")
    }
}
