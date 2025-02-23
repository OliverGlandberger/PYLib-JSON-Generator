function(jsongen_fetch_and_configure_module repo_name namespace git_repo git_tag output_dir_var)
    include(FetchContent)
    set(FETCHCONTENT_QUIET OFF)

    FetchContent_Declare(
        ${repo_name}
        GIT_REPOSITORY ${git_repo}
        GIT_TAG        ${git_tag}
    )
    set(${output_dir_var} "${CMAKE_BINARY_DIR}/modules/${repo_name}")

    FetchContent_MakeAvailable(${repo_name})
    FetchContent_GetProperties(${repo_name})

    if(NOT ${repo_name}_POPULATED)
        message(FATAL_ERROR "Failed to populate ${repo_name}")
    else()
        message(STATUS "Successfully populated ${repo_name}")
        message(STATUS "Source Dir: ${${repo_name}_SOURCE_DIR}")
        message(STATUS "Binary Dir: ${${repo_name}_BINARY_DIR}")
    endif()
endfunction()

function(jsongen_fetch_requirements_file file_path)
    if(NOT EXISTS "${file_path}")
        message(STATUS "No fetch_requirements.txt found at: ${file_path}")
        return()
    endif()

    message(STATUS "Reading JSONGen fetch requirements from: ${file_path}")
    file(STRINGS "${file_path}" LINES)

    foreach(LINE ${LINES})
        string(STRIP "${LINE}" LINE)
        if(LINE MATCHES "^(#|$)")
            continue()
        endif()

        string(REPLACE "|" ";" RAW_TOKENS "${LINE}")
        list(LENGTH RAW_TOKENS NUM_TOKENS)
        if(NOT NUM_TOKENS EQUAL 4)
            message(FATAL_ERROR
                "Invalid line in fetch_requirements.txt:\n  ${LINE}\n"
                "Expected 4 parts separated by '|'."
            )
        endif()

        # Trim extra spaces
        set(TOKENS "")
        foreach(TOKEN ${RAW_TOKENS})
            string(STRIP "${TOKEN}" TOKEN)
            list(APPEND TOKENS "${TOKEN}")
        endforeach()

        list(GET TOKENS 0 REPO_NAME)
        list(GET TOKENS 1 REPO_NAMESPACE)
        list(GET TOKENS 2 GIT_REPO)
        list(GET TOKENS 3 GIT_TAG)

        set(OUTPUT_DIR_VAR "${REPO_NAME}_OUTPUT_DIR")

        jsongen_fetch_and_configure_module(
            "${REPO_NAME}" "${REPO_NAMESPACE}"
            "${GIT_REPO}"  "${GIT_TAG}"
            "${OUTPUT_DIR_VAR}"
        )
    endforeach()
endfunction()

# Trigger JSONGen’s local fetch_requirements.txt
jsongen_fetch_requirements_file("${${JSONGEN_NAMESPACE}_FETCH_REQUIREMENTS_FILE}")
