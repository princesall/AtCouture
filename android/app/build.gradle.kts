import java.io.FileInputStream
import java.util.Properties

// Clés de signature du build release, lues depuis android/key.properties
// (volontairement NON versionné — voir .gitignore). Tant que ce fichier n'est
// pas présent ET correctement rempli, on retombe sur la signature debug pour ne
// pas casser `flutter build apk --release` en local ni la CI.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val declaredKeystorePath: String? = keystoreProperties.getProperty("storeFile")
val declaredKeystoreFile: File? = declaredKeystorePath?.let { path ->
    val candidate = File(path)
    if (candidate.isAbsolute) candidate else File(projectDir, path)
}

// Le keystore doit RÉELLEMENT exister. Sans cette vérification, un
// key.properties laissé au stade de modèle (storeFile = /chemin/absolu/…)
// faisait échouer `flutter build apk --release` avec une erreur Gradle peu
// explicite, au lieu de retomber proprement sur la signature debug.
val hasReleaseKeystore = keystorePropertiesFile.exists() &&
    declaredKeystoreFile != null &&
    declaredKeystoreFile.exists()

if (keystorePropertiesFile.exists() && !hasReleaseKeystore) {
    logger.warn(
        "⚠️  android/key.properties est présent mais le keystore déclaré est introuvable " +
            "($declaredKeystorePath). Le build release sera signé avec la clé DEBUG " +
            "(inutilisable sur le Play Store) — voir android/key.properties.example."
    )
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.styleconnect.styleconnect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.styleconnect.styleconnect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Signature de production. Le keystore NE DOIT JAMAIS être commité :
        // voir android/key.properties.example pour les 4 clés attendues.
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Utilise la vraie clé de release dès que android/key.properties
            // existe (obligatoire pour publier sur le Play Store) ; sinon repli
            // sur la clé debug, uniquement pour pouvoir tester un build release
            // en local et laisser la CI fonctionner.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
