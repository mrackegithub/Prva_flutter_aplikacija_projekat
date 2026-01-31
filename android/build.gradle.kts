buildscript {
    val kotlin_version: String by extra { "2.1.0" } // Koristi ovu sintaksu za definisanje extra property
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0") // Ažuriraj na stabilnu verziju
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version") // Sada koristi $kotlin_version
        classpath("com.google.gms:google-services:4.4.2") // Ako koristiš Firebase
        // Dodaj druge classpath ako trebaš (npr. za Hilt, itd.)
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory - premesti build iz android/build u root/build (../../build iz perspektive android/)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir) // Koristi .set umesto .value (bolje u novijim Gradle)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ukloni ovo ako nemaš multi-module setup izvan :app - u standardnom Flutteru nije potrebno
// subprojects {
//     project.evaluationDependsOn(":app")
// }

// Custom clean task da briše custom build dir
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}