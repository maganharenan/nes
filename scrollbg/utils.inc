; ----------------------------------------------------------------------------------
;      Filename: Utils.inc
;      Description: Holds macros to improve workflow
; ----------------------------------------------------------------------------------
.macro PPU_SETADDR addr
    bit PPU_STATUS
    lda #>addr
    sta PPU_ADDR
    lda #<addr
    sta PPU_ADDR
.endmacro

.macro PPU_SETDATA val
    lda val
    sta PPU_DATA
.endmacro