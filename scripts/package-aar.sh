#!/usr/bin/env bash
set -euo pipefail

# Builds OpenSSL and packages an AAR containing .so files and headers.

OPENSSL_VERSION=${OPENSSL_VERSION:-"3.0.11"}
ROOT_DIR="$(pwd)"
MODULE_DIR="$ROOT_DIR/android-openssl"
OUTDIR="$ROOT_DIR/third_party/openssl/${OPENSSL_VERSION}"
ABIS=(armeabi-v7a arm64-v8a x86 x86_64)

# If the NDK env var isn't set, try to auto-detect under ANDROID_HOME/ndk
if [ -z "${ANDROID_NDK_ROOT:-}${ANDROID_NDK_HOME:-}" ] && [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
  latest=$(ls -1 "$ANDROID_HOME/ndk" | sort -V | tail -n1 || true)
  if [ -n "$latest" ]; then
    export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk/$latest"
    echo "Auto-set ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
  fi
fi

echo "Building OpenSSL..."
bash "$ROOT_DIR/scripts/build-openssl.sh"

# Clean target jniLibs and assets
rm -rf "$MODULE_DIR/src/main/jniLibs"
rm -rf "$MODULE_DIR/src/main/assets/openssl"

for ABI in "${ABIS[@]}"; do
  mkdir -p "$MODULE_DIR/src/main/jniLibs/$ABI"
  LIBDIR="$OUTDIR/$ABI/lib"
  if [ -d "$LIBDIR" ]; then
    cp -v "$LIBDIR"/*.a "$LIBDIR"/*.so 2>/dev/null || true
    # prefer .so if present
    for f in "$LIBDIR"/*.so; do
      [ -e "$f" ] || continue
      cp -v "$f" "$MODULE_DIR/src/main/jniLibs/$ABI/"
    done
  fi
done

# Copy include headers into AAR assets so downstream projects can extract them
mkdir -p "$MODULE_DIR/src/main/assets/openssl/include"
if [ -d "$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}/include" ]; then
  cp -r "$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}/include"/* "$MODULE_DIR/src/main/assets/openssl/include/"
else
  echo "Warning: include directory not found in source; attempting to copy from installs"
  # try copying from one of the built installs
  for ABI in "${ABIS[@]}"; do
    SRC_INC="$OUTDIR/$ABI/include"
    if [ -d "$SRC_INC" ]; then
      cp -r "$SRC_INC"/* "$MODULE_DIR/src/main/assets/openssl/include/"
      break
    fi
  done
fi

echo "Assembling Android AAR via Gradle..."
# Run gradle assembleRelease in the module to create the AAR. Prefer bundled wrapper if present.
if [ -x "$MODULE_DIR/gradlew" ]; then
  ( cd "$MODULE_DIR" && ./gradlew assembleRelease )
elif command -v gradle >/dev/null 2>&1; then
  ( cd "$MODULE_DIR" && gradle assembleRelease )
else
  echo "Gradle not found. To produce the AAR either:"
  echo "  1) Install Gradle and run: (cd $MODULE_DIR && gradle assembleRelease)" 
  echo "  2) Or create a Gradle wrapper in the module: (cd $MODULE_DIR && gradle wrapper) then ./gradlew assembleRelease"
  echo "AAR was not assembled. The built OpenSSL libraries are available under: $OUTDIR"
  exit 1
fi

echo "AAR build complete. Find the AAR in: $MODULE_DIR/build/outputs/aar/" 
