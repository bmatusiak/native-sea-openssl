# native-sea-openssl

This project provides scripts to build OpenSSL for Android ABIs and package an AAR containing the native `.so` files and headers for use in an Android / React Native native module.

Prerequisites:
- Android NDK installed (set `ANDROID_NDK_ROOT` or `ANDROID_NDK_HOME`)
- Java + Gradle
- `perl` and standard build tools (`make`, `gcc`) available

Quick commands:

Build OpenSSL for all ABIs (default OPENSSL_VERSION=3.0.11):

```bash
bash scripts/build-openssl.sh
```

Assemble AAR (builds OpenSSL then produces AAR):

```bash
bash scripts/package-aar.sh
```

The resulting AAR will be in `native-sea-openssl/build/outputs/aar/` and headers will be packaged inside the AAR under `assets/openssl/include`.

See `scripts/` for customization options (OpenSSL version, NDK path, ABIs).

Build variants

You can assemble Android library variants directly with Gradle:

```bash
./gradlew :native-sea-openssl:assembleDebug
./gradlew :native-sea-openssl:assembleRelease
```

The debug AAR will be at `native-sea-openssl/build/outputs/aar/native-sea-openssl-debug.aar` and the release AAR at `native-sea-openssl/build/outputs/aar/native-sea-openssl-release.aar`.

To publish the AARs (configured for GitHub Packages by environment vars), run:

```bash
./gradlew :native-sea-openssl:publish
```
