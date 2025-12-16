#!/usr/bin/env bash
set -euo pipefail

# Builds OpenSSL and packages an AAR containing .so files and headers.

OPENSSL_VERSION=${OPENSSL_VERSION:-"3.0.11"}
ROOT_DIR="$(pwd)"
MODULE_DIR="$ROOT_DIR/native-sea-openssl"
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

# Build and package two AAR variants: debug (with debug symbols) and release.

# Ensure assets dir for headers will be populated from the installs
mkdir -p "$MODULE_DIR/src/main/assets/openssl/include"
if [ -d "$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}/include" ]; then
  cp -r "$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}/include"/* "$MODULE_DIR/src/main/assets/openssl/include/"
else
  # try copying from one of the built installs (prefer any ABI/release copy)
  for ABI in "${ABIS[@]}"; do
    SRC_INC="$OUTDIR/$ABI/release/include"
    if [ -d "$SRC_INC" ]; then
      cp -r "$SRC_INC"/* "$MODULE_DIR/src/main/assets/openssl/include/"
      break
    fi
  done
fi

assemble_variant() {
  local VARIANT="$1"   # debug or release
  echo "Assembling AAR variant: $VARIANT"

  # Clean and populate jniLibs with appropriate libs for this variant
  rm -rf "$MODULE_DIR/src/main/jniLibs"
  for ABI in "${ABIS[@]}"; do
    mkdir -p "$MODULE_DIR/src/main/jniLibs/$ABI"
    LIBDIR="$OUTDIR/$ABI/$VARIANT/lib"
    if [ -d "$LIBDIR" ]; then
      cp -v "$LIBDIR"/*.a "$LIBDIR"/*.so 2>/dev/null || true
      # prefer .so if present
      for f in "$LIBDIR"/*.so; do
        [ -e "$f" ] || continue
        cp -v "$f" "$MODULE_DIR/src/main/jniLibs/$ABI/"
      done
      # if only .a exist, copy them too so consumers can link against static libs
      for f in "$LIBDIR"/*.a; do
        [ -e "$f" ] || continue
        cp -v "$f" "$MODULE_DIR/src/main/jniLibs/$ABI/"
      done
    else
      echo "Warning: libs not found for $ABI/$VARIANT at $LIBDIR"
    fi
  done

  # Assemble only the requested Gradle variant
  if [ -x "$MODULE_DIR/gradlew" ]; then
    ( cd "$MODULE_DIR" && if [ "$VARIANT" = "debug" ]; then ./gradlew assembleDebug; else ./gradlew assembleRelease; fi )
  elif command -v gradle >/dev/null 2>&1; then
    ( cd "$MODULE_DIR" && if [ "$VARIANT" = "debug" ]; then gradle assembleDebug; else gradle assembleRelease; fi )
  else
    echo "Gradle not found. To produce the AARs either:"
    echo "  1) Install Gradle and run the assemble tasks in $MODULE_DIR"
    echo "AARs were not assembled. The built OpenSSL libraries are available under: $OUTDIR"
    exit 1
  fi
}

echo "Assembling Android AARs (debug + release) via Gradle..."
assemble_variant debug
assemble_variant release

echo "AAR build complete. Find the AARs in: $MODULE_DIR/build/outputs/aar/"
echo "  - $MODULE_DIR/build/outputs/aar/native-sea-openssl-debug.aar"
echo "  - $MODULE_DIR/build/outputs/aar/native-sea-openssl-release.aar"

# Copy produced AARs into the React Native wrapper android folder for convenience
TARGET_DIR="$ROOT_DIR/react-native-native-sea-openssl/android"
mkdir -p "$TARGET_DIR"
for A in "$MODULE_DIR/build/outputs/aar/native-sea-openssl-debug.aar" \
         "$MODULE_DIR/build/outputs/aar/native-sea-openssl-release.aar"; do
  if [ -f "$A" ]; then
    cp -v "$A" "$TARGET_DIR/"
  else
    echo "Warning: AAR not found: $A"
  fi
done
echo "Copied AARs to: $TARGET_DIR"

# Inject a Prefab module into the produced AARs so downstream CMake/Gradle
# consumers can directly consume OpenSSL as a prefab package.
inject_prefab_into_aar() {
  local aarfile="$1"
  local variant="$2"
  local tmpdir
  tmpdir=$(mktemp -d)
  echo "Injecting prefab into $aarfile (workdir: $tmpdir)"

  (cd "$tmpdir" && unzip -q "$aarfile")

  PREFAB_DIR="$tmpdir/prefab/modules/openssl"
  mkdir -p "$PREFAB_DIR/libs"

  # Copy headers
  mkdir -p "$PREFAB_DIR/include"
  if [ -d "$MODULE_DIR/src/main/assets/openssl/include" ]; then
    cp -a "$MODULE_DIR/src/main/assets/openssl/include/"* "$PREFAB_DIR/include/"
  else
    echo "Warning: headers not found to include in prefab"
  fi

  # Copy prebuilt libs for each ABI into prefab/libs/<abi>/
  ABIS=(armeabi-v7a arm64-v8a x86 x86_64)
  for ABI in "${ABIS[@]}"; do
    # prefer variant-specific installs (e.g., .../<abi>/debug/lib)
    ABI_LIBDIR="$OUTDIR/$ABI/$variant/lib"
    if [ ! -d "$ABI_LIBDIR" ]; then
      # fallback to legacy location
      ABI_LIBDIR="$OUTDIR/$ABI/lib"
    fi
    if [ -d "$ABI_LIBDIR" ]; then
      mkdir -p "$PREFAB_DIR/libs/$ABI"
      # copy .a and .so if present
      for lib in libcrypto libssl; do
        if [ -f "$ABI_LIBDIR/${lib}.a" ]; then
          cp -v "$ABI_LIBDIR/${lib}.a" "$PREFAB_DIR/libs/$ABI/"
        fi
        if [ -f "$ABI_LIBDIR/${lib}.so" ]; then
          cp -v "$ABI_LIBDIR/${lib}.so" "$PREFAB_DIR/libs/$ABI/"
        fi
      done
    fi
  done

  # Write a simple module.json describing the two OpenSSL libraries
  MODULE_JSON="$tmpdir/prefab/modules/openssl/module.json"
  cat > "$MODULE_JSON" <<EOF
{
  "name": "openssl",
  "version": "${OPENSSL_VERSION}",
  "libraries": [
    {
      "name": "crypto",
      "headers": [ "include" ]
    },
    {
      "name": "ssl",
      "headers": [ "include" ]
    }
  ]
}
EOF

  # Repack the AAR with the prefab directory included
  pushd "$tmpdir" >/dev/null
  # create a new AAR file (overwrite original)
  zip -q -r "$aarfile" .
  popd >/dev/null

  rm -rf "$tmpdir"
  echo "Prefab injected into $aarfile"
}

for A_VAR in debug release; do
  A="$MODULE_DIR/build/outputs/aar/native-sea-openssl-${A_VAR}.aar"
  if [ -f "$A" ]; then
    inject_prefab_into_aar "$A" "$A_VAR"
  fi
done
