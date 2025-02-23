find_program(JSONGEN_PIP_EXECUTABLE pip REQUIRED)
find_program(JSONGEN_NINJA_EXECUTABLE ninja REQUIRED)

if(DEFINED CUSTOM_PYTHON_EXECUTABLE AND NOT CUSTOM_PYTHON_EXECUTABLE STREQUAL "")
    set(JSONGEN_PYTHON3_EXECUTABLE "${CUSTOM_PYTHON_EXECUTABLE}")
else()
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    set(JSONGEN_PYTHON3_EXECUTABLE "${Python3_EXECUTABLE}")
endif()

set(${JSONGEN_NAMESPACE}_OUTPUT_DIR "${CMAKE_BINARY_DIR}/${${JSONGEN_NAMESPACE}_PROJ_NAME}")
set(${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_DIR "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/.vscode")
set(${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_FILE "${${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_DIR}/settings.json")

# Normal Python package requirements
set(${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE "${CMAKE_SOURCE_DIR}/requirements.txt")
# Custom fetch requirements
set(${JSONGEN_NAMESPACE}_FETCH_REQUIREMENTS_FILE "${CMAKE_SOURCE_DIR}/fetch_requirements.txt")

set(${JSONGEN_NAMESPACE}_MAIN_SCRIPT "main.py")

# Install Python deps if present
if(EXISTS "${${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE}")
    add_custom_target(${JSONGEN_NAMESPACE}_InstallPythonDeps ALL
        COMMAND ${JSONGEN_PIP_EXECUTABLE} install --verbose -r "${${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE}"
        COMMENT "Installing Python dependencies for '${PROJ_NAME}'"
    )
else()
    message(WARNING
        "requirements.txt not found at '${${JSONGEN_NAMESPACE}_REQUIREMENTS_FILE}'. "
        "No Python dependencies installed."
    )
endif()

# Setup main script
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
        COMMENT "Making main.py executable on Unix-like systems"
    )
endif()

# Copy .py files from subdirectories
set(JSONGEN_SUB_DIRS src modules utilities tests)
foreach(SUB_DIR ${JSONGEN_SUB_DIRS})
    file(GLOB JSONGEN_PY_FILES "${CMAKE_SOURCE_DIR}/${SUB_DIR}/*.py")
    set(JSONGEN_DEST_DIR "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}/${SUB_DIR}")
    foreach(FILE ${JSONGEN_PY_FILES})
        add_custom_command(TARGET ${JSONGEN_NAMESPACE}_SetupPythonProject POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${JSONGEN_DEST_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy "${FILE}" "${JSONGEN_DEST_DIR}/"
        )
    endforeach()
endforeach()

# Optionally init Git
if(AUTO_GIT_INIT)
    find_program(JSONGEN_GIT_EXECUTABLE git REQUIRED)
    add_custom_command(
        TARGET ${JSONGEN_NAMESPACE}_SetupPythonProject POST_BUILD
        COMMAND ${JSONGEN_GIT_EXECUTABLE} init "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
        WORKING_DIRECTORY "${${JSONGEN_NAMESPACE}_OUTPUT_DIR}"
        COMMENT "Auto-initializing Git repository in output project"
    )
endif()
