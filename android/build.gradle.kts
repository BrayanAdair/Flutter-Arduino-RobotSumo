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

// flutter_bluetooth_serial fija compileSdkVersion 30 en su propio build.gradle,
// anterior a la API 31 donde se agrego android:attr/lStar. Una dependencia de
// Material mas reciente arrastrada por la app si lo referencia, y eso rompe
// solo los builds --release (verifyReleaseResources es estricto; debug no).
// El modulo :app ya trae su compileSdk correcto via flutter.compileSdkVersion,
// asi que se excluye para no chocar con el bloqueo de AGP ("too late to set
// compileSdk") que ocurre porque su evaluacion se fuerza temprano.
subprojects {
    if (project.name == "app") return@subprojects
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.compileSdkVersion(34)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
