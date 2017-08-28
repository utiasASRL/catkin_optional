# catkin optional

This `CMake` project allows other projects to be compiled, exported and installed with or without `catkin`.

It is inspired by [`catkin_simple`](https://github.com/catkin/catkin_simple), and generously borrows concepts.

- [Example](#example)
- [Commands](#commands)
- [Variables](#variables)

# Example

**`CMakeLists.txt`**
```CMake
cmake_minimum_required(VERSION 2.8.3)
project(myproject)

# (required) adds the macro definitions for catkin_optional
# note: this will detect catkin and set up install paths
find_package(catkin_optional)

# (optional) set up the build type cache variable (defaults to Release)
co_build_type()

# (optional) find simple (no modules/version requirement) required dependencies
# automatically included_directories() (dep|DEP)_INCLUDE_DIR(S)
# we don't concatenate dependency libraries, to suppress the urge to overlink
co_find(dep1 dep2)
# co_find is not required, you can manually call find_package
find_package(dep3 VERSION 1.2)
include_directories(${dep3_INCLUDE_DIRS})

# (required) export and configure package
# the listed targets are also marked for installation
# this must come before exported target definitions
co_export(
  VERSION 0.1.0
  INCLUDE_DIRS include
  LIBRARIES ${PROJECT_NAME}
  DEPENDS dep1
  CFG_EXTRAS myproject-extras.cmake)

# find source files (force cmake to index added/removed files)
file(GLOB_RECURSE HEADERS include/*.hpp)
file(GLOB_RECURSE LIB_SOURCE src/lib/*.cpp)
file(GLOB_RECURSE BIN_SOURCE src/bin/*.cpp)

# specify build targets
add_library(${PROJECT_NAME} ${LIB_SOURCE} ${HEADERS})
target_link_libraries(${PROJECT_NAME} ${dep1_LIBRARIES})
add_executable(mybin ${BIN_SOURCE})
target_link_libraries(mybin ${PROJECT_NAME} ${dep3_LIBRARIES})

# (optional) install rules for exported items and package config
# this must come after co_export and exported target definitions
co_install()

# custom install rules for other files
install(DIRECTORY configs DESTINATION ${INSTALL_BIN_DIR})

```
See below for more information on the commands

**`package.xml`**
```XML
<package>
  <name>mypackage</name>
  <description>
    My awesome package.
  </description>
  <version>0.0.0</version>
  <maintainer email="something@somehere.tld">My Name</maintainer>
  <license>WTFPL</license>

  <buildtool_depend>catkin</buildtool_depend>
  <buildtool_depend>catkin_optional</buildtool_depend>
  
  <build_depend>dep1</build_depend>
  <run_depend>dep1</run_depend>
</package>
```
The main difference to catkin is the additional `buildtool_depend` on `catkin_optional`.

# Commands

### co_build_type()
```co_build_type()```

Initializes `CMAKE_BUILD_TYPE` cache variable, and enumerates the options.

### co_find()
```co_find([deps...])```

Finds the dependency, and adds its libraries to `${PROJECT_NAME}_DEPEND_LIBRARIES`, and `include_directories` its includes.

### co_export()
```
co_export([VERSION 1.2.3] [INCLUDE_DIRS includes...] [LIBRARIES libraries...]
          [EXECUTABLES executables...] [DEPENDS deps...] [CFG_EXTRAS extras...])
```

This calls `catkin_package` if catkin is available, otherwise, it prepares the cmake config files and installation lists.

### co_install()
```co_install()```

Creates the install target.

# Variables

TODO: document the input / output `CMake` variables that are expected to be stable.
