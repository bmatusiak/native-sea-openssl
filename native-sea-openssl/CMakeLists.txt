cmake_minimum_required(VERSION 3.10)
project(android_openssl_lib LANGUAGES C CXX)

set(OPENSSL_VERSION "3.0.11" CACHE STRING "OpenSSL version used for locate prebuilt libs")

# Paths to potential prebuilt libraries
set(PREBUILT_SO "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libcrypto.so")
set(PREBUILT_A "${CMAKE_SOURCE_DIR}/../third_party/openssl/${OPENSSL_VERSION}/${ANDROID_ABI}/lib/libcrypto.a")
set(PREBUILT_INC "${CMAKE_SOURCE_DIR}/../third_party/openssl/${OPENSSL_VERSION}/${ANDROID_ABI}/include")

if(EXISTS ${PREBUILT_SO})
	add_library(libcrypto SHARED IMPORTED)
	set_target_properties(libcrypto PROPERTIES IMPORTED_LOCATION ${PREBUILT_SO})
	set(OPENSSL_INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp")
elseif(EXISTS ${PREBUILT_A})
	add_library(libcrypto STATIC IMPORTED)
	set_target_properties(libcrypto PROPERTIES IMPORTED_LOCATION ${PREBUILT_A})
	set(OPENSSL_INC_DIR ${PREBUILT_INC})
else()
	message(FATAL_ERROR "Could not find prebuilt libcrypto for ${ANDROID_ABI}. Checked: ${PREBUILT_SO} and ${PREBUILT_A}")
endif()

add_library(ssl_jni SHARED src/main/cpp/openssl_jni.cpp)

find_library(log-lib log)

target_include_directories(ssl_jni PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp ${OPENSSL_INC_DIR})
target_link_libraries(ssl_jni libcrypto ${log-lib} m)
