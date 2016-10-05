cmake_minimum_required(VERSION 2.8.3)
project(catkin_optional)

# use find_package(catkin_optional) once installed
include(cmake/catkin_optional-extras.cmake)

# set up the build type
co_build_type()

# find dependencies
co_find()

# configure package
co_export(
  VERSION 0.1.0
  CFG_EXTRAS catkin_optional-extras.cmake)

# install rules
co_install()
install(FILES cmake/catkin_optionalConfig.cmake.in
  DESTINATION ${INSTALL_CMAKE_DIR})