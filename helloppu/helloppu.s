; ---- INCLUDES --------------------------------------------------------------------
.include    "constants.inc"
.include    "header.inc"
.include    "reset.inc"
; ----------------------------------------------------------------------------------

; ---- CODE ------------------------------------------------------------------------
.segment "CODE"

.proc LoadPalette
            ldy #0
LoopPalette:
            lda PaletteData, y
            sta PPU_DATA
            iny
            cpy #32
            bne LoopPalette

            rts
.endpro

Reset: 
            INIT_NES
Main:
            bit PPU_STATUS
            ldx #$3F
            stx PPU_ADDR
            ldx #$00
            stx PPU_ADDR

            jsr LoadPalette

            sta PPU_DATA
            lda #%00011110
            sta PPU_MASK

LoopForever:
            jmp LoopForever

NMI:
            rti
IRQ:
            rti

PaletteData:
.byte $0F, $2A, $0C, $3A,  $0F, $2A, $0C, $3A,  $0F, $2A, $0C, $3A ; Background
.byte $0F, $10, $00, $26,  $0F, $10, $00, $26,  $0F, $10, $00, $26 ; Sprites
; ----------------------------------------------------------------------------------

; ---- VECTORS ---------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       Reset
.word       IRQ
; ----------------------------------------------------------------------------------