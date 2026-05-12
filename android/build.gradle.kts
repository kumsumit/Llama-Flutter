import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.write4me.llama_flutter_android"
version = "1.0.0"

repositories {
        google()
        mavenCentral()
    }

android {
    namespace = "com.write4me.llama_flutter_android"
    
    // Target Android 15 with 16KB page size support
    compileSdk = 37
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 26  // Android 8.0 (for SharedMemory support)
        
        ndk {
            abiFilters.addAll(listOf("arm64-v8a"))  // Only ARM64
        }
        
        externalNativeBuild {
            cmake {
                // Android 15 16KB page size compliance
                cppFlags += listOf(
                    "-std=c++17",
                    "-O3",
                    "-fvisibility=hidden",
                    "-Wl,-z,max-page-size=16384"
                )
                
                // ARM64 optimization flags
                arguments += listOf(
                    "-DANDROID_ARM_NEON=ON",
                    "-DGGML_CPU_AARCH64=ON",
                    "-DGGML_DOTPROD=ON"
                )
            }
        }
    }
    
    externalNativeBuild {
        cmake {
            path = file("CMakeLists.txt")
            version = "3.22.1"
        }
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()
        }
    }
}

 kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_21)
        }
    }

dependencies {
        implementation("org.jetbrains.kotlin:kotlin-stdlib:2.3.21")
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
        implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
        
        testImplementation("org.jetbrains.kotlin:kotlin-test")
        testImplementation("org.mockito:mockito-core:5.23.0")
    }    