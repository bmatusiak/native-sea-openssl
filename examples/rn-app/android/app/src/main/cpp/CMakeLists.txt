cmake_minimum_required(VERSION 3.10)
project(rnopenssl)

set(CMAKE_CXX_STANDARD 17)

find_package(openssl CONFIG REQUIRED)

add_library(rnopenssl SHARED
    openssl_jni.cpp
)

target_link_libraries(rnopenssl
    PRIVATE openssl::openssl
)

set_target_properties(rnopenssl PROPERTIES OUTPUT_NAME "rnopenssl")
