cmake_minimum_required(VERSION 3.15)

# ------------------------------------------------------------------
# Determine if root or dependency
# ------------------------------------------------------------------
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(JSONGEN_IS_ROOT_PROJECT TRUE)
else()
    set(JSONGEN_IS_ROOT_PROJECT FALSE)
endif()

# ------------------------------------------------------------------
# Load config.cmake
# ------------------------------------------------------------------
if(JSONGEN_IS_ROOT_PROJECT)
    set(JSONGEN_CONFIG_CMAKE_PATH "${CMAKE_SOURCE_DIR}/config.cmake")
else()
    set(JSONGEN_CONFIG_CMAKE_PATH "${CMAKE_CURRENT_LIST_DIR}/config.cmake")
endif()

if(NOT EXISTS "${JSONGEN_CONFIG_CMAKE_PATH}")
    message(FATAL_ERROR "Configuration file not found at: ${JSONGEN_CONFIG_CMAKE_PATH}")
endif()

include("${JSONGEN_CONFIG_CMAKE_PATH}")

if(NOT DEFINED PROJ_NAME OR PROJ_NAME STREQUAL "")
    message(FATAL_ERROR "No project name found in config.cmake for PYLib-JSONGenerator.")
endif()

# ------------------------------------------------------------------
# Use a distinct namespace to avoid collisions
# ------------------------------------------------------------------
set(JSONGEN_NAMESPACE ${PROJ_NAME})
set(${JSONGEN_NAMESPACE}_PROJ_NAME "${PROJ_NAME}")

project(${PROJ_NAME} LANGUAGES NONE)

# ------------------------------------------------------------------
# Add path for .cmake modules
# ------------------------------------------------------------------
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# ------------------------------------------------------------------
# Include refactored modules for Python, fetching, tests
# ------------------------------------------------------------------
include(PythonSetup_JSONGEN)
include(FetchModules_JSONGEN)
include(Tests_JSONGEN)

# ------------------------------------------------------------------
# Final target
# ------------------------------------------------------------------
add_custom_target(${JSONGEN_NAMESPACE}_FinishSetup
    COMMAND ${CMAKE_COMMAND} -E echo "Python project setup is complete!"
    COMMAND ${CMAKE_COMMAND} -E echo "Output directory: ${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
    DEPENDS ${JSONGEN_NAMESPACE}_SetupPythonProject
)
