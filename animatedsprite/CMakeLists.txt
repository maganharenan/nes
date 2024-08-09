cmake_minimum_required( VERSION 3.21 FATAL_ERROR )

set( MEMORY_MAP_FILE ${CMAKE_CURRENT_SOURCE_DIR}/memory_map.cfg )
list( APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" )

project(
    AnimatedSprite
    LANGUAGES 6502
)

add_executable( ${PROJECT_NAME} "" )
add_subdirectory( assets )
add_subdirectory( src )
set_target_properties(
    ${PROJECT_NAME}
    PROPERTIES SUFFIX ".nes"
)

if( NOT DEFINED MEMORY_MAP_FILE )
    message( FATAL_ERROR "Path to memory map file not set or file doesn't exist" )
endif( NOT DEFINED MEMORY_MAP_FILE )