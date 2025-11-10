buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        // Only Jackson for JSON serialization - NO OpenRewrite dependencies!
        classpath("com.fasterxml.jackson.core:jackson-databind:2.18.0")
    }
}

import com.fasterxml.jackson.databind.ObjectMapper

/**
 * Custom task that extracts recipe metadata using rewrite-gradle-plugin.
 *
 * KEY INSIGHT: We CANNOT import RecipeDescriptor because that would load it
 * in the wrong classloader. We must use pure reflection to extract data as
 * primitives (String, List, Map) that can cross the classloader boundary.
 */
tasks.register("extractRecipeMetadata") {
    group = "rewrite"
    description = "Extract detailed metadata for all discovered recipes"

    dependsOn(configurations.getByName("rewrite"))

    doLast {
        println("Extracting recipe metadata using rewrite-gradle-plugin infrastructure...")

        // Get the wrapped parser from the plugin (it's in the isolated classloader)
        val rewriteDiscoverTask = tasks.getByName("rewriteDiscover")
        val projectParserGetter = rewriteDiscoverTask.javaClass.getDeclaredMethod("getProjectParser")
        projectParserGetter.isAccessible = true
        val delegatingParser = projectParserGetter.invoke(rewriteDiscoverTask)

        val gppField = delegatingParser.javaClass.getDeclaredField("gpp")
        gppField.isAccessible = true
        val actualParser = gppField.get(delegatingParser)

        // Get recipe descriptors - they are in the isolated classloader!
        val listRecipeDescriptorsMethod = actualParser.javaClass.getMethod("listRecipeDescriptors")
        val recipeDescriptors = listRecipeDescriptorsMethod.invoke(actualParser) as Collection<*>

        println("✓ Found ${recipeDescriptors.size} recipe descriptors")

        // Extract data using pure reflection - never cast to RecipeDescriptor!
        val recipes = recipeDescriptors.map { descriptorObj ->
            // Use reflection to access fields
            val descriptorClass = descriptorObj!!.javaClass

            // Extract basic fields
            val name = descriptorClass.getMethod("getName").invoke(descriptorObj) as String
            val displayName = descriptorClass.getMethod("getDisplayName").invoke(descriptorObj) as String
            val description = descriptorClass.getMethod("getDescription").invoke(descriptorObj) as String
            val tags = descriptorClass.getMethod("getTags").invoke(descriptorObj) as Set<*>
            val estimatedEffort = descriptorClass.getMethod("getEstimatedEffortPerOccurrence").invoke(descriptorObj)

            // Extract options list
            val optionsList = descriptorClass.getMethod("getOptions").invoke(descriptorObj) as List<*>
            val options = optionsList.map { optionObj ->
                if (optionObj == null) return@map emptyMap<String, Any?>()

                val optionClass = optionObj.javaClass
                mapOf(
                    "name" to optionClass.getMethod("getName").invoke(optionObj),
                    "type" to optionClass.getMethod("getType").invoke(optionObj),
                    "displayName" to optionClass.getMethod("getDisplayName").invoke(optionObj),
                    "description" to optionClass.getMethod("getDescription").invoke(optionObj),
                    "example" to optionClass.getMethod("getExample").invoke(optionObj),
                    "valid" to optionClass.getMethod("getValid").invoke(optionObj),
                    "value" to optionClass.getMethod("getValue").invoke(optionObj)
                )
            }

            // Extract recipe list
            val recipeListObjs = descriptorClass.getMethod("getRecipeList").invoke(descriptorObj) as List<*>
            val recipeList = recipeListObjs.map { recipeDescObj ->
                if (recipeDescObj == null) return@map null
                recipeDescObj.javaClass.getMethod("getName").invoke(recipeDescObj) as String
            }.filterNotNull()

            // Build map with primitives only - safe to cross classloader boundary
            mapOf(
                "name" to name,
                "displayName" to displayName,
                "description" to description,
                "tags" to tags.map { it.toString() },
                "estimatedEffortPerOccurrence" to estimatedEffort?.toString(),
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

        // Write to JSON
        val outputFile = project.layout.buildDirectory.file("recipe-metadata.json").get().asFile
        outputFile.parentFile.mkdirs()

        val mapper = ObjectMapper()
        mapper.writerWithDefaultPrettyPrinter().writeValue(outputFile, recipes)

        println("✓ Metadata written to: ${outputFile.absolutePath}")
    }
}
