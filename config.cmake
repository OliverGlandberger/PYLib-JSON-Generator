# Set a custom Python interpreter path (if needed)
set(CUSTOM_PYTHON_EXECUTABLE "" CACHE STRING "Optional custom Python interpreter path")

# Set custom output directory (default is GeneratedPythonProject)
set(CUSTOM_OUTPUT_PROJECT_NAME "" CACHE STRING "Optional custom output project name")

# Enable automatic git initialization
option(AUTO_GIT_INIT "Enables optional auto-initialization of local git repository" ON)

# Enable optional features (like extra modules or utilities)
option(OPTIONAL_MODULES "Enable optional Python modules" OFF)
