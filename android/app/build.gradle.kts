plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // O plugin Flutter precisa vir depois dos plugins do Android e Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.triplice.cadastro_clientes_final"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.triplice.cadastro_clientes_final"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true   // ✅ sintaxe correta no .kts
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ bloco dependencies deve vir no final do arquivo
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
