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

// Plugin lama (mis. flutter_windowmanager) belum mencantumkan `namespace`.
// AGP 8.x wajib punya namespace di tiap modul library, jadi isi otomatis dengan
// `group` proyek (mis. io.adaptant.labs.flutter_windowmanager) saat plugin
// com.android.library diterapkan, bila `namespace` belum didefinisikan.
gradle.beforeProject {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        val existing = try {
            androidExt.javaClass.getMethod("getNamespace").invoke(androidExt) as? String
        } catch (_: Throwable) {
            null
        }
        if (existing.isNullOrEmpty()) {
            val fallback = group as? String
            if (!fallback.isNullOrEmpty()) {
                try {
                    androidExt.javaClass.getMethod("setNamespace", String::class.java).invoke(androidExt, fallback)
                } catch (_: Throwable) {
                    // abaikan bila getter/setter tidak tersedia
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
