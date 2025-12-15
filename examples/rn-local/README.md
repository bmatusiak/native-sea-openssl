Example React Native (Android) — Local AAR consumption

This example demonstrates how a React Native Android app can consume the packaged AAR locally from `node_modules` (useful for development).

Steps (assumes you installed the npm wrapper locally):

1. `npm install --save /path/to/native-sea-openssl/react-native-native-sea-openssl`
2. In your app module `android/app/build.gradle` add the dependency to the AAR shipped inside `node_modules`:

   dependencies {
     implementation files('../node_modules/react-native-native-sea-openssl/android/native-sea-openssl.aar')
     // other deps (React Native etc.)
   }

3. From your project root run Gradle build (or `npx react-native run-android`).

Notes
- This approach bundles the AAR that was included in the npm package into the app. It's simple for local testing but less ideal for CI and distribution because binaries live in npm.
- If you publish the AAR to Maven later, switch to the Maven-based example.
