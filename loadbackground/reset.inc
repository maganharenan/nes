; ----------------------------------------------------------------------------------
;      Filename: reset.inc
;      Description: Macro responsible for initialize the rom
; ----------------------------------------------------------------------------------
.macro INIT_NES
            sei
            cld
            ldx #$FF
            txs

            inx
            stx PPU_CTRL        ; Disable NMI
            stx PPU_MASK
            stx $4010           ; Disable DMC IRQs

            lda #$40
            sta $4017

Wait1stVBlank:
            bit PPU_STATUS
            bpl Wait1stVBlank

            txa

ClearRam:
            sta $0000, x
            sta $0100, x
            sta $0200, x
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