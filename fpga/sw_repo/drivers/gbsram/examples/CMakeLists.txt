# BSP Import Examples build: Vitis supplies instance/example metadata and linker.
# Building an ELF never runs it; review each example's safety settings first.
# License details: LICENSE.md at repository root.
# CMake shape follows AMD embeddedsw gpio_v4_12 example build interface.
# Original template Copyright (C) 2023-2024 Advanced Micro Devices, Inc.
# Copyright (c) 2021 Xilinx, Inc. SPDX-License-Identifier: MIT
cmake_minimum_required(VERSION 3.15)
include(${CMAKE_CURRENT_SOURCE_DIR}/GbsramExample.cmake)
project(gbsram_examples)
find_package(common)
enable_language(C ASM)
collect(PROJECT_LIB_DEPS xilstandalone)
collect(PROJECT_LIB_DEPS xil)
collect(PROJECT_LIB_DEPS gcc)
collect(PROJECT_LIB_DEPS c)
collector_list(_deps PROJECT_LIB_DEPS)
set(DRIVER_INSTANCES "${NUM_DRIVER_INSTANCES}" CACHE STRING "Driver Instances")
set_property(CACHE DRIVER_INSTANCES PROPERTY STRINGS "${NUM_DRIVER_INSTANCES}")
set(index 0)
LIST_INDEX(${index} ${DRIVER_INSTANCES} "${NUM_DRIVER_INSTANCES}")
list(GET TOTAL_EXAMPLE_LIST ${index} ex_list)
list(GET REG_LIST ${index} reg)
set(EXAMPLE_LIST "${${ex_list}}" CACHE STRING "Driver Example List")
set_property(CACHE EXAMPLE_LIST PROPERTY STRINGS "${${ex_list}}")
linker_gen("${CMAKE_CURRENT_SOURCE_DIR}/linker_files/")
foreach(EXAMPLE ${EXAMPLE_LIST})
 string(REGEX REPLACE "\\.[^.]*$" "" target "${EXAMPLE}")
 add_executable(${target}.elf "${target}.c")
 target_compile_definitions(${target}.elf PRIVATE GB_EXAMPLE_CTRL_BASE=${reg})
 target_link_libraries(${target}.elf -Wl,--gc-sections -T"${CMAKE_SOURCE_DIR}/lscript.ld" -L"${CMAKE_SOURCE_DIR}/" -Wl,--start-group ${_deps} -Wl,--end-group)
endforeach()
