import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround: some 3rd-party Android library modules (in pub cache) don't declare
// an `android.namespace` which is required by recent Android Gradle Plugin versions.
// Instead of editing files in the pub cache, set a namespace on library modules
// at configuration time if one is missing.
gradle.projectsEvaluated {
    subprojects.forEach { proj ->
        try {
            if (proj.plugins.hasPlugin("com.android.library")) {
                val libExt = proj.extensions.findByType(LibraryExtension::class.java)
                if (libExt != null) {
                    val current = try { libExt.namespace ?: "" } catch (_: Exception) { "" }
                    if (current.isBlank()) {
                        val base = "com.example.note_app"
                        libExt.namespace = "${'$'}base.${'$'}{proj.name.replace('-', '_')}"
                    }
                }
            }
        } catch (_: Throwable) {
            // ignore and continue
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
