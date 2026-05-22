import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.tasks.testing.Test

plugins {
    id("com.android.library")
}

group = "com.write4me.llama_flutter_android"
version = "1.0.0"

repositories {
    google()
    mavenCentral()
}

extensions.configure<LibraryExtension>("android") {

    namespace = "com.write4me.llama_flutter_android"

    // Android 15
    compileSdk = 37

    ndkVersion = "30.0.14904198"

    defaultConfig {

        // Android 8+
        minSdk = 26

        consumerProguardFiles("consumer-rules.pro")

        ndk {
            abiFilters += listOf("arm64-v8a")
        }

        externalNativeBuild {
            cmake {

                cppFlags += listOf(
                    "-std=c++17",
                    "-O3",
                    "-fvisibility=hidden"
                )

                arguments += listOf(
                    "-DANDROID_ARM_NEON=ON",
                    "-DGGML_CPU_AARCH64=ON",
                    "-DGGML_DOTPROD=ON",

                    // 16 KB page size support
                    "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384",
                    "-DCMAKE_EXE_LINKER_FLAGS=-Wl,-z,max-page-size=16384"
                )
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

   sourceSets["main"].java.srcDir("src/main/kotlin")
   sourceSets["test"].java.srcDir("src/test/kotlin")

    externalNativeBuild {
        cmake {
            path = file("CMakeLists.txt")
            version = "3.22.1"
        }
    }

    testOptions {
        unitTests.all {
            it as Test
            it.useJUnitPlatform()
        }
    }
}


dependencies {

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")

    testImplementation(kotlin("test"))

    // JUnit 5
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.13.4")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.13.4")

    testImplementation("org.mockito:mockito-core:5.23.0")
}