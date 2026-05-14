plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "app.antuanjoseff.senda.gps_plugin"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-location:21.0.1")
}
