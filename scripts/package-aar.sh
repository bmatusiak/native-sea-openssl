#!/usr/bin/env bash
set -euo pipefail

# Builds OpenSSL and packages an AAR containing .so files and headers.

OPENSSL_VERSION=${OPENSSL_VERSION:-"3.5.4"}
export OPENSSL_VERSION
ROOT_DIR="$(pwd)"
MODULE_DIR="$ROOT_DIR/native-sea-openssl"
OUTDIR="$ROOT_DIR/third_party/openssl/${OPENSSL_VERSION}"
ABIS=(armeabi-v7a arm64-v8a x86 x86_64)

# Packaging options (environment variables):
#  SKIP_OPENSSL_BUILD=1        -> don't run build-openssl.sh (use existing third_party outputs)
#  SHIP_OPENSSL_SOURCE=1       -> copy OpenSSL source to native-sea-openssl-package/openssl-src
#  SHIP_SOURCE_TO_AAR=1        -> include OpenSSL source inside AAR assets under assets/openssl/src
#  INCLUDE_STATIC=0|1          -> include .a static libs in jniLibs/prefab (default 1)
#  INCLUDE_SHARED=0|1          -> include .so shared libs in jniLibs/prefab (default 1)

SKIP_OPENSSL_BUILD=${SKIP_OPENSSL_BUILD:-0}
SHIP_OPENSSL_SOURCE=${SHIP_OPENSSL_SOURCE:-1}
SHIP_SOURCE_TO_AAR=${SHIP_SOURCE_TO_AAR:-0}
INCLUDE_STATIC=${INCLUDE_STATIC:-1}
INCLUDE_SHARED=${INCLUDE_SHARED:-1}
PACKAGE_DIR="$ROOT_DIR/native-sea-openssl-package"

