cmake_minimum_required(VERSION 3.26)

#list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

project(ulib
  VERSION 6.0
  LANGUAGES C OBJC)

set(CMAKE_POSITION_INDEPENDENT_CODE YES)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED YES)

set(CMAKE_CXX_STANDARD 11)

macro( target_link_framework TARGET NAME )
    find_library( FRAMEWORK_${NAME}
        NAMES ${NAME}
        PATHS ${CMAKE_OSX_SYSROOT}/System/Library
        PATH_SUFFIXES Frameworks PrivateFrameworks
        CMAKE_FIND_FRAMEWORK only
        NO_DEFAULT_PATH )
    if( ${FRAMEWORK_${NAME}} STREQUAL FRAMEWORK_${NAME}-NOTFOUND)
        message( ERROR ": Framework ${NAME} not found" )
    else()
        target_link_libraries( ${TARGET} PUBLIC "${FRAMEWORK_${NAME}}" )
        message( STATUS "Framework ${NAME} found at ${FRAMEWORK_${NAME}}" )
    endif()
endmacro( target_link_framework )


set_source_files_properties(foo.cpp PROPERTIES COMPILE_OPTIONS "-Wno-unused-parameter;-Wno-missing-field-initializer")
#find_package(Threads REQUIRED)

#include(CheckCCompilerFlag)
#include(CheckCSourceCompiles)
#include(CheckFunctionExists)
#include(CheckIncludeFiles)
#include(CheckLibraryExists)
#include(CheckLinkerFlag)
#include(CheckSymbolExists)
#include(GNUInstallDirs)
#include(CTest)

#include(DispatchAppleOptions)
#include(DispatchSanitization)
#include(DispatchCompilerWarnings)
#include(DTrace)
#include(EnableFramePointers)

# NOTE(abdulras) this is the CMake supported way to control whether we generate
# shared or static libraries.  This impacts the behaviour of `add_library` in
# what type of library it generates.
option(BUILD_SHARED_LIBS "build shared libraries" ON)
option(DISPATCH_ENABLE_ASSERTS "enable debug assertions" FALSE)

option(INSTALL_PRIVATE_HEADERS "installs private headers in the same location as the public ones" OFF)

add_subdirectory(ulib)
#set_property (TARGET ulib APPEND_STRING PROPERTY COMPILE_FLAGS "-fobjc-arc")

set_target_properties(ulib PROPERTIES LINK_FLAGS "-Wl,-F/Library/Frameworks")

target_compile_options(ulib PUBLIC "-fobjc-arc")

#add_library(bingitup STATIC bingitup.cpp)

target_include_directories(ulib PRIVATE .)

target_link_libraries(ulib PUBLIC -L/usr/local/include/)
target_link_framework(ulib Foundation)
target_link_framework(ulib CoreFoundation)
target_link_framework(ulib IOKit)
target_link_libraries(ulib PUBLIC libzmq.dylib)
target_link_libraries(ulib PUBLIC libssl.a)
target_link_libraries(ulib PUBLIC libcrypto.a)
target_link_libraries(ulib PUBLIC libc++.1.tbd)

