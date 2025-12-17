# native-sea-openssl-package


React Native (C++ / Prefab consumers)

If your React Native app builds native C++ code that needs to link against OpenSSL headers/libs in this AAR (for example when using a CMake `externalNativeBuild`), prefer consuming the AAR's Prefab metadata at build time rather than extracting files into source.

Two consumer options:

- Simple AAR with prebuilt .so files (no CMake integration required)

  If the AAR contains per-ABI shared libraries under `jniLibs/` and the Java/Kotlin surface you need, consumers can add the AAR directly:

  ```gradle
  dependencies {
      implementation files('node_modules/native-sea-openssl-package/android/native-sea-openssl.aar')
  }
  ```

  This works when the AAR provides `.so` files and a Java API and no additional native compilation is required in the app.

- AAR with Prefab metadata (C++ consumers who build with CMake)

  If you need to build C++ code in your app and link to OpenSSL via Prefab, use a short Gradle snippet that unpacks only the `prefab/` tree from the AAR into a build intermediate and passes that folder to CMake. Example additions to your app module `app/build.gradle`:

  ```gradle
  // allow Gradle to find the local AAR
  repositories {
      flatDir { dirs "$projectDir/../../node_modules/native-sea-openssl-package/android" }
  }

  dependencies {
      implementation(name: "native-sea-openssl-release", ext: "aar")
  }

  // unpack Prefab metadata from the AAR into an intermediates folder
  def nativeSeaAar = file("$projectDir/../../node_modules/native-sea-openssl-package/android/native-sea-openssl-release.aar")
  task unpackNativeSeaAar(type: Copy) {
      onlyIf { nativeSeaAar.exists() }
      from { zipTree(nativeSeaAar) }
      include "prefab/**"
      into "$buildDir/intermediates/nativeSeaAar"
  }
  preBuild.dependsOn unpackNativeSeaAar

  // Tell CMake where the unpacked Prefab module lives; put this under defaultConfig
  defaultConfig {
      externalNativeBuild {
          cmake {
              // Match the path your CMakeLists.txt expects
              arguments "-DOPENSSL_PREFAB_DIR=${project.buildDir}/intermediates/nativeSeaAar/prefab/modules/openssl"
          }
      }
  }
  ```

  Then in your `app/src/main/cpp/CMakeLists.txt` you can inspect `OPENSSL_PREFAB_DIR` and import the prebuilt libraries / headers from there (or fall back to `find_package(openssl CONFIG REQUIRED)` if you prefer). This approach avoids committing extracted headers/libs into source and keeps the unpacking local to the Gradle build.

If you'd like, I can add a ready-to-copy snippet for your `CMakeLists.txt` that imports `libopenssl.a` from the unpacked Prefab and sets include paths — tell me which consumption mode you prefer and I'll add it to this README or a separate example file.

CMake import snippet

Copy this example into your `app/src/main/cpp/CMakeLists.txt` (adjust `your_native_target` to the name of your native library target). It checks for the Gradle-provided `OPENSSL_PREFAB_DIR` (passed via `-DOPENSSL_PREFAB_DIR=...`) and imports the prebuilt library from the unpacked Prefab; otherwise it falls back to `find_package` for Prefab-aware setups.

```cmake
if(DEFINED OPENSSL_PREFAB_DIR)
    set(OPENSSL_PREFAB "${OPENSSL_PREFAB_DIR}")
    set(OPENSSL_INCLUDE_DIR "${OPENSSL_PREFAB}/include")
    set(OPENSSL_LIB_DIR "${OPENSSL_PREFAB}/libs/${ANDROID_ABI}")

    add_library(openssl_prebuilt STATIC IMPORTED)
    set_target_properties(openssl_prebuilt PROPERTIES
        IMPORTED_LOCATION "${OPENSSL_LIB_DIR}/libopenssl.a"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}"
    )

    target_include_directories(your_native_target PRIVATE "${OPENSSL_INCLUDE_DIR}")
    target_link_libraries(your_native_target PRIVATE openssl_prebuilt)
else()
    find_package(openssl CONFIG REQUIRED)
    target_link_libraries(your_native_target PRIVATE openssl::openssl)
endif()
```

This keeps unpacking local to the Gradle build and lets you link against the AAR's Prefab-provided headers and static libraries without committing extracted files into your source tree.
