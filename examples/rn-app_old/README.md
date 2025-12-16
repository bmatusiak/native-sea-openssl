Example React Native app that demonstrates consuming the OpenSSL wrapper.

Quick start (development):

1. From this repo root, install dependencies for the example:

   cd examples/rn-app
   npm install

   (This will install `react`, `react-native` and the local wrapper via `file:../native-sea-openssl-package`.)

2. Start Metro and run on Android:

   npm run android

Notes:
- The local wrapper package `native-sea-openssl-package` should contain the AAR under `node_modules/native-sea-openssl-package/android/native-sea-openssl.aar` (the repo already includes it in `native-sea-openssl-package/android`).
- The example's Android Gradle config is minimal and intended to demonstrate how to include the AAR. For a full RN environment you may need to adjust Gradle plugin and Android SDK versions to match your setup.
- The JS app calls `require('native-sea-openssl-package')` and expects a function `callOpenSSL()` exported by the native module; that native module is not implemented yet — calling will show a fallback message.

Next steps to make this end-to-end:
- Implement the Java/Kotlin native module in the `native-sea-openssl-package` package and include it in the AAR (I can scaffold this next).
- Optionally publish the AAR to GitHub Packages and switch the wrapper to use Maven coordinates instead of bundling the AAR.
