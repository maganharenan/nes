; ==================================================================================
;       _   _ _   _ _     
;      | | | | |_(_) |___ 
;      | | | | __| | / __|
;      | |_| | |_| | \__ \
;       \___/ \__|_|_|___/
;
; ----------------------------------------------------------------------------------
;      Description: This file contains macros to streamline and improve workflow
;      for NES development. These macros handle common tasks such as setting PPU 
;      addresses and data, managing the stack, and disabling NMI interrupts.
; ==================================================================================

; ---- MARK: MACROS ----------------------------------------------------------------
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

.macro PUSH_REGISTERS
    pha                     ; Push A to the stack
    txa                     ; Copy X to A
    pha                     ; Push X to the stack
    tya                     ; Copy Y to A
    pha                     ; Push Y to the stack
    php                     ; Push Processor status flags to the stack
.endmacro

.macro PULL_REGISTERS
    plp                     ; Restore status flags from the stack
    pla                     ; Restore the old value of Y from the stack
    tay                     ; Transfer A to Y
    pla                     ; Restore the old value of X from the stack
    tax     
    pla                     ; Restore the old value of A from the stack
.endmacro

.macro PPU_DISABLE_NMI
    lda #0
    sta PPU_CTRL
    sta PPU_MASK
.endmacro
; ----------------------------------------------------------------------------------