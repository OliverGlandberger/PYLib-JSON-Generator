cmake_minimum_required(VERSION 3.15)

# Find executables
find_program(PIP_EXECUTABLE pip REQUIRED)
find_program(NINJA_EXECUTABLE ninja REQUIRED)
if(DEFINED CUSTOM_PYTHON_EXECUTABLE AND NOT CUSTOM_PYTHON_EXECUTABLE STREQUAL "")
    set(Python3_EXECUTABLE "${CUSTOM_PYTHON_EXECUTABLE}")
else()
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
endif()

# Determine if this project is being fetched or built independently
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # Top-level project
    set(IS_ROOT_PROJECT TRUE)
else()
    # Included as a dependency
    set(IS_ROOT_PROJECT FALSE)
endif()

# Load configurations based on context
if(IS_ROOT_PROJECT)
    set(CONFIG_CMAKE_PATH "${CMAKE_SOURCE_DIR}/config.cmake")
else()
    set(CONFIG_CMAKE_PATH "${CMAKE_CURRENT_LIST_DIR}/config.cmake")
endif()
if(EXISTS "${CONFIG_CMAKE_PATH}")
    message(STATUS "Loading config.cmake from: ${CONFIG_CMAKE_PATH}")
    include("${CONFIG_CMAKE_PATH}")
else()
    message(FATAL_ERROR "Configuration file not found at: ${CONFIG_CMAKE_PATH}")
endif()

# Ensure project name is defined
if(NOT DEFINED PROJ_NAME OR PROJ_NAME STREQUAL "")
    message(FATAL_ERROR "No project name found. Make sure 'config.cmake' sets the 'PROJ_NAME' variable.")
endif()
# Set the project's name
if (NOT IS_ROOT_PROJECT)
    set(CMAKE_PROJECT_NAME ${PROJ_NAME})
endif()
project(${PROJ_NAME} LANGUAGES NONE)

# Define namespace
set(NAMESPACE ${PROJ_NAME})
set(${NAMESPACE}_PROJ_NAME "${PROJ_NAME}")

message(STATUS "${${NAMESPACE}_PROJ_NAME}: Configuring project")

# Define output directories and files with namespace
set(${NAMESPACE}_OUTPUT_PROJECT_DIR "${CMAKE_BINARY_DIR}/${${NAMESPACE}_PROJ_NAME}")
set(${NAMESPACE}_VSCODE_SETTINGS_DIR "${${NAMESPACE}_OUTPUT_PROJECT_DIR}/.vscode")
set(${NAMESPACE}_VSCODE_SETTINGS_FILE "${${NAMESPACE}_VSCODE_SETTINGS_DIR}/settings.json")
set(${NAMESPACE}_REQUIREMENTS_FILE "${CMAKE_SOURCE_DIR}/requirements.txt")
set(${NAMESPACE}_MAIN_SCRIPT "main.py")

# Install Python dependencies if requirements.txt exists
if(EXISTS ${${NAMESPACE}_REQUIREMENTS_FILE})
    add_custom_target(${NAMESPACE}_InstallPythonDependencies ALL
        COMMAND ${PIP_EXECUTABLE} install --verbose -r ${${NAMESPACE}_REQUIREMENTS_FILE}
        COMMENT "Installing Python dependencies for '${PROJ_NAME}' using 'requirements.txt'"
    )
else()
    message(WARNING "The 'requirements.txt' was not found at '${${NAMESPACE}_REQUIREMENTS_FILE}'. Python dependencies will not be installed.")
endif()

