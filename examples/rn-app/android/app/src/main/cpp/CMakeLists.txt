cmake_minimum_required(VERSION 3.10)
project(native_sea_openssl_demo LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)

# Prefer the Prefab-provided OpenSSL CMake target. Fail early if it's not
# available so the build system relies on the AAR dependency instead of
# local file copies.
add_library(native-lib SHARED native-lib.cpp)

# If Gradle unpacks the AAR prefab into a build dir it will pass
# -DOPENSSL_PREFAB_DIR=<dir>. Prefer that unpacked prefab first (so we
# don't need to copy files into source). Otherwise fall back to prefer
# a system Prefab find_package.
if(DEFINED OPENSSL_PREFAB_DIR)
	message(STATUS "Using unpacked OpenSSL prefab at ${OPENSSL_PREFAB_DIR}")
	target_include_directories(native-lib PRIVATE ${OPENSSL_PREFAB_DIR}/include)
	set(PREBUILT_LIB "${OPENSSL_PREFAB_DIR}/libs/android.${ANDROID_ABI}/libopenssl.a")
	add_library(libopenssl STATIC IMPORTED)
	set_target_properties(libopenssl PROPERTIES IMPORTED_LOCATION ${PREBUILT_LIB})
	target_link_libraries(native-lib PRIVATE libopenssl)
else()
	find_package(openssl CONFIG REQUIRED)
	target_link_libraries(native-lib PRIVATE openssl::openssl)
endif()
