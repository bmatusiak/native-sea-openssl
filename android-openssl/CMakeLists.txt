cmake_minimum_required(VERSION 3.10)
project(android_openssl_lib LANGUAGES C CXX)

# This CMakeLists is a placeholder. The OpenSSL libraries will be prebuilt
# and packaged into the AAR; consumers can link against them in their own projects.

add_library(dummy-lib STATIC dummy.c)

add_library(native-lib SHARED IMPORTED)
set_target_properties(native-lib PROPERTIES IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libcrypto.so")
