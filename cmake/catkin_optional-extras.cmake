### INITIALIZATION ###

# inclusion guard
if(${_CATKIN_OPTIONAL_INCLUDED_})
  return()
endif()
set(_CATKIN_OPTIONAL_INCLUDED_ TRUE)

# allow CMake 3.0+ to run without warnings
if(NOT CMAKE_MAJOR_VERSION LESS 3)
  cmake_policy(SET CMP0048 OLD) # Lets us manage PROJECT_VERSION
  cmake_policy(SET CMP0026 OLD) # Get the LOCATION target property
endif()

# remember our own directory (we installed other things here)
set(_CATKIN_OPTIONAL_DIR ${CMAKE_CURRENT_LIST_DIR})

# for parsing function arguments
include(CMakeParseArguments)

# allow catkin to be disabled in the cache, initialized by detecting if catkin ran cmake
if("${CATKIN_ON}" STREQUAL "")
  string(COMPARE NOTEQUAL "${CATKIN_DEVEL_PREFIX}" "" _CATKIN_ON_DEFAULT)
  set(CATKIN_ON ${_CATKIN_ON_DEFAULT} CACHE BOOL "Disable catkin, even if found" FORCE)
endif()

# if it's not disabled, try to find catkin
if(${CATKIN_ON})
  find_package(catkin)
  if(NOT ${catkin_FOUND})
    set(CATKIN_ON FALSE)
    message(STATUS "catkin_optional: catkin enabled but not found, using vanilla cmake.")
  endif()
endif()

if(CATKIN_ON)
  # catkin provides install paths
  set(DEF_INSTALL_LIB_DIR ${CATKIN_PACKAGE_LIB_DESTINATION})
  set(DEF_INSTALL_BIN_DIR ${CATKIN_PACKAGE_BIN_DESTINATION})
  set(DEF_INSTALL_INCLUDE_DIR ${CATKIN_GLOBAL_INCLUDE_DESTINATION})
  set(DEF_INSTALL_CMAKE_DIR ${CATKIN_PACKAGE_SHARE_DESTINATION})
  # also devel location for pre-install exports
  set(CMAKE_DEVEL_PREFIX ${CATKIN_DEVEL_PREFIX})
else()
  # sane default install paths for vanilla cmake
  set(DEF_INSTALL_LIB_DIR lib)
  set(DEF_INSTALL_BIN_DIR bin)
  set(DEF_INSTALL_INCLUDE_DIR include)
  if(WIN32 AND NOT CYGWIN)
    set(DEF_INSTALL_CMAKE_DIR CMake)
  else()
    set(DEF_INSTALL_CMAKE_DIR lib/cmake/${PROJECT_NAME})
  endif()
  set(CMAKE_DEVEL_PREFIX ${PROJECT_BINRARY_DIR})
endif()

# Offer the user the choice of overriding the installation directories
set(INSTALL_LIB_DIR ${DEF_INSTALL_LIB_DIR} CACHE PATH "Installation directory for libraries")
set(INSTALL_BIN_DIR ${DEF_INSTALL_BIN_DIR} CACHE PATH "Installation directory for executables")
set(INSTALL_INCLUDE_DIR ${DEF_INSTALL_INCLUDE_DIR} CACHE PATH "Installation directory for header files")
set(INSTALL_CMAKE_DIR ${DEF_INSTALL_CMAKE_DIR} CACHE PATH "Installation directory for CMake files")

# Make relative paths absolute (needed later on)
foreach(p LIB BIN INCLUDE CMAKE)
  set(var INSTALL_${p}_DIR)
  if(NOT IS_ABSOLUTE "${${var}}")
    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
  endif()
endforeach()

### FUNCTIONS ###

# configure build type
macro(co_build_type)
  # check that a build type was chosen, default to release
  if(NOT DEFINED CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "")
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      Release Debug RelWithDebInfo MinSizeRel)
  endif()
endmacro()

# find dependencies, and find catkin dependencies through catkin modules
macro(co_find)
  # find and record each dependency
  foreach(dep ${ARGN})
    find_package(${dep} REQUIRED)
    if("${CATKIN_ON}" AND "${${dep}_FOUND_CATKIN_PROJECT}")
      list(APPEND ${PROJECT_NAME}_CATKIN_BUILD_DEPENDS ${dep})
      list(APPEND ${PROJECT_NAME}_CATKIN_BUILD_DEPENDS_EXPORTED_TARGETS ${${dep}_EXPORTED_TARGETS})
    else()
      list(APPEND ${PROJECT_NAME}_CMAKE_BUILD_DEPENDS)
    endif()

    # auto include the dependency's includes
    include_directories(${${dep}_INCLUDE_DIRS} ${${dep}_INCLUDE_DIR})
    string(TOUPPER ${dep} DEP)
    if(NOT ${dep} STREQUAL ${DEP})
      include_directories(${${DEP}_INCLUDE_DIRS} ${${DEP}_INCLUDE_DIR})
    endif()
  endforeach()
