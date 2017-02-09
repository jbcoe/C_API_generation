# ffig_add_library
# ----------------
#
# This module defines a function that allows the user to add a build target
# that constructs a shared library with a C-API and optional language bindings
# that make use of the C-API. 
#
# FIXME: Make output directory user-configurable.
# Currently the generated bindings and libraries go into ${CMAKE_BINARY_DIR}/generated.
#
# Usage:
#
# ffig_add_library(NAME myModuleName INPUTS myHeader.h RUBY PYTHON)
#
# This will create a build target called myModuleName_c which creates a shared library:
# * libmyModuleName.so on Linux
# * libmyModuleName.dylib on macOS
# * myModuleName.dll on Windows
#
# NAME is required, 
# FIXME: relax constraints on INPUTS
# INPUTS currently supports only a single header file (which must have only standard library includes).
#
# Optional bindings can be created by passing in any of the optional arguments:
# * RUBY - creates myModuleName.rb
# * PYTHON - creates myModuleName.py
# * CPP - creates myModuleName_cpp.h
# * CPP_MOCKS - creates myModuleName_mocks.h

function(ffig_add_library)
  set(options RUBY PYTHON CPP CPP_MOCKS)
  set(oneValueArgs NAME INPUTS)
  cmake_parse_arguments(ffig_add_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(module ${ffig_add_library_NAME})
  set(input ${ffig_add_library_INPUTS})

  set(ffig_invocation "-i;${input};-m;${module};-o;${CMAKE_BINARY_DIR}/generated;-b;_c.h.tmpl;_c.cpp.tmpl")
  set(ffig_outputs "${CMAKE_BINARY_DIR}/generated/${module}_c.h;${CMAKE_BINARY_DIR}/generated/${module}_c.cpp")  
  set(ffig_output_dir "${CMAKE_BINARY_DIR}/generated")

  if(ffig_add_library_RUBY)
    set(ffig_invocation "${ffig_invocation};rb.tmpl")
    set(ffig_outputs "${ffig_outputs};${ffig_output_dir}/${module}.rb")
  endif()
  if(ffig_add_library_PYTHON)
    set(ffig_invocation "${ffig_invocation};py.tmpl")
    set(ffig_outputs "${ffig_outputs};${ffig_output_dir}/${module}.py")
  endif()
  if(ffig_add_library_CPP_MOCKS)
    set(ffig_invocation "${ffig_invocation};_mocks.h.tmpl")
    set(ffig_outputs "${ffig_outputs};${ffig_output_dir}/${module}_mocks.h")
  endif()
  if(ffig_add_library_CPP)
    set(ffig_invocation "${ffig_invocation};_cpp.h.tmpl")
    set(ffig_outputs "${ffig_outputs};${ffig_output_dir}/${module}_cpp.h")
  endif()

  add_custom_command(OUTPUT ${ffig_outputs}
    COMMAND ${PYTHON_EXECUTABLE} ffig/FFIG.py ${ffig_invocation}
    DEPENDS ${input}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

  # FIXME: This is a bit ugly. The header is copied next to the generated bindings.
  file(COPY ${input} DESTINATION ${ffig_output_dir}/)

  add_library(${module}_c SHARED ${input} ${ffig_output_dir}/${module}_c.h ${ffig_output_dir}/${module}_c.cpp)

  # FIXME: This is a bit ugly. The shared library is copied next to the generated bindings.
  add_custom_command(TARGET ${module}_c
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${module}_c> ${ffig_output_dir}/)
endfunction()

