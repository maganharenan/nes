# How to build objects
set( CMAKE_6502_COMPILE_OBJECT
    "<CMAKE_6502_COMPILER> --cpu 6502 \
                              <FLAGS> \
                              -s \
                              -o <OBJECT> \
                              <SOURCE>"
)

# How to build executables
set( CMAKE_6502_LINK_EXECUTABLE
    "ld65 -C ${MEMORY_MAP_FILE} \
          <OBJECTS> \
          -o <TARGET>"
)

set( CMAKE_6502_INFORMATION_LOADED 1 )