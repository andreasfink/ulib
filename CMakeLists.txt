cmake_minimum_required(VERSION 3.26)

project(ulib
  VERSION 6.0
  LANGUAGES C OBJC)

set(CMAKE_OSX_ARCHITECTURES arm64 x86_64)
set(CMAKE_OSX_DEPLOYMENT_TARGET 10.15)
set(CMAKE_POSITION_INDEPENDENT_CODE YES)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED YES)
set(CMAKE_CXX_STANDARD 11)

macro( target_link_framework TARGET NAME )
    find_library( FRAMEWORK_${NAME}
        NAMES ${NAME}
        PATHS ${CMAKE_OSX_SYSROOT}/System/Library /Library/Application\ Support/FinkTelecomServices/frameworks
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


option(BUILD_SHARED_LIBS "build shared libraries" ON)
option(BUILD_STATIC_LIBS "build static libraries" ON)
option(INSTALL_PRIVATE_HEADERS "installs private headers in the same location as the public ones" OFF)

add_subdirectory(ulib)
target_compile_options(ulib PUBLIC "-fobjc-arc")
set_target_properties(ulib PROPERTIES LINK_FLAGS "-Wl,-F/Library/Frameworks")

target_include_directories(ulib PRIVATE .)
target_include_directories(ulib PRIVATE /usr/local/include)

if(MACOS)
	target_include_directories(ulib PRIVATE /opt/homebrew/include)
endif()

target_link_libraries(ulib PRIVATE -L/usr/local/lib/)
if(MACOS)
	target_link_libraries(ulib PRIVATE -L/opt/homebrew/lib/)
endif()

target_link_framework(ulib Foundation)
if(MACOS)
	target_link_framework(ulib IOKit)
endif()
if(MACOS)
	target_link_libraries(ulib PRIVATE /opt/homebrew/lib/libzmq.a)
	target_link_libraries(ulib PRIVATE /opt/homebrew/lib/libssl.a)
	target_link_libraries(ulib PRIVATE /opt/homebrew/lib/libcrypto.a)
	target_link_libraries(ulib PRIVATE libc++.1.tbd)
endif()

