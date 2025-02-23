if(JSONGEN_IS_ROOT_PROJECT)
    unset(JSONGEN_TEST_DIRECTORIES)

    function(jsongen_collect_tests BASE_DIR)
        file(GLOB ITEMS "${BASE_DIR}/*")
        foreach(ITEM ${ITEMS})
            if(IS_DIRECTORY "${ITEM}")
                get_filename_component(DIR_NAME "${ITEM}" NAME)
                if(DIR_NAME STREQUAL "tests")
                    list(APPEND JSONGEN_TEST_DIRECTORIES "${ITEM}")
                    set(JSONGEN_TEST_DIRECTORIES "${JSONGEN_TEST_DIRECTORIES}" CACHE INTERNAL "")
                else()
                    jsongen_collect_tests("${ITEM}")
                endif()
            endif()
        endforeach()
    endfunction()

    jsongen_collect_tests("${CMAKE_BINARY_DIR}/_deps")

    message(STATUS "Raw JSONGEN_TEST_DIRECTORIES: ${JSONGEN_TEST_DIRECTORIES}")
    string(REPLACE ";" "\n" JSONGEN_TEST_DIRS_OUTPUT "${JSONGEN_TEST_DIRECTORIES}")
    message(STATUS "Discovered test dirs:\n${JSONGEN_TEST_DIRS_OUTPUT}")

    enable_testing()

    foreach(TEST_DIR ${JSONGEN_TEST_DIRECTORIES})
        get_filename_component(PARENT_DIR "${TEST_DIR}" DIRECTORY)
        get_filename_component(TEST_NAME "${PARENT_DIR}" NAME)
        message(STATUS "Registering JSONGen test dir: ${TEST_DIR} => ${TEST_NAME}")

        add_test(NAME JSONGenTests_${TEST_NAME}
            COMMAND "${JSONGEN_PYTHON3_EXECUTABLE}" -m unittest discover
                    -s "${TEST_DIR}" -p "test_*.py"
            WORKING_DIRECTORY "${TEST_DIR}"
        )
    endforeach()

    # Build a JSON array for python.testing.unittestArgs
    set(JSONGEN_TEST_ARGS_LIST "")
    list(APPEND JSONGEN_TEST_ARGS_LIST "\"-v\"")

    foreach(TEST_DIR ${JSONGEN_TEST_DIRECTORIES})
        file(TO_CMAKE_PATH "${TEST_DIR}" TEST_DIR_CLEAN)
        list(APPEND JSONGEN_TEST_ARGS_LIST "\"-s\"")
        list(APPEND JSONGEN_TEST_ARGS_LIST "\"${TEST_DIR_CLEAN}\"")
    endforeach()

    list(APPEND JSONGEN_TEST_ARGS_LIST "\"-p\"")
    list(APPEND JSONGEN_TEST_ARGS_LIST "\"test_*.py\"")
    string(JOIN "," JSONGEN_UNITTEST_ARGS ${JSONGEN_TEST_ARGS_LIST})

    configure_file(
        "${CMAKE_SOURCE_DIR}/settings.json.in"
        "${${JSONGEN_NAMESPACE}_VSCODE_SETTINGS_FILE}"
        @ONLY
    )
endif()
