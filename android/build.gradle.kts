allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)

    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker 11.0.3 picks its Kotlin setup from the AGP major version alone
// and ignores `android.builtInKotlin`. Under AGP 9 with the Flutter template's
// builtInKotlin=false it therefore applies neither KGP nor built-in Kotlin.
// Apply KGP for that one module, including the jvmTarget its own script skips
// on AGP 9.
//
// Drop this once file_picker guards on `android.builtInKotlin`, as
// app_badge_plus already does.
subprojects {
    if (name == "file_picker") {
        plugins.withId("com.android.library") {
            apply(plugin = "org.jetbrains.kotlin.android")

            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}