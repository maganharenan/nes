; ---- INCLUDES --------------------------------------------------------------------
.include    "constants.inc"
.include    "header.inc"
.include    "reset.inc"
.include    "utils.inc"
; ----------------------------------------------------------------------------------

; ---- ZERO-PAGE -------------------------------------------------------------------
.segment "ZEROPAGE"
Buttons:            .res 1

XPosition:          .res 2
YPosition:          .res 2

XVelocity:          .res 1
YVelocity:          .res 1

Frame:              .res 1
Clock60:            .res 1
BgPointer:          .res 2

XScroll:            .res 1
CurrentNametable:   .res 1
Column:             .res 1
NewColumnAddress:   .res 2
SourceAddress:      .res 2
; ----------------------------------------------------------------------------------

; ---- CODE ------------------------------------------------------------------------
.segment "CODE"

.proc ReadControllers
            lda #1              ; set the latch to input mode
            sta Buttons

            sta JOYPAD_1
            lsr                 ; set to output mode to send to NES (same as setting lda to #0)
            sta JOYPAD_1

LoopButtons:
            lda JOYPAD_1

            lsr
            rol Buttons

            bcc LoopButtons     ; In the moment that carry is set I break my loop
            rts
.endproc

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

.proc LoadSprites
            ldx #0
LoopSprites:
            lda SpriteData,x
            sta $0200,x
            inx
            cpx #32
            bne LoopSprites

            rts
.endproc

.proc DrawNewColumn
            lda XScroll
            lsr
            lsr
            lsr
            sta NewColumnAddress

            lda CurrentNametable
            eor #1
            asl
            asl
            clc
            adc #$20
            sta NewColumnAddress + 1

            lda Column              ; Multiply (col * 32) to compute the data offset
            asl
            asl
            asl
            asl
            asl
            sta SourceAddress

            lda Column
            lsr
            lsr
            lsr
            sta SourceAddress + 1

            lda SourceAddress
            clc
            adc #<BackgroundData
            sta SourceAddress

            lda SourceAddress + 1
            adc #>BackgroundData
            sta SourceAddress + 1

            DrawColumn:
                lda #%00000100
                sta PPU_CTRL

                lda PPU_STATUS
                lda NewColumnAddress + 1
                sta PPU_ADDR
                lda NewColumnAddress
                sta PPU_ADDR

                ldx #30
                ldy #0

                DrawColumnLoop:
                    lda (SourceAddress), y
                    sta PPU_DATA
                    iny
                    dex
                    bne DrawColumnLoop

            rts
.endproc

.proc DrawNewAttribute
            lda CurrentNametable
            eor #1
            asl
            asl
            clc
            adc #$23
            sta NewColumnAddress + 1

            lda XScroll
            lsr
            lsr
            lsr
            lsr
            lsr
            clc
            adc #$C0
            sta NewColumnAddress

            lda Column
            and #%11111100
            asl
            sta SourceAddress

            lda Column
            lsr
            lsr
            lsr
            lsr
            lsr
            lsr
            lsr
            sta SourceAddress + 1

            lda SourceAddress
            clc
            adc #<AttributeData
            sta SourceAddress

            lda SourceAddress + 1
            adc #>AttributeData
            sta SourceAddress + 1

            DrawAttribute:
                bit PPU_STATUS
                ldy #0

                DrawAttributeLoop:
                    lda NewColumnAddress + 1
                    sta PPU_ADDR
                    lda NewColumnAddress
                    sta PPU_ADDR
                    lda (SourceAddress), y
                    sta PPU_DATA
                    iny
                    cpy #8
                    beq :+
                        lda NewColumnAddress
                        clc
                        adc #8
                        sta NewColumnAddress
                        jmp DrawAttributeLoop
                    :

            rts
.endproc

Reset: 
            INIT_NES

InitVariables:
            lda #0
            sta Frame
            sta Clock60
            sta CurrentNametable
            sta Column

Main:
            jsr LoadPalette
            jsr LoadSprites

InitBackgroundTiles:
            lda #1
            sta CurrentNametable
            lda #0
            sta XScroll
            sta Column

InitBackgroundLoop:
            jsr DrawNewColumn

            lda XScroll
            clc
            adc #8
            sta XScroll

            inc Column

            lda Column
            cmp #32
            bne InitBackgroundLoop

            lda #0
            sta CurrentNametable
            lda #1
            sta XScroll

            jsr DrawNewColumn
            inc Column

            lda #%00000000
            sta PPU_CTRL

InitAttributes:
            lda #1
            sta CurrentNametable
            lda #0
            sta XScroll
            sta Column

InitAttributesLoop:
            jsr DrawNewAttribute
            lda XScroll
            clc
            adc #32
            sta XScroll

            lda Column
            clc
            adc #4
            sta Column
            cmp #32
            bne InitAttributesLoop

            lda #0
            sta CurrentNametable
            lda #1
            sta XScroll
            jsr DrawNewAttribute

EnablePPURendering:
            lda #%10010000
            sta PPU_CTRL
            lda #0
            sta PPU_SCROLL
            sta PPU_SCROLL
            lda #%00011110
            sta PPU_MASK

LoopForever:
            jmp LoopForever

NMI:
            inc Frame

OAMDMACopy:
            lda #$02
            sta PPU_OAM_DMA

NewColumnCheck:
            lda XScroll
            and #%00000111
            bne EndColumnCheck
              jsr DrawNewColumn

            Clamp128Columns:
              lda Column
              clc
              adc #1
              and #%01111111
              sta Column

            EndColumnCheck:

NewAttributesCheck:
            lda XScroll
            and #%00011111
            bne :+
              jsr DrawNewAttribute
            :

ScrollBackground:
            inc XScroll

            lda XScroll
            bne :+
              lda CurrentNametable
              eor #1
              sta CurrentNametable
            :

            lda XScroll
            sta PPU_SCROLL
            lda #0
            sta PPU_SCROLL    ; Disables Y Scroll

RefreshRendering:
            lda #%10010000
            ora CurrentNametable
            sta PPU_CTRL
            lda #%00011110
            sta PPU_MASK

SetGameClock:
            lda Frame
            cmp #60
            bne :+
              inc Clock60

              lda #0
              sta Frame
            :
            rti

IRQ:
    rti   

PaletteData:
.byte $1C,$0F,$22,$1C, $1C,$37,$3D,$0F, $1C,$37,$3D,$30, $1C,$0F,$3D,$30 ; Background palette
.byte $1C,$0F,$2D,$10, $1C,$0F,$20,$27, $1C,$2D,$38,$18, $1C,$0F,$1A,$32 ; Sprite palette

BackgroundData:
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$23,$33,$15,$21,$12,$00,$31,$31,$31,$55,$56,$00,$00 ; ---> screen column 1 (from top to bottom)
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$24,$34,$15,$15,$12,$00,$31,$31,$53,$56,$56,$00,$00 ; ---> screen column 2 (from top to bottom)
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$52,$56,$00,$00 ; ---> screen column 3 (from top to bottom)
.byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$44,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$31,$5a,$56,$00,$00 ; ...
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$45,$21,$21,$21,$22,$32,$15,$15,$12,$00,$00,$00,$31,$58,$56,$00,$00 ; ...
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$46,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$51,$5c,$56,$00,$00 ; ...
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$27,$37,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$5c,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$47,$21,$21,$21,$48,$21,$21,$22,$32,$3e,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$4a,$21,$21,$23,$33,$4e,$15,$12,$00,$00,$00,$00,$59,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$24,$34,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$00,$00
.byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$00,$00
.byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$53,$56,$00,$00
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$21,$21,$25,$35,$15,$15,$12,$00,$60,$00,$00,$54,$56,$00,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$27,$37,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$48,$21,$21,$15,$27,$37,$15,$15,$12,$00,$00,$00,$00,$5d,$56,$00,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$28,$38,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$22,$35,$3f,$21,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$26,$36,$3f,$21,$12,$00,$00,$00,$00,$57,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$27,$37,$21,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$58,$56,$00,$00
.byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$3e,$21,$12,$00,$00,$00,$00,$59,$56,$00,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$21,$12,$00,$00,$00,$51,$59,$56,$00,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$00,$5c,$56,$00,$00
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$29,$39,$21,$21,$12,$00,$00,$00,$00,$55,$56,$00,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$48,$21,$2c,$2a,$3a,$3c,$21,$12,$00,$00,$00,$54,$56,$56,$00,$00
.byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$46,$21,$21,$21,$4a,$21,$2d,$2a,$3a,$3d,$15,$12,$00,$00,$00,$00,$52,$56,$00,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$2b,$3b,$15,$15,$12,$00,$00,$00,$00,$57,$56,$00,$00

.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$21,$12,$00,$31,$31,$31,$55,$56,$ff,$9a
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$21,$14,$11,$15,$15,$12,$00,$31,$31,$53,$56,$56,$ff,$5a
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$15,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$52,$56,$ff,$5a
.byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$15,$15,$15,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$31,$5a,$56,$ff,$56
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$15,$15,$15,$21,$14,$11,$15,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$59
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$15,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$51,$5c,$56,$ff,$5a
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$5a
.byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$5c,$56,$ff,$5a
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$47,$21,$21,$21,$48,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$4a,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$25,$35,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00
.byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$27,$37,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$15,$15,$21,$21,$29,$39,$15,$15,$12,$00,$00,$00,$00,$53,$56,$aa,$00
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$21,$1f,$2a,$3a,$3c,$15,$12,$00,$61,$00,$00,$54,$56,$aa,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$28,$3b,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$48,$21,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$5d,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$3f,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$3f,$21,$12,$00,$00,$00,$00,$57,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$14,$11,$21,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$5a,$00
.byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$3e,$21,$12,$00,$00,$00,$00,$59,$56,$9a,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$22,$32,$4e,$21,$12,$00,$00,$00,$51,$59,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$23,$33,$3f,$15,$12,$00,$00,$00,$00,$5c,$56,$6a,$00
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$24,$34,$21,$21,$12,$00,$00,$00,$00,$55,$56,$9a,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$48,$15,$15,$14,$11,$15,$21,$12,$00,$00,$00,$54,$56,$56,$aa,$00
.byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$46,$21,$21,$21,$4a,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$52,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00

.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$21,$12,$00,$31,$31,$31,$58,$56,$ff,$9a
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$14,$11,$15,$15,$12,$00,$31,$31,$00,$5d,$56,$ff,$5a
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$5a
.byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$44,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$aa
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$45,$21,$21,$21,$22,$32,$15,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$56
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$46,$21,$21,$21,$26,$36,$15,$15,$12,$00,$00,$00,$51,$58,$56,$ff,$9a
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$27,$37,$15,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$59
.byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$28,$38,$15,$15,$12,$00,$00,$00,$00,$55,$56,$ff,$5a
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$57,$56,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$47,$21,$21,$21,$48,$21,$21,$22,$32,$3e,$15,$12,$00,$00,$00,$00,$52,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$4a,$21,$21,$23,$33,$4e,$15,$12,$00,$00,$00,$00,$53,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$24,$34,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$62,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$29,$39,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$1f,$2a,$3a,$3d,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$48,$21,$15,$2d,$2a,$3a,$3c,$15,$12,$00,$00,$00,$00,$5b,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$2f,$2a,$3a,$3d,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$28,$3b,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$49,$21,$21,$21,$14,$11,$4e,$21,$12,$00,$00,$00,$51,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$14,$11,$21,$15,$12,$00,$00,$00,$51,$58,$56,$aa,$00
.byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$21,$21,$15,$29,$39,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$15,$2c,$2a,$3a,$3e,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$2e,$2a,$3a,$4e,$21,$12,$00,$00,$00,$51,$58,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$1f,$2a,$3a,$3f,$15,$12,$00,$00,$00,$00,$5d,$56,$aa,$00
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$15,$28,$3b,$3f,$21,$12,$00,$00,$00,$00,$57,$56,$aa,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$48,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$46,$21,$21,$21,$4a,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00

.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$21,$12,$00,$31,$31,$31,$58,$56,$ff,$9a
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$31,$31,$00,$58,$56,$ff,$5a
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$31,$58,$56,$ff,$5a
.byte $13,$13,$7f,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$15,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$31,$54,$56,$ff,$59
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$15,$21,$21,$21,$14,$11,$3e,$15,$12,$00,$00,$00,$31,$54,$56,$ff,$56
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$42,$15,$21,$21,$15,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$51,$58,$56,$ff,$5a
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$59
.byte $13,$13,$61,$13,$20,$21,$21,$21,$21,$21,$21,$44,$21,$21,$21,$21,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$ff,$5a
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$45,$21,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$47,$15,$21,$21,$21,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$53,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$15,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$21,$14,$11,$15,$15,$12,$00,$00,$00,$00,$57,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$21,$29,$39,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$6c,$13,$20,$21,$21,$21,$21,$21,$48,$21,$15,$21,$21,$21,$21,$1d,$1e,$2a,$3a,$3c,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$78,$13,$20,$21,$21,$21,$21,$21,$49,$21,$21,$21,$21,$21,$21,$21,$21,$2b,$3b,$3e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$7b,$13,$20,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$6e,$13,$20,$21,$21,$21,$21,$15,$48,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$4e,$15,$12,$00,$63,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$49,$21,$21,$21,$21,$21,$21,$21,$21,$14,$11,$3f,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$4a,$21,$21,$21,$21,$21,$21,$15,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$15,$21,$15,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$60,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$15,$21,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$42,$21,$21,$21,$15,$21,$21,$21,$29,$39,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$43,$21,$21,$21,$15,$21,$21,$2c,$2a,$3a,$3c,$21,$12,$00,$00,$00,$50,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$44,$15,$21,$21,$15,$21,$21,$2d,$2a,$3a,$3e,$15,$12,$00,$00,$00,$50,$58,$56,$aa,$00
.byte $13,$13,$76,$13,$20,$21,$21,$21,$21,$21,$21,$45,$15,$21,$21,$21,$21,$21,$15,$2b,$3b,$3f,$15,$12,$00,$00,$00,$00,$54,$56,$aa,$00
.byte $13,$13,$72,$13,$20,$21,$21,$21,$21,$21,$21,$46,$15,$21,$21,$21,$21,$15,$15,$14,$11,$3f,$21,$12,$00,$00,$00,$00,$59,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$51,$58,$56,$aa,$00
.byte $13,$13,$7c,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$75,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$21,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$5d,$56,$aa,$00
.byte $13,$13,$84,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$15,$21,$15,$14,$11,$15,$21,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$65,$13,$20,$21,$21,$21,$21,$21,$21,$21,$15,$21,$21,$21,$15,$15,$15,$14,$11,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00
.byte $13,$13,$13,$13,$20,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$21,$22,$32,$15,$15,$12,$00,$00,$00,$00,$58,$56,$aa,$00

AttributeData:
.byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$6a,$a6,$00,$00,$00
.byte $ff,$aa,$aa,$9a,$59,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

.byte $ff,$aa,$aa,$5a,$9a,$00,$00,$00
.byte $ff,$aa,$aa,$9a,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$6a,$56,$00,$00,$00
.byte $ff,$aa,$aa,$9a,$59,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

.byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$aa,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$56,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$59,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

.byte $ff,$aa,$aa,$aa,$9a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$59,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$56,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$59,$00,$00,$00
.byte $ff,$aa,$aa,$aa,$5a,$00,$00,$00

SpriteData:
;      Y   tile#  attributes   X
.byte $A6,  $60,  %00000000,  $70 ; $200   _______________
.byte $A6,  $61,  %00000000,  $78 ; $204   \  o o o o o  /   <-- Ship (4 tiles)
.byte $A6,  $62,  %00000000,  $80 ; $208    \___________/
.byte $A6,  $63,  %00000000,  $88 ; $20C
; ----------------------------------------------------------------------------------

.segment "CHARS"
.incbin "atlantico.chr"

; ---- VECTORS ---------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       Reset
.word       IRQ
; ----------------------------------------------------------------------------------