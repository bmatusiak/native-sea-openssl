react-native-native-sea-openssl

This package provides a prebuilt OpenSSL AAR produced by the `native-sea-openssl` project and a tiny JS wrapper.

Included artifact
- `android/native-sea-openssl.aar` — AAR built from `native-sea-openssl` containing per-ABI `.so` under `jniLibs` and headers under `assets/openssl`.

Quick install (local, using the included AAR)

1. From your app repo install this package (local path for development):

   npm install --save /path/to/native-sea-openssl/react-native-native-sea-openssl

2. In your Android app module `build.gradle` add the dependency pointing at the AAR file shipped in `node_modules`:

   dependencies {
     implementation files('node_modules/react-native-native-sea-openssl/android/native-sea-openssl.aar')
   }

3. Rebuild your Android app. The AAR contains the per-ABI `.so` files and headers; no extra native build steps are required.

Recommended production approach (preferred)

Publish the AAR to GitHub Packages (Maven) and let Gradle fetch it during the app build. This is cleaner for CI and consumers.

Default Maven coordinates used by CI and `native-sea-openssl/build.gradle`:

- GroupId: `com.example`
- ArtifactId: `native-sea-openssl`
- Version: `3.0.11`

If published to GitHub Packages the Maven repo URL is:

```
https://maven.pkg.github.com/<GITHUB_OWNER>/<REPO>
```

Example `android/build.gradle` repository + dependency configuration for a consumer app:

```gradle
allprojects {
    repositories {
        maven {
            url = uri("https://maven.pkg.github.com/<GITHUB_OWNER>/<REPO>")
            credentials {
                username = project.findProperty('gpr.user') ?: System.getenv('GITHUB_ACTOR')
                password = project.findProperty('gpr.key') ?: System.getenv('GITHUB_TOKEN')
            }
        }
        // other repos: mavenCentral(), google(), etc.
    }
}

dependencies {
    implementation 'com.example:native-sea-openssl:3.0.11'
}
```

Notes about GitHub Packages
- The CI workflow in this repo publishes the AAR to `https://maven.pkg.github.com/<owner>/<repo>` when you push a tag (see `.github/workflows/publish-aar.yml`). Gradle consumes it using the credentials shown above.

Alternative (npm-hosted AAR — easier but heavier)

- You can publish this JS package to npm with the AAR included under `android/`. Consumers then `npm install react-native-native-sea-openssl` and use the `implementation files('node_modules/.../native-sea-openssl.aar')` approach shown in Quick install. This works but places binaries in npm rather than Maven and is less ideal for large-scale CI.

Exposing native APIs to JS

This package currently ships the AAR only. To call OpenSSL from React Native you should implement a Java/Kotlin native module inside this package that wraps the APIs you need (and include it in the AAR) — then the JS `index.js` will import the native module and surface JS-friendly functions.

Next steps I can help with
- Implement a simple Java/Kotlin native module that exposes a small OpenSSL API surface and include it in the AAR.
- Update `groupId`/`artifactId`/`version` in `native-sea-openssl/build.gradle` if you want different coordinates before publishing.

If you'd like, I can also prepare a short example React Native app that demonstrates `implementation files('node_modules/...')` and a second example that consumes the published Maven artifact.
