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
CI publishing & packaging options
--------------------------------

The repository includes a GitHub Actions workflow at `.github/workflows/release.yml` that builds OpenSSL and packages the AARs when you push a tag like `v3.0.11`. The workflow also supports manual dispatch and exposes packaging controls:

- `SKIP_OPENSSL_BUILD` (0|1) — if `1`, the script will skip running `scripts/build-openssl.sh` and use existing outputs under `third_party/openssl/<version>`.
- `SHIP_OPENSSL_SOURCE` (0|1) — if `1`, the OpenSSL source tree `third_party/src/openssl-<version>` is copied into `native-sea-openssl-package/openssl-src-<version>` for consumers.
- `SHIP_SOURCE_TO_AAR` (0|1) — if `1`, the OpenSSL source is copied into the AAR assets under `assets/openssl/src`.
- `INCLUDE_STATIC` (0|1, default 1) — control whether `.a` static archives are included in `jniLibs` and Prefab inside the AAR.
- `INCLUDE_SHARED` (0|1, default 1) — control whether `.so` shared libraries are included in `jniLibs` and Prefab.

You can trigger the workflow manually from GitHub (Actions → Build & Release AARs) and pass these inputs, or push a tag `v<openssl-version>` to trigger a tag-aligned build.

Example manual dispatch values to ship source and only static libs:

1. Go to the repo Actions → Build & Release AARs → Run workflow
2. Set `OPENSSL_VERSION` to `3.0.11`
3. Set `SHIP_OPENSSL_SOURCE` and/or `SHIP_SOURCE_TO_AAR` to `1`
4. Set `INCLUDE_SHARED` to `0` and `INCLUDE_STATIC` to `1`

