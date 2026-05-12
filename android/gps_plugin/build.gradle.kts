plugins {
    // CANVI: Un plugin ha de ser una llibreria, no una aplicació
    id("com.android.library")
    id("kotlin-android")
    // El plugin de Flutter NO s'aplica normalment dins d'un sub-plugin local d'aquesta manera
}

android {
    // Manté el teu namespace únic per al plugin
    namespace = "app.antuanjoseff.gpxgo.gps_plugin"
    
    // Utilitzem versions estàndard o les definides al projecte arrel
    compileSdk = 34 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // ELIMINAT: Un plugin (library) no pot tenir applicationId
        minSdk = 21 
        // Les versions de Flutter se solen heretar o definir manualment aquí
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-location:21.0.1")
    
    // En lloc d'una versió fixa, demanem a Flutter que ens doni el seu fitxer de compilació
    compileOnly(files("${project.rootDir}/../build/app/intermediates/flutter/release/libs.jar")) 
    // O millor encara, utilitzem l'accés estàndard per a plugins:
    implementation(files(org.gradle.internal.os.OperatingSystem.current().isWindows() 
        ?.let { "C:/flutter/bin/cache/artifacts/engine/android-arm64/flutter.jar" } // Això és massa complex
        ?: "")) 
}
