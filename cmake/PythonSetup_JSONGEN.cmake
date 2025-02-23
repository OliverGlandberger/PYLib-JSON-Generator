find_program(JSONGEN_NINJA_EXECUTABLE ninja REQUIRED)

if(DEFINED CUSTOM_PYTHON_EXECUTABLE AND NOT CUSTOM_PYTHON_EXECUTABLE STREQUAL "")
    set(JSONGEN_PYTHON3_EXECUTABLE "${CUSTOM_PYTHON_EXECUTABLE}")
else()
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    set(JSONGEN_PYTHON3_EXECUTABLE "${Python3_EXECUTABLE}")
endif()

set(${JSONGEN_NAMESPACE}_MAIN_SCRIPT "main.py")
set(${JSONGEN_NAMESPACE}_OUTPUT_DIR "${CMAKE_BINARY_DIR}/${${JSONGEN_NAMESPACE}_PROJ_NAME}")
set(${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_DIR "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/.vscode")
set(${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_FILE "${${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_DIR}/settings.json")
set(${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE "${CMAKE_SOURCE_DIR}/requirements.txt")

if(JSONGEN_IS_ROOT_PROJECT)
    set(${JSONGEN_NAMESPACE}_FETCH_REQUIREMENTS_FILE "${CMAKE_SOURCE_DIR}/fetch_requirements.txt")
else()
    set(${JSONGEN_NAMESPACE}_FETCH_REQUIREMENTS_FILE "${CMAKE_CURRENT_LIST_DIR}/fetch_requirements.txt")
endif()

# Install Python deps
if(EXISTS "${${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE}")
    add_custom_target(${JSONGEN_NAMESPACE}_InstallPythonDeps ALL
        COMMAND "${JSONGEN_PYTHON3_EXECUTABLE}" -m pip install --verbose
                -r "${${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE}"
        COMMENT "Installing Python dependencies for '${PROJ_NAME}'"
    )
else()
    message(WARNING "No requirements.txt found for JSONGen.")
endif()

# If not root, skip
if(NOT JSONGEN_IS_ROOT_PROJECT)
    return()
endif()

add_custom_target(${JSONGEN_NAMESPACE}_SetupPythonProject ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_SOURCE_DIR}/${${JSONGEN_NAMESPACE}_MAIN_SCRIPT}"
            "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/"
    COMMENT "Setting up project '${${JSONGEN_NAMESPACE}_PROJ_NAME}'"
    DEPENDS ${JSONGEN_NAMESPACE}_InstallPythonDeps
)

if(UNIX)
    add_custom_command(TARGET ${JSONGEN_NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E chmod +x
                "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/${${JSONGEN_NAMESPACE}_MAIN_SCRIPT}"
        COMMENT "Making main.py executable on Unix"
    )
endif()

# Copy subproject's src/*.py
file(GLOB JSONGEN_SRC_FILES "${CMAKE_SOURCE_DIR}/src/*.py")
foreach(FILE_PATH ${JSONGEN_SRC_FILES})
    add_custom_command(TARGET ${JSONGEN_NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
                "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/src"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${FILE_PATH}"
                "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/src/"
    )
endforeach()

# Copy subproject's modules/*.py
file(GLOB JSONGEN_MODULE_FILES "${CMAKE_SOURCE_DIR}/modules/*.py")
foreach(FILE_PATH ${JSONGEN_MODULE_FILES})
    add_custom_command(TARGET ${JSONGEN_NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
                "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/modules"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${FILE_PATH}"
                "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/modules/"
    )
endforeach()

# We omit copying "tests" here since we do that at configure time in Tests_JSONGEN.cmake.

# Optionally init Git
if(AUTO_GIT_INIT)
    find_program(JSONGEN_GIT_EXECUTABLE git REQUIRED)
    add_custom_command(
        TARGET ${JSONGEN_NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND ${JSONGEN_GIT_EXECUTABLE} init "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
        WORKING_DIRECTORY "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
        COMMENT "Auto-initializing Git repository"
    )
endif()
