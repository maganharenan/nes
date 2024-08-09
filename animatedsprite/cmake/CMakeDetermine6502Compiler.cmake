find_program(
    CMAKE_6502_COMPILER
        NAMES "ca65"
        HINTS "${CMAKE_SOURCE_DIR}"
        DOC "ca65 assembler"
)

mark_as_advanced( CMAKE_6502_COMPILER )

set( CMAKE_6502_SOURCE_FILE_EXTENSIONS s;asm )
set( CMAKE_6502_OUTPUT_EXTENSION .o )
set( CMAKE_6502_COMPILER_ENV_VAR "FOO" )

# Configure variables set in this file for fast reload later on
configure_file( ${CMAKE_CURRENT_LIST_DIR}/CMake6502Compiler.cmake.in
                ${CMAKE_PLATFORM_INFO_DIR}/CMake6502Compiler.cmake )
