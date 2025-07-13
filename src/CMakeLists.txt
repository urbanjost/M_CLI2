cmake_minimum_required(VERSION 3.10)
project(M_CLI2 LANGUAGES Fortran)

# Define the build directory in the project root
set(BUILD_DIR ${CMAKE_SOURCE_DIR}/../build)

# Set the build directory for all CMake-generated files
#set(CMAKE_BINARY_DIR ${BUILD_DIR})
#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${BUILD_DIR})
#set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${BUILD_DIR})
#set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${BUILD_DIR})

# Set Fortran compiler flags for modern standards
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS}")

set(INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/include)

# Place module files (.mod) in build/lib
set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/include)

# Define the library
add_library(M_CLI2 STATIC
    M_CLI2.F90
)

# Set output directory for the library to build/lib
set_target_properties(M_CLI2 PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${BUILD_DIR}/lib"
)

set_source_files_properties(
  "*.F90" "*.f90"
  PROPERTIES Fortran_PREPROCESS ON
)

# Find all Fortran files in test/ and example/ directories (relative to project root)
#file(GLOB TEST_SOURCES "${CMAKE_SOURCE_DIR}/../test/*.f90")
file(GLOB TEST_SOURCES 
"${CMAKE_SOURCE_DIR}/../test/fid.f90"
"${CMAKE_SOURCE_DIR}/../test/test_ignorecase.f90"
"${CMAKE_SOURCE_DIR}/../test/test_lastonly.f90"
"${CMAKE_SOURCE_DIR}/../test/test_strict.f90"
"${CMAKE_SOURCE_DIR}/../test/test_suite_M_CLI2.f90"
"${CMAKE_SOURCE_DIR}/../test/test_syntax.f90"
"${CMAKE_SOURCE_DIR}/../test/fid.f90"
)

file(GLOB EXAMPLE_SOURCES "${CMAKE_SOURCE_DIR}/../example/*.f90")
# Build test programs
foreach(test_source ${TEST_SOURCES})
    get_filename_component(test_name ${test_source} NAME_WE)
    add_executable(${test_name} ${test_source})
    target_link_libraries(${test_name} PRIVATE M_CLI2)
    set_target_properties(${test_name} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${BUILD_DIR}/test"
    )
endforeach()

# Build example programs
foreach(example_source ${EXAMPLE_SOURCES})
    get_filename_component(example_name ${example_source} NAME_WE)
    add_executable(${example_name} ${example_source})
    target_link_libraries(${example_name} PRIVATE M_CLI2)
    set_target_properties(${example_name} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${BUILD_DIR}/example"
    )
endforeach()

##################################################################################
# Platform-specific default installation directories for binaries
# 
# CMAKE_INSTALL_PREFIX
# 
# Install directory used by install().
# 
# If make install is invoked or INSTALL is built, this directory is
# prepended onto all install directories.
# 
# This variable defaults as follows:
# 
#     Added in version 3.29: If the CMAKE_INSTALL_PREFIX environment
#     variable is set, its value is used as default for this variable.
# 
#     c:/Program Files/${PROJECT_NAME} on Windows.
# 
#     /usr/local on UNIX platforms.
# 
# See CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT for how a project
# might choose its own default.
# 
# On UNIX one can use the DESTDIR mechanism in order to relocate the whole
# installation to a staging area. See the DESTDIR environment variable
# for more information.
# 
# The installation prefix is also added to CMAKE_SYSTEM_PREFIX_PATH so
# that find_package(), find_program(), find_library(), find_path(), and
# find_file() will search the prefix for other software. This behavior can
# be disabled by setting the CMAKE_FIND_NO_INSTALL_PREFIX to TRUE before
# the first project() invocation.
# 
# Note
# 
# Use the GNUInstallDirs module to provide GNU-style options for the layout
# of directories within the installation.
# 
# The CMAKE_INSTALL_PREFIX may be defined when configuring a build tree to
# set its installation prefix. Or, when using the cmake(1) command-line
# tool's --install mode, one may specify a different prefix using the
# --prefix option:
# 
#     cmake --install . --prefix /my/install/prefix
# 
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
   set(CMAKE_INSTALL_PREFIX "$ENV{HOME}/.local")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
   set(CMAKE_INSTALL_PREFIX "$ENV{APPDATA}/local")
else()
   # Fallback for other systems
   set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}")
endif()
##################################################################################
# Install library to DEFAULT_LIBRARY_INSTALL_DIR  and module files to $CMAKE_INSTALL_PREFIX/lib
install(TARGETS M_CLI2
    ARCHIVE DESTINATION lib
    PERMISSIONS OWNER_WRITE OWNER_READ
    GROUP_EXECUTE GROUP_READ
    WORLD_EXECUTE WORLD_READ
)
# Install include/*.mod to  module files to $CMAKE_INSTALL_PREFIX/include
install(DIRECTORY "${BUILD_DIR}/include/"
    DESTINATION include
    FILES_MATCHING PATTERN "*.mod"
    PERMISSIONS OWNER_WRITE OWNER_READ
    GROUP_EXECUTE GROUP_READ
    WORLD_EXECUTE WORLD_READ
)

# Ensure CMake generates files in build/
set(CMAKE_CACHEFILE_DIR ${BUILD_DIR})
set(CMAKE_CONFIGURE_DEPENDS ${BUILD_DIR}/CMakeCache.txt)
