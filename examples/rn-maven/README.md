Example React Native (Android) — Maven (GitHub Packages) consumption

This example demonstrates consuming the published AAR from a Maven repository (recommended for CI/production).

Prerequisites
- The AAR is published to GitHub Packages for this repository (CI workflow is included in `.github/workflows/publish-aar.yml`).

Example `android/build.gradle` (add the GitHub Packages repo):

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
        google()
        mavenCentral()
    }
}
```

In your app module `android/app/build.gradle` add the dependency using the published coordinates:

```gradle
dependencies {
    implementation 'com.example:native-sea-openssl:3.0.11'
}
```

Notes
- Using Maven allows Gradle to fetch the correct AAR and its embedded ABI libs during the build. This is the cleanest approach for CI and downstream projects.
- Replace `<GITHUB_OWNER>/<REPO>` with your GitHub owner and repository name where the package is published.
