#!/usr/bin/env bash
set -euo pipefail

# Builds OpenSSL for common Android ABIs and installs outputs under third_party/openssl/<version>/<abi>

OPENSSL_VERSION=${OPENSSL_VERSION:-"3.0.11"}
NDK=${ANDROID_NDK_ROOT:-${ANDROID_NDK_HOME:-""}}
# Auto-detect NDK under ANDROID_HOME/ndk if not provided
if [ -z "$NDK" ] && [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
  # pick the highest-version folder in $ANDROID_HOME/ndk
  latest=$(ls -1 "$ANDROID_HOME/ndk" | sort -V | tail -n1 || true)
  if [ -n "$latest" ]; then
    NDK="$ANDROID_HOME/ndk/$latest"
    echo "Auto-detected NDK: $NDK"
  fi
fi
API=${API:-21}
ABIS=(armeabi-v7a arm64-v8a x86 x86_64)
OUTDIR="$(pwd)/third_party/openssl/${OPENSSL_VERSION}"

if [ -z "$NDK" ]; then
  echo "ANDROID_NDK_ROOT or ANDROID_NDK_HOME must be set to your NDK path"
  exit 1
fi

mkdir -p "$OUTDIR"

# Download source tarball if needed
TARBALL="openssl-${OPENSSL_VERSION}.tar.gz"
SRCDIR="$(pwd)/third_party/src/openssl-${OPENSSL_VERSION}"
if [ ! -d "$SRCDIR" ]; then
  mkdir -p "$(pwd)/third_party/src"
  if [ ! -f "$(pwd)/third_party/src/$TARBALL" ]; then
    echo "Downloading OpenSSL $OPENSSL_VERSION..."
    curl -L -o "$(pwd)/third_party/src/$TARBALL" "https://www.openssl.org/source/$TARBALL"
  fi
  tar -xzf "$(pwd)/third_party/src/$TARBALL" -C "$(pwd)/third_party/src"
fi

pushd "$SRCDIR"

for ABI in "${ABIS[@]}"; do
  case "$ABI" in
    armeabi-v7a)
      TARGET="android-arm"
      TOOLCHAIN_PREFIX=armv7a-linux-androideabi
      ;;
    arm64-v8a)
      TARGET="android-arm64"
      TOOLCHAIN_PREFIX=aarch64-linux-android
      ;;
    x86)
      TARGET="android-x86"
      TOOLCHAIN_PREFIX=i686-linux-android
      ;;
    x86_64)
      TARGET="android-x86_64"
      TOOLCHAIN_PREFIX=x86_64-linux-android
      ;;
    *)
      echo "Unsupported ABI: $ABI"; exit 1;;
  esac

  echo "Building OpenSSL for $ABI (target $TARGET)"

  BUILD_OUT="$OUTDIR/$ABI"
  mkdir -p "$BUILD_OUT"
  make clean || true

  # Prepare Android NDK toolchain
  TOOLCHAIN_BIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
  if [ ! -d "$TOOLCHAIN_BIN" ]; then
    echo "Cannot find NDK prebuilt toolchain at $TOOLCHAIN_BIN"
    echo "Set ANDROID_NDK_ROOT to your NDK and ensure the prebuilt toolchain exists."
    exit 1
  fi

  case "$ABI" in
    armeabi-v7a)
      CC="$TOOLCHAIN_BIN/armv7a-linux-androideabi${API}-clang"
      ;;
    arm64-v8a)
      CC="$TOOLCHAIN_BIN/aarch64-linux-android${API}-clang"
      ;;
    x86)
      CC="$TOOLCHAIN_BIN/i686-linux-android${API}-clang"
      ;;
    x86_64)
      CC="$TOOLCHAIN_BIN/x86_64-linux-android${API}-clang"
      ;;
  esac

  export PATH="$TOOLCHAIN_BIN:$PATH"
  export CC
  export AR="$TOOLCHAIN_BIN/llvm-ar"
  export RANLIB="$TOOLCHAIN_BIN/llvm-ranlib"
  export NM="$TOOLCHAIN_BIN/llvm-nm"
  export STRIP="$TOOLCHAIN_BIN/llvm-strip"

  # Configure and build
  ./Configure $TARGET no-shared no-tests --prefix="$BUILD_OUT" -D__ANDROID_API__=$API
  make -j$(nproc)
  make install_sw

  echo "Installed to $BUILD_OUT"
done

popd

echo "OpenSSL $OPENSSL_VERSION build complete. Outputs in: $OUTDIR" 