# Setup project directories and copy 'main.py'
add_custom_target(${NAMESPACE}_SetupPythonProject ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${${NAMESPACE}_OUTPUT_PROJECT_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/${${NAMESPACE}_MAIN_SCRIPT}" "${${NAMESPACE}_OUTPUT_PROJECT_DIR}/"
    COMMENT "Setting up project '${${NAMESPACE}_PROJ_NAME}'."
    DEPENDS ${NAMESPACE}_InstallPythonDependencies
)

# Add chmod +x for Unix-like systems
if(UNIX)
    add_custom_command(TARGET ${NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E chmod +x "${${NAMESPACE}_OUTPUT_PROJECT_DIR}/${${NAMESPACE}_MAIN_SCRIPT}"
        COMMENT "Setting executable permission on main.py"
    )
endif()

# Handle file copying
set(SUB_DIRS src modules utilities tests)
foreach(SUB_DIR ${SUB_DIRS})
    file(GLOB FILES "${CMAKE_SOURCE_DIR}/${SUB_DIR}/*.py")
    set(DEST_DIR "${${NAMESPACE}_OUTPUT_PROJECT_DIR}/${SUB_DIR}")
    foreach(FILE ${FILES})
        add_custom_command(TARGET ${NAMESPACE}_SetupPythonProject POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEST_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy "${FILE}" "${DEST_DIR}/"
        )
    endforeach()
endforeach()

# If this is the root project, find/add all tests
if (IS_ROOT_PROJECT)
    # Recursively glob everything under "_deps", then filter out all "tests" dirs
    file(GLOB_RECURSE ALL_POSSIBLE_TEST_DIRS "${CMAKE_BINARY_DIR}/_deps")
    set(${NAMESPACE}_MODULE_TEST_DIRS "") 
    foreach(DIR ${ALL_POSSIBLE_TEST_DIRS})
        if(IS_DIRECTORY ${DIR} AND DIR MATCHES "(^|.*/|.\\\\)tests$")
            list(APPEND ${NAMESPACE}_MODULE_TEST_DIRS ${DIR})
        endif()
    endforeach()
    # Convert list of test dirs to a comma-separated string
    if(NOT "${${NAMESPACE}_MODULE_TEST_DIRS}" STREQUAL "")
        list(JOIN ${${NAMESPACE}_MODULE_TEST_DIRS} "\",\"" MODULE_TEST_FOLDERS)
        set(MODULE_TEST_FOLDERS_JSON "[\"${MODULE_TEST_FOLDERS}\"]")
    else()
        set(MODULE_TEST_FOLDERS_JSON "[]")
    endif()
    # Generate settings.json in the build directory
    configure_file(
        "${CMAKE_SOURCE_DIR}/settings.json.in"
        "${${NAMESPACE}_VSCODE_SETTINGS_FILE}" @ONLY
    )

    enable_testing()
    add_test(NAME PythonTests
        COMMAND "${Python3_EXECUTABLE}" -m unittest discover -s "${${NAMESPACE}_OUTPUT_PROJECT_DIR}/tests" -p "test_*.py"
        WORKING_DIRECTORY "${${NAMESPACE}_OUTPUT_PROJECT_DIR}"
    )
    # Add tests for imported projects
    foreach(TEST_DIR ${${NAMESPACE}_MODULE_TEST_DIRS})
        get_filename_component(TEST_NAME ${TEST_DIR} NAME_WE)
        string(REPLACE "/" "_" TEST_NAME ${TEST_NAME})  # Sanitize for uniqueness
        add_test(NAME ModuleTests_${TEST_NAME}
            COMMAND "${Python3_EXECUTABLE}" -m unittest discover -s "${TEST_DIR}" -p "test_*.py"
            WORKING_DIRECTORY "${TEST_DIR}"
        )
    endforeach()
    message(STATUS "Discovered test directories: ${${NAMESPACE}_MODULE_TEST_DIRS}")
endif()

# Optionally initialize Git in the output project
if(AUTO_GIT_INIT)
    find_program(GIT_EXECUTABLE git REQUIRED)
    add_custom_command(
        TARGET ${NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND git init "${${NAMESPACE}_OUTPUT_PROJECT_DIR}"
        WORKING_DIRECTORY "${${NAMESPACE}_OUTPUT_PROJECT_DIR}"
        COMMENT "Auto-initializing Git repository in output project"
    )
endif()

# Final setup
add_custom_target(${NAMESPACE}_FinishSetup
    COMMAND ${CMAKE_COMMAND} -E echo "Python project setup is complete!"
    COMMAND ${CMAKE_COMMAND} -E echo "Output directory: ${${NAMESPACE}_OUTPUT_PROJECT_DIR}"
    DEPENDS ${NAMESPACE}_SetupPythonProject
)
message(STATUS "${${NAMESPACE}_PROJ_NAME}: Finished configuring project")
