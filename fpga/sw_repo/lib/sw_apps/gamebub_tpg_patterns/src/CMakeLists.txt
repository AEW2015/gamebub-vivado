# Copyright (C) 2023 - 2025 Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
# Adapted from the installed Vitis 2025.2 hello_world application CMake template.
# Native application build; license details: LICENSE.md at repository root.
cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_SOURCE_DIR}/Gamebub_tpg_patternsExample.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/UserConfig.cmake)
set(APP_NAME gamebub_tpg_patterns)
project(${APP_NAME})
enable_language(C ASM CXX)
# Vitis supplies common.cmake and the standalone BSP libraries. Do not copy or
# relicense AMD's standalone/xil/xiltimer sources into this custom repository.
find_package(common)
collect(PROJECT_LIB_DEPS xilstandalone)
collect(PROJECT_LIB_DEPS xil)
collect(PROJECT_LIB_DEPS gcc)
collect(PROJECT_LIB_DEPS c)
# Resolve one instance per driver from this platform's generated metadata.
# The bindings helper also selects local BRAM for code/data/stack/heap.
set(GB_NATIVE_DEPS v_tpg)
set(GB_NATIVE_IRQ 0)
include(${CMAKE_CURRENT_SOURCE_DIR}/gamebub_bindings.cmake)
collect(PROJECT_LIB_SOURCES main.c)
collector_list(_sources PROJECT_LIB_SOURCES)
list(APPEND _sources ${USER_COMPILE_SOURCES})
collector_list(_deps PROJECT_LIB_DEPS)
list(APPEND _deps ${USER_LINK_LIBRARIES})
string(REPLACE ";" ",-l" _deps "${_deps}")
# Let Vitis generate the linker script using the BRAM settings above. Merely
# binding external RAM addresses does not reserve a safe scratch span there.
linker_gen("${CMAKE_CURRENT_SOURCE_DIR}/linker_files/")
string(APPEND CMAKE_C_FLAGS ${USER_COMPILE_OPTIONS})
string(APPEND CMAKE_CXX_FLAGS ${USER_COMPILE_OPTIONS})
string(APPEND CMAKE_C_LINK_FLAGS ${USER_LINK_OPTIONS})
# Rebuild this application when the selected platform's BSP changes.
add_dependency_on_bsp(_sources)
add_executable(${APP_NAME}.elf ${_sources})
set_target_properties(${APP_NAME}.elf PROPERTIES LINK_DEPENDS ${USER_LINKER_SCRIPT})
set(_linker_command "-Wl,-T -Wl,\"${USER_LINKER_SCRIPT}\" -L\"${CMAKE_SOURCE_DIR}/\" -L\"${CMAKE_LIBRARY_PATH}/\" -L\"${USER_LINK_DIRECTORIES}/\" -Wl,--start-group,-l${_deps} -Wl,--end-group")
target_link_libraries(${APP_NAME}.elf ${_linker_command})
target_compile_definitions(${APP_NAME}.elf PUBLIC ${USER_COMPILE_DEFINITIONS})
target_include_directories(${APP_NAME}.elf PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR} ${USER_INCLUDE_DIRECTORIES})
print_build_info_target(${APP_NAME}.elf "${CMAKE_C_FLAGS}" "${USER_COMPILE_DEFINITIONS}" "${CMAKE_C_LINK_FLAGS}" "${_linker_command}")
print_elf_size(CMAKE_SIZE ${APP_NAME})
