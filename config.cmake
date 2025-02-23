# Optional custom Python interpreter
set(CUSTOM_PYTHON_EXECUTABLE "" CACHE STRING "Optional custom Python path")

# Distinct name for the subproject
set(PROJ_NAME "PYLib-JSONGenerator" CACHE STRING "Subproject name")

option(AUTO_GIT_INIT "Auto-initialize git" ON)
option(OPTIONAL_MODULES "Enable optional modules" OFF)