endmacro()

function(_co_config)
  
endfunction()

# configuration for what to export during package config and install
macro(co_export)
  set(ARG_NAMES )
  cmake_parse_arguments(${PROJECT_NAME}
    "" # options
    "VERSION" # single-value
    "INCLUDE_DIRS;LIBRARIES;EXECUTABLES;DEPENDS;CFG_EXTRAS" # multi-value
    "${ARGN}") # args

  # convenience include
  include_directories(${${PROJECT_NAME}_INCLUDE_DIRS})

  # default to zero version
  if("${${PROJECT_NAME}_VERSION}" STREQUAL "")
    set(${PROJECT_NAME}_VERSION 0.0.0)
  endif()
  set(PROJECT_VERSION ${${PROJECT_NAME}_VERSION})
  
  # catkin package pass-through
  if(${CATKIN_ON})
    # create the package config file
    catkin_package(
      INCLUDE_DIRS ${${PROJECT_NAME}_INCLUDE_DIRS}
      LIBRARIES ${${PROJECT_NAME}_LIBRARIES}
      DEPENDS ${${PROJECT_NAME}_DEPENDS}
      CFG_EXTRAS ${${PROJECT_NAME}_CFG_EXTRAS})
  else()
    # export to cmake's database
    export(PACKAGE ${PROJECT_NAME})
    set(CONFIG_IN "${_CATKIN_OPTIONAL_DIR}/templates/catkin_optionalConfig.cmake.in")

    # generate package config for the build tree
    set(CONF_INCLUDE_DIRS ${${PROJECT_NAME}_INCLUDE_DIRS})
    set(CONF_LIBRARIES ${${PROJECT_NAME}_LIBRARIES})
    set(CONF_CFG_EXTRAS)
    foreach(cfg ${${PROJECT_NAME}_CFG_EXTRAS})
      if(NOT IS_ABSOLUTE ${cfg})
	set(cfg_ABS ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${cfg})
      else()
	set(cfg_ABS ${cfg})
      endif()
      list(APPEND CONF_CFG_EXTRAS ${cfg_ABS})
    endforeach()
    set(${PROJECT_NAME}_CFG_EXTRAS_ABS ${CONF_CFG_EXTRAS})
    configure_file(${CONFIG_IN}
      "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake" @ONLY)

    # generate package config version
    set(CONFIG_VERSION "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config-version.cmake")
    configure_file("${_CATKIN_OPTIONAL_DIR}/templates/catkin_optionalConfig-version.cmake.in"
      ${CONFIG_VERSION} @ONLY)

    # generate package config for the install
    set(CONF_INCLUDE_DIRS ${INSTALL_INCLUDE_DIR})
    set(CONF_LIBRARIES)
    foreach(targ ${${PROJECT_NAME}_LIBRARIES})
      get_target_property(targ_PATH ${targ} LOCATION)
      get_filename_component(targ_NAME ${targ_PATH} NAME)
      list(APPEND CONF_LIBRARIES "${INSTALL_LIB_DIR}/${targ_NAME}")
    endforeach()
    set(CONF_CFG_EXTRAS)
    foreach(cfg ${${PROJECT_NAME}_CFG_EXTRAS_ABS})
      get_filename_component(cfg_NAME ${cfg} NAME)
      list(APPEND CONF_CFG_EXTRAS "${INSTALL_CMAKE_DIR}/${cfg_NAME}")
    endforeach()
    set(CONFIG_INSTALL "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}Config.cmake")
    configure_file(${CONFIG_IN} ${CONFIG_INSTALL} @ONLY)
  endif()

  # generate package config for the uninstall
  set(UNINSTALL_CMAKE "${CMAKE_CURRENT_BINARY_DIR}/cmake-uninstall.cmake")
  configure_file("${_CATKIN_OPTIONAL_DIR}/templates/catkin_optional-uninstall.cmake.in"
    ${UNINSTALL_CMAKE} IMMEDIATE @ONLY)
endmacro()

# set install locations, and install include and libraries
macro(co_install)
  # actually install
  install(TARGETS ${${PROJECT_NAME}_LIBRARIES}
    LIBRARY DESTINATION ${INSTALL_LIB_DIR})
  install(TARGETS ${${PROJECT_NAME}_EXECUTABLES}
    RUNTIME DESTINATION ${INSTALL_BIN_DIR})
  foreach(inc ${${PROJECT_NAME}_INCLUDE_DIRS})
    install(DIRECTORY ${inc}/ DESTINATION ${INSTALL_INCLUDE_DIR})
  endforeach()
  install(FILES ${${PROJECT_NAME}_CFG_EXTRAS_ABS}
    DESTINATION ${INSTALL_CMAKE_DIR})
  if(NOT ${CATKIN_ON})
    install(FILES ${CONFIG_INSTALL} ${CONFIG_VERSION}
      DESTINATION ${INSTALL_CMAKE_DIR})
  endif()

  # uninstall target
  add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${UNINSTALL_CMAKE})
endmacro()
