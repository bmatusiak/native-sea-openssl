cmake_minimum_required(VERSION 3.10)
project(native_sea_openssl_demo LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)

# Prefab should make OpenSSL available via find_package. Make it QUIET so
# the build falls back to the prebuilt archive in jniLibs when Prefab is
# not available in the toolchain's CMAKE_PREFIX_PATH.
find_package(openssl CONFIG QUIET)

add_library(native-lib SHARED native-lib.cpp)

target_include_directories(native-lib PRIVATE ${CMAKE_SOURCE_DIR}/../../assets/openssl/include ${CMAKE_SOURCE_DIR}/../../assets/openssl/include/openssl ${CMAKE_SOURCE_DIR}/openssl/include)

# Link against the prefab target or prebuilt archive
if (TARGET openssl::openssl)
    target_link_libraries(native-lib PRIVATE openssl::openssl)
else()
    # Fallback: link to libopenssl.a in jniLibs
    set(PREBUILT_LIB "${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libopenssl.a")
    add_library(libopenssl STATIC IMPORTED)
    set_target_properties(libopenssl PROPERTIES IMPORTED_LOCATION ${PREBUILT_LIB})
    target_link_libraries(native-lib PRIVATE libopenssl)
endif()
