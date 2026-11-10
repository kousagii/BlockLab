allprojects {
    repositories {
        google()
        mavenCentral()
        flatDir { dirs("${project(":unityLibrary").projectDir}/libs") }
    }
}
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects { layout.buildDirectory.value(newBuildDir.dir(project.name)) }
subprojects { evaluationDependsOn(":app") }
tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }
