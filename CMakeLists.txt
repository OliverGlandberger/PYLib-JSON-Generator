cmake_minimum_required(VERSION 3.15)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(JSONGEN_IS_ROOT_PROJECT TRUE)
else()
    set(JSONGEN_IS_ROOT_PROJECT FALSE)
endif()

if(JSONGEN_IS_ROOT_PROJECT)
    set(JSONGEN_CONFIG_CMAKE_PATH "${CMAKE_SOURCE_DIR}/config.cmake")
else()
    set(JSONGEN_CONFIG_CMAKE_PATH "${CMAKE_CURRENT_LIST_DIR}/config.cmake")
endif()

if(NOT EXISTS "${JSONGEN_CONFIG_CMAKE_PATH}")
    message(FATAL_ERROR "Config file not found at: ${JSONGEN_CONFIG_CMAKE_PATH}")
endif()

include("${JSONGEN_CONFIG_CMAKE_PATH}")

# Check if a project name override has been passed by the parent project
if(DEFINED PROJECT_OVERRIDE_NAME AND NOT PROJECT_OVERRIDE_NAME STREQUAL "")
    set(PROJ_NAME ${PROJECT_OVERRIDE_NAME})
endif()

if(NOT DEFINED PROJ_NAME OR PROJ_NAME STREQUAL "")
    message(FATAL_ERROR "No project name set in config.cmake for PYLib-JSONGenerator.")
endif()

project(${PROJ_NAME} LANGUAGES NONE)

set(JSONGEN_NAMESPACE "${PROJ_NAME}")
set(${JSONGEN_NAMESPACE}_PROJ_NAME "${PROJ_NAME}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(PythonSetup_JSONGEN)
include(FetchModules_JSONGEN)
include(Tests_JSONGEN)

if(JSONGEN_IS_ROOT_PROJECT)
    add_custom_target(${JSONGEN_NAMESPACE}_FinishSetup
        COMMAND ${CMAKE_COMMAND} -E echo "Python project setup is complete!"
        COMMAND ${CMAKE_COMMAND} -E echo "Output directory: ${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
        DEPENDS ${JSONGEN_NAMESPACE}_SetupPythonProject
    )
endif()
