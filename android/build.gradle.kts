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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val prj = this
    val configureSdk = {
        if (prj.plugins.hasPlugin("com.android.library") || prj.plugins.hasPlugin("com.android.application")) {
            val android = prj.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.compileSdkVersion(35)
        }
    }
    if (prj.state.executed) {
        configureSdk()
    } else {
        prj.afterEvaluate { configureSdk() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
