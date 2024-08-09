; ==================================================================================
;       ____                _   
;      |  _ \ ___  ___  ___| |_ 
;      | |_) / _ \/ __|/ _ \ __|
;      |  _ <  __/\__ \  __/ |_ 
;      |_| \_\___||___/\___|\__|
;
; ----------------------------------------------------------------------------------
;      Description: This macro initializes the NES system. It sets up the stack 
;      pointer, disables interrupts, and prepares the PPU (Picture Processing Unit) 
;      for rendering. The macro waits for the first VBlank, clears the RAM, hides 
;      sprites, and waits for the second VBlank to ensure the system is ready for 
;      operation.
; ==================================================================================

; ---- MARK: MACROS ----------------------------------------------------------------
.macro INIT_NES
    sei
    cld
    ldx #$FF
    txs

    inx
    stx PPU_CTRL            ; Disable NMI
    stx PPU_MASK
    stx $4010               ; Disable DMC IRQs

    lda #$40
    sta $4017

    Wait1stVBlank:
        bit PPU_STATUS
        bpl Wait1stVBlank

        txa

    ClearRam:
        sta $0000, x
        sta $0100, x
        lda #$FF            ; Hide sprites
        sta $0200, x
        lda #0
        sta $0300, x
        sta $0400, x
        sta $0500, x
        sta $0600, x
        sta $0700, x
        inx
        bne ClearRam

    Wait2ndVBlank:
        bit PPU_STATUS
        bpl Wait2ndVBlank
        
        txa

.endmacro
; ----------------------------------------------------------------------------------