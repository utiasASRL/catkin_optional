cmake_minimum_required(VERSION 2.8.3)
project(catkin_optional)

# (required) adds the macro definitions for catkin_optional
# use find_package(catkin_optional) once installed
# note: this will detect catkin and set up install paths
include(cmake/catkin_optional-extras.cmake)

# (optional) set up the build type (defaults to Release)
co_build_type()

# (optional) find simple (no modules/version requirement) required dependencies
# automatically included_directories() the *_INCLUDE_DIR(S)
# this is not required, and you can manually call find_package
co_find()

# (required) export and configure package
# the listed targets are also marked for installation
# this must come before exported target definitions
co_export(
  VERSION 0.1.0
  CFG_EXTRAS catkin_optional-extras.cmake)

# specify build targets
# e.g. add_library(${PROJECT_NAME} ${PROJECT_SOURCE} ${PROJECT_HEADERS})
# e.g. target_link_libraries(${PROJECT_NAME} ${depend1_LIBRARIES}

# (optional) install rules for exported items and package config
# this must come after co_export and exported target definitions
co_install()

# custom install rules for other files
install(DIRECTORY cmake/templates DESTINATION ${INSTALL_CMAKE_DIR})
