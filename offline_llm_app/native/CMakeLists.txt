# CMakeLists.txt for llama_wrapper
# This file is used by Android NDK to build the native library

cmake_minimum_required(VERSION 3.18)
project(llama_wrapper)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# Optimization flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -fPIC")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -fPIC")

# Disable FP16/Accelerate paths for emulator/x86_64 to avoid missing intrinsics
add_compile_definitions(
    GGML_NO_F16C=1
    GGML_NO_ACCELERATE=1
)

# Build llama.cpp as a static library
set(LLAMA_STATIC ON CACHE BOOL "Build llama as static library" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Disable tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Disable examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Disable server" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries" FORCE)

# Mobile optimizations
set(LLAMA_NATIVE OFF CACHE BOOL "Disable native optimizations for cross-compile" FORCE)
set(LLAMA_ACCELERATE OFF CACHE BOOL "Disable Accelerate" FORCE)
set(LLAMA_METAL OFF CACHE BOOL "Disable Metal for Android" FORCE)
set(LLAMA_CUDA OFF CACHE BOOL "Disable CUDA" FORCE)
set(LLAMA_VULKAN OFF CACHE BOOL "Disable Vulkan" FORCE)
set(LLAMA_OPENMP OFF CACHE BOOL "Disable OpenMP" FORCE)

# Add llama.cpp subdirectory
# Expects llama.cpp to be cloned into native/llama.cpp/
add_subdirectory(llama.cpp)

# Create the wrapper shared library
add_library(llama_wrapper SHARED
    llama_wrapper.cpp
)

# Include directories
target_include_directories(llama_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/common
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/ggml/include
)

# Link against llama static library
target_link_libraries(llama_wrapper PRIVATE
    llama
)

# Android-specific settings
if(ANDROID)
    target_link_libraries(llama_wrapper PRIVATE
        log
        android
    )
    
    # Strip debug symbols for release builds
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set_target_properties(llama_wrapper PROPERTIES
            LINK_FLAGS "-s"
        )
    endif()
endif()

# Export symbols
set_target_properties(llama_wrapper PROPERTIES
    C_VISIBILITY_PRESET default
    CXX_VISIBILITY_PRESET default
    VISIBILITY_INLINES_HIDDEN OFF
)
