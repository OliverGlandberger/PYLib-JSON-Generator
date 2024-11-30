cmake_minimum_required(VERSION 3.15)
project(PYLib-JSON-Generator LANGUAGES NONE)

# Load optional configurations
include("${CMAKE_SOURCE_DIR}/config.cmake" OPTIONAL)

# Check for Python3 (OPTIONAL: Custom Python Interpreter)
if(DEFINED CUSTOM_PYTHON_EXECUTABLE AND NOT CUSTOM_PYTHON_EXECUTABLE STREQUAL "")
    set(Python3_EXECUTABLE "${CUSTOM_PYTHON_EXECUTABLE}")
else()
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    if(NOT Python3_FOUND)
        message(FATAL_ERROR "Python3 not found. Please install Python3 on your system or specify a custom interpreter in config.cmake.")
    endif()
endif()

# Find pip executable
find_program(PIP_EXECUTABLE pip)
if(NOT PIP_EXECUTABLE)
    message(FATAL_ERROR "pip not found. Please ensure pip is installed and accessible from your PATH.")
endif()

# Set custom output project name if provided
if(DEFINED CUSTOM_OUTPUT_PROJECT_NAME AND NOT CUSTOM_OUTPUT_PROJECT_NAME STREQUAL "")
    set(OUTPUT_PROJECT_NAME "${CUSTOM_OUTPUT_PROJECT_NAME}")
else()
    set(OUTPUT_PROJECT_NAME "GeneratedPythonProject")
endif()

# Define output directories and files
set(OUTPUT_PROJECT_DIR "${CMAKE_BINARY_DIR}/${OUTPUT_PROJECT_NAME}")
set(VSCODE_SETTINGS_DIR "${OUTPUT_PROJECT_DIR}/.vscode")
set(VSCODE_SETTINGS_FILE "${VSCODE_SETTINGS_DIR}/settings.json")
set(REQUIREMENTS_FILE "${CMAKE_SOURCE_DIR}/requirements.txt")
set(MAIN_SCRIPT "main.py")

# Install Python dependencies from requirements.txt
if(EXISTS ${REQUIREMENTS_FILE})
    add_custom_target(InstallPythonDependencies ALL
        COMMAND ${PIP_EXECUTABLE} install -r ${REQUIREMENTS_FILE}
        COMMENT "Installing Python dependencies from requirements.txt"
    )
else()
    message(WARNING "requirements.txt not found. Skipping Python dependency installation.")
endif()

# Create the output project directory and copy main.py
add_custom_target(SetupPythonProject ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${OUTPUT_PROJECT_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/${MAIN_SCRIPT}" "${OUTPUT_PROJECT_DIR}/"
    COMMENT "Setting up output Python project with main.py as entry point"
    DEPENDS InstallPythonDependencies
)

# Add chmod +x to 'main.py' (Unix-like systems)
if(UNIX)
    add_custom_command(TARGET SetupPythonProject POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E chmod +x "${OUTPUT_PROJECT_DIR}/${MAIN_SCRIPT}"
        COMMENT "Setting executable permission on main.py"
    )
endif()

# Copy project files
file(GLOB SRC_FILES    "${CMAKE_SOURCE_DIR}/src/*.py")
file(GLOB MODULE_FILES "${CMAKE_SOURCE_DIR}/modules/*.py")
file(GLOB UTIL_FILES   "${CMAKE_SOURCE_DIR}/utilities/*.py")
file(GLOB TEST_FILES   "${CMAKE_SOURCE_DIR}/tests/*.py")

foreach(FILE ${SRC_FILES} ${MODULE_FILES} ${UTIL_FILES} ${TEST_FILES})
    # Determine the destination folder
    if(FILE IN_LIST SRC_FILES)
        set(DEST_DIR "${OUTPUT_PROJECT_DIR}/src")
    elseif(FILE IN_LIST MODULE_FILES)
        set(DEST_DIR "${OUTPUT_PROJECT_DIR}/modules")
    elseif(FILE IN_LIST UTIL_FILES)
        set(DEST_DIR "${OUTPUT_PROJECT_DIR}/utilities")
    elseif(FILE IN_LIST TEST_FILES)
        set(DEST_DIR "${OUTPUT_PROJECT_DIR}/tests")
    else()
        set(DEST_DIR "${OUTPUT_PROJECT_DIR}")
    endif()
    # Copy files to appropriate location(s)
    add_custom_command(TARGET SetupPythonProject POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEST_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy "${FILE}" "${DEST_DIR}/"
        COMMENT "Copying ${FILE} to output directory ${DEST_DIR}"
    )
endforeach()

# Enable testing and run tests with the system Python interpreter
enable_testing()
add_test(NAME PythonTests
    COMMAND "${Python3_EXECUTABLE}" -m unittest discover -s "${OUTPUT_PROJECT_DIR}/tests"
    WORKING_DIRECTORY "${OUTPUT_PROJECT_DIR}"
)

# Optionally initialize Git in the output project
if(AUTO_GIT_INIT)
    add_custom_command(
        TARGET SetupPythonProject POST_BUILD
        COMMAND git init "${OUTPUT_PROJECT_DIR}"
        WORKING_DIRECTORY "${OUTPUT_PROJECT_DIR}"
        COMMENT "Auto-initializing Git repository in output project"
    )
endif()

# Ensure .vscode directory exists
add_custom_command(
    TARGET SetupPythonProject POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${VSCODE_SETTINGS_DIR}"
)
# Configure the settings.json file from the template
configure_file(
    "${CMAKE_SOURCE_DIR}/settings.json.in"
    "${VSCODE_SETTINGS_FILE}"
    COPYONLY
)

# Final message to indicate setup completion
add_custom_target(FinishSetup
    COMMAND ${CMAKE_COMMAND} -E echo "Python project setup is complete!"
    DEPENDS SetupPythonProject
)