# If the NDK env var isn't set, try to auto-detect under ANDROID_HOME/ndk
if [ -z "${ANDROID_NDK_ROOT:-}${ANDROID_NDK_HOME:-}" ] && [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
  latest=$(ls -1 "$ANDROID_HOME/ndk" | sort -V | tail -n1 || true)
  if [ -n "$latest" ]; then
    export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk/$latest"
    echo "Auto-set ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
  fi
fi

if [ "${SKIP_OPENSSL_BUILD}" = "1" ]; then
  echo "SKIP_OPENSSL_BUILD=1 -> skipping OpenSSL build. Assuming outputs exist in: $OUTDIR"
else
  echo "Building OpenSSL..."
  bash "$ROOT_DIR/scripts/build-openssl.sh"
fi

# Build and package two AAR variants: debug (with debug symbols) and release.

# Ensure assets dir for headers will be populated from the installs
mkdir -p "$MODULE_DIR/src/main/assets/openssl/include"
# optionally include source inside AAR assets
if [ "${SHIP_SOURCE_TO_AAR}" = "1" ]; then
  mkdir -p "$MODULE_DIR/src/main/assets/openssl/src"
fi
# Prefer copying the built, ABI-specific install includes (they contain generated
# configuration.h) and fall back to the source include templates if needed.
COPIED=0
for ABI in "${ABIS[@]}"; do
  # prefer release installs
  SRC_INC="$OUTDIR/$ABI/release/include"
  if [ -d "$SRC_INC" ]; then
    cp -r "$SRC_INC"/* "$MODULE_DIR/src/main/assets/openssl/include/"
    COPIED=1
    break
  fi
  # fallback to debug installs
  SRC_INC="$OUTDIR/$ABI/debug/include"
  if [ -d "$SRC_INC" ]; then
    cp -r "$SRC_INC"/* "$MODULE_DIR/src/main/assets/openssl/include/"
    COPIED=1
    break
  fi
done
if [ "$COPIED" -eq 0 ]; then
  if [ -d "$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}/include" ]; then
    cp -r "$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}/include"/* "$MODULE_DIR/src/main/assets/openssl/include/"
  else
    echo "Warning: no OpenSSL include files found in builds or source; prefab will miss configuration.h"
  fi
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
      # copy according to include flags
      if [ "${INCLUDE_SHARED}" = "1" ]; then
        for f in "$LIBDIR"/*.so; do
          [ -e "$f" ] || continue
          cp -v "$f" "$MODULE_DIR/src/main/jniLibs/$ABI/"
        done
      fi
      if [ "${INCLUDE_STATIC}" = "1" ]; then
        for f in "$LIBDIR"/*.a; do
          [ -e "$f" ] || continue
          cp -v "$f" "$MODULE_DIR/src/main/jniLibs/$ABI/"
        done
      fi
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
TARGET_DIR="$ROOT_DIR/native-sea-openssl-package/android"
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
      PREFAB_ABI_DIR="$PREFAB_DIR/libs/android.$ABI"
      mkdir -p "$PREFAB_ABI_DIR"
      for lib in libcrypto libssl; do
        if [ "${INCLUDE_STATIC}" = "1" ] && [ -f "$ABI_LIBDIR/${lib}.a" ]; then
          cp -v "$ABI_LIBDIR/${lib}.a" "$PREFAB_ABI_DIR/"
        fi
        if [ "${INCLUDE_SHARED}" = "1" ] && [ -f "$ABI_LIBDIR/${lib}.so" ]; then
          cp -v "$ABI_LIBDIR/${lib}.so" "$PREFAB_ABI_DIR/"
        fi
      done
    fi
  done

  # Create abi.json metadata files expected by the Prefab CLI for each ABI
  # Determine NDK major version if possible
  if [ -n "${ANDROID_NDK_ROOT:-}" ] && [ -f "$ANDROID_NDK_ROOT/source.properties" ]; then
    NDK_VER=$(grep -E '^Pkg.Revision' "$ANDROID_NDK_ROOT/source.properties" | awk -F'=' '{print $2}' | cut -d. -f1 | tr -d ' '\
    ) || true
  fi
  NDK_VER=${NDK_VER:-27}
  ANDROID_API=${ANDROID_API:-24}
  for ABI in "${ABIS[@]}"; do
    PREFAB_ABI_DIR="$PREFAB_DIR/libs/android.$ABI"
    if [ -d "$PREFAB_ABI_DIR" ]; then
      # Detect whether only static libs were provided
      STATIC_PRESENT=0
      SHARED_PRESENT=0
      shopt -s nullglob
      for f in "$PREFAB_ABI_DIR"/*.a; do
        STATIC_PRESENT=1 && break
      done
      for f in "$PREFAB_ABI_DIR"/*.so; do
        SHARED_PRESENT=1 && break
      done
      shopt -u nullglob
      if [ "$SHARED_PRESENT" -eq 1 ]; then
        STATIC_FLAG=false
      elif [ "$STATIC_PRESENT" -eq 1 ]; then
        STATIC_FLAG=true
      else
        # no libs => skip writing metadata
        continue
      fi

      # If static libs were provided as libcrypto.a and libssl.a, create
      # a merged libopenssl.a archive so the Prefab-generated
      # opensslConfig.cmake IMPORTED_LOCATION points to an existing file.
      if [ "$STATIC_PRESENT" -eq 1 ]; then
        if [ -f "$PREFAB_ABI_DIR/libcrypto.a" ] || [ -f "$PREFAB_ABI_DIR/libssl.a" ]; then
          # Only create libopenssl.a if it doesn't already exist
          if [ ! -f "$PREFAB_ABI_DIR/libopenssl.a" ]; then
            echo "Creating merged static archive: $PREFAB_ABI_DIR/libopenssl.a"
            tmpobjdir=$(mktemp -d)
            pushd "$tmpobjdir" >/dev/null
            # extract object files from available archives
            if [ -f "$PREFAB_ABI_DIR/libcrypto.a" ]; then
              ar -x "$PREFAB_ABI_DIR/libcrypto.a" || true
            fi
            if [ -f "$PREFAB_ABI_DIR/libssl.a" ]; then
              ar -x "$PREFAB_ABI_DIR/libssl.a" || true
            fi
            # create combined archive
            if compgen -G "*.o" >/dev/null; then
              ar -rcs "$PREFAB_ABI_DIR/libopenssl.a" *.o
              # ensure index
              if command -v ranlib >/dev/null 2>&1; then
                ranlib "$PREFAB_ABI_DIR/libopenssl.a" || true
              fi
            else
              echo "Warning: no object files found to build libopenssl.a for $PREFAB_ABI_DIR"
            fi
            popd >/dev/null
            rm -rf "$tmpobjdir"
          fi
        fi
      fi

      cat > "$PREFAB_ABI_DIR/abi.json" <<EOF
{
  "abi": "$ABI",
  "api": $ANDROID_API,
  "ndk": $NDK_VER,
  "stl": "c++_shared",
  "static": $STATIC_FLAG
}
EOF
    fi
  done

  # Write a minimal Prefab-compatible module.json that does NOT export
  # libraries. Leaving out `export_libraries` prevents Prefab from
  # adding INTERFACE_LINK_LIBRARIES (which produced -l flags like
  # -lopenssl causing unresolved linker errors). The imported target
  # will still have IMPORTED_LOCATION pointing to libopenssl.a.
  MODULE_JSON="$tmpdir/prefab/modules/openssl/module.json"
  cat > "$MODULE_JSON" <<EOF
{
  "android": {}
}
EOF

  # Also write top-level prefab package index so Prefab CLI recognizes the package
  PREFAB_JSON="$tmpdir/prefab/prefab.json"
  mkdir -p "$(dirname "$PREFAB_JSON")"
  cat > "$PREFAB_JSON" <<EOF
{
  "name": "openssl",
  "schema_version": 2,
  "dependencies": [],
  "version": "${OPENSSL_VERSION}"
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

# Ensure the package folder receives the injected AARs (overwrite previous copies)
mkdir -p "$TARGET_DIR"
for A in "$MODULE_DIR/build/outputs/aar/native-sea-openssl-debug.aar" \
         "$MODULE_DIR/build/outputs/aar/native-sea-openssl-release.aar"; do
  if [ -f "$A" ]; then
    cp -v "$A" "$TARGET_DIR/"
  fi
done
echo "Copied injected AARs to: $TARGET_DIR"

# Optionally include OpenSSL source inside the AAR assets
if [ "${SHIP_SOURCE_TO_AAR}" = "1" ]; then
  SRC_DIR="$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}"
  if [ -d "$SRC_DIR" ]; then
    echo "Adding OpenSSL source into AAR assets..."
    # copy into assets so it will be included in future AAR builds (if any)
    rsync -a --exclude 'build' --exclude '*.o' --exclude '*.a' --exclude '*.so' "$SRC_DIR/" "$MODULE_DIR/src/main/assets/openssl/src/"
  else
    echo "Warning: OpenSSL source not found at $SRC_DIR — cannot include in AAR assets"
  fi
fi

# Optionally ship OpenSSL source alongside package outputs (release folder)
if [ "${SHIP_OPENSSL_SOURCE}" = "1" ]; then
  SRC_DIR="$ROOT_DIR/third_party/src/openssl-${OPENSSL_VERSION}"
  if [ -d "$SRC_DIR" ]; then
    DEST="$PACKAGE_DIR/src/openssl-${OPENSSL_VERSION}"
    mkdir -p "$DEST"
    echo "Copying OpenSSL source to $DEST"
    rsync -a --exclude 'build' --exclude '*.o' --exclude '*.a' --exclude '*.so' "$SRC_DIR/" "$DEST/"
  else
    echo "Warning: OpenSSL source not found at $SRC_DIR — cannot ship source"
  fi
fi

echo "Packaging script complete. Package folder: $PACKAGE_DIR"
