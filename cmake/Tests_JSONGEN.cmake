if(JSONGEN_IS_ROOT_PROJECT)
    unset(JSONGEN_TEST_DIRECTORIES)

    function(jsongen_collect_tests BASE_DIR)
        file(GLOB ITEMS "${BASE_DIR}/*")
        foreach(ITEM ${ITEMS})
            if(IS_DIRECTORY "${ITEM}")
                get_filename_component(DIR_NAME "${ITEM}" NAME)
                if(DIR_NAME STREQUAL "tests")
                    list(APPEND JSONGEN_TEST_DIRECTORIES "${ITEM}")
                    set(JSONGEN_TEST_DIRECTORIES "${JSONGEN_TEST_DIRECTORIES}"
                        CACHE INTERNAL "Collected test directories (JSONGen)")
                else()
                    jsongen_collect_tests("${ITEM}")
                endif()
            endif()
        endforeach()
    endfunction()

    # Collect tests from _deps or anywhere else you'd like
    jsongen_collect_tests("${CMAKE_BINARY_DIR}/_deps")

    message(STATUS "Raw JSONGEN_TEST_DIRECTORIES: ${JSONGEN_TEST_DIRECTORIES}")
    string(REPLACE ";" "\n" JSONGEN_TEST_DIRS_OUTPUT "${JSONGEN_TEST_DIRECTORIES}")
    message(STATUS "Discovered test dirs:\n${JSONGEN_TEST_DIRS_OUTPUT}")

    enable_testing()

    foreach(TEST_DIR ${JSONGEN_TEST_DIRECTORIES})
        get_filename_component(PARENT_DIR "${TEST_DIR}" DIRECTORY)
        get_filename_component(TEST_NAME "${PARENT_DIR}" NAME)
        message(STATUS "Registering JSONGen test dir: ${TEST_DIR} (name: ${TEST_NAME})")

        add_test(NAME JSONGenTests_${TEST_NAME}
            COMMAND "${JSONGEN_PYTHON3_EXECUTABLE}" -m unittest discover
                    -s "${TEST_DIR}" -p "test_*.py"
            WORKING_DIRECTORY "${TEST_DIR}"
        )
    endforeach()

    # Generate VSCode settings referencing discovered tests
    if(JSONGEN_TEST_DIRECTORIES AND NOT JSONGEN_TEST_DIRECTORIES STREQUAL "")
        set(JSONGEN_TEST_DIRS_JSON "")
        foreach(TEST_DIR ${JSONGEN_TEST_DIRECTORIES})
            list(APPEND JSONGEN_TEST_DIRS_JSON "\"${TEST_DIR}\"")
        endforeach()
        string(JOIN "," JSONGEN_TEST_DIRS_JSON ${JSONGEN_TEST_DIRS_JSON})
        set(JSONGEN_MODULE_TEST_FOLDERS_JSON "[${JSONGEN_TEST_DIRS_JSON}]")
    else()
        set(JSONGEN_MODULE_TEST_FOLDERS_JSON "[]")
    endif()

    configure_file(
        "${CMAKE_SOURCE_DIR}/settings.json.in"
        "${${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_FILE}"
        @ONLY
    )
endif()
