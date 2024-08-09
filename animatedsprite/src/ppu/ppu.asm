; ==================================================================================
;       ____  ____  _   _ 
;      |  _ \|  _ \| | | |
;      | |_) | |_) | | | |
;      |  __/|  __/| |_| |
;      |_|   |_|    \___/ 
;
; ----------------------------------------------------------------------------------
;      Description: This file is the main entry point for the NES game. It includes 
;      necessary constants, headers, reset routines, utility macros, and assets. 
;      It defines zero-page variables, main game logic, and interrupt service routines. 
;      The game loop initializes the PPU, updates player animations, and handles 
;      the main game logic within a VBlank-wait loop.
; ==================================================================================

; ---- MARK: EXPORT ----------------------------------------------------------------
.export     NMIHandler
.export     ResetHandler
.export     IRQHandler
; ----------------------------------------------------------------------------------

; ---- MARK: PALETTE ---------------------------------------------------------------
.proc LoadPalette
    PPU_SETADDR $3F00
    ldy #0

    LoopPalette:
        lda PaletteData, y
        sta PPU_DATA
        iny
        cpy #32
        bne LoopPalette

    rts
.endproc
; ----------------------------------------------------------------------------------
