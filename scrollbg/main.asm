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

TileOffset:         .res 1

Frame:              .res 1              ; Reserve 1 byte to store the number of frames
Clock60:            .res 1              ; Reserve 1 byte to store a counter that increments every second (60 frames)
BgPointer:          .res 2              ; Ponter to the background address (Lo-byte and Hi-byte -> Little Endian)

XScroll:            .res 1
; ----------------------------------------------------------------------------------

; ---- CONSTANTS -------------------------------------------------------------------
MAXSPEED    = 120
ACCEL       = 2
BRAKE       = 2
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

.proc LoadNametable0
            lda #<BackgroundData0
            sta BgPointer
            lda #>BackgroundData0
            sta BgPointer+1

            PPU_SETADDR $2000

            ldx #$00
            ldy #$00
OuterBackgroundLoop:
InnerBackgroundLoop:
            lda (BgPointer), y
            sta PPU_DATA
            iny
            cpy #0
            beq IncreaseHiByte
            jmp InnerBackgroundLoop

IncreaseHiByte:
            inc BgPointer+1
            inx
            cpx #4
            bne OuterBackgroundLoop

            rts
.endproc

.proc LoadNametable1
            lda #<BackgroundData1
            sta BgPointer
            lda #>BackgroundData1
            sta BgPointer+1

            PPU_SETADDR $2400

            ldx #$00
            ldy #$00
OuterBackgroundLoop:
InnerBackgroundLoop:
            lda (BgPointer), y
            sta PPU_DATA
            iny
            cpy #0
            beq IncreaseHiByte
            jmp InnerBackgroundLoop

IncreaseHiByte:
            inc BgPointer+1
            inx
            cpx #4
            bne OuterBackgroundLoop

            rts
.endproc

Reset: 
            INIT_NES

InitVariables:
            lda #0
            sta Frame
            sta Clock60
            sta TileOffset
            sta XScroll

            ldx #0
            lda SpriteData, x
            sta YPosition+1
            inx
            inx
            inx
            lda SpriteData, x
            sta XPosition+1

Main:
            jsr LoadPalette
            jsr LoadNametable0
            jsr LoadNametable1
            jsr LoadSprites

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

ScrollBackground:
            inc XScroll

            lda XScroll
            sta PPU_SCROLL
            lda #0
            sta PPU_SCROLL    ; Disables Y Scroll

RefreshRendering:
            lda #%10010000
            sta PPU_CTRL
            lda #%00011110
            sta PPU_MASK

ReadController:
            jsr ReadControllers

CheckRightButton:
            lda Buttons
            and #BUTTON_RIGHT
            beq NotRight
              lda XVelocity
              bmi NotRight
                clc
                adc #ACCEL
                cmp #MAXSPEED
                bcc :+
                  lda #MAXSPEED
                :
                sta XVelocity
                jmp CheckLeftButton
            NotRight:
              lda XVelocity
              bmi CheckLeftButton
                cmp #BRAKE
                bcs :+
                  lda #BRAKE+1
                :
                sbc #BRAKE
                sta XVelocity

CheckLeftButton:
            lda Buttons
            and #BUTTON_LEFT
            beq NotLeft
              lda XVelocity
              beq :+
                bpl NotLeft
              :
              sec 
              sbc #ACCEL
              cmp #256-MAXSPEED
              bcs :+
                lda #256-MAXSPEED
              :
              sta XVelocity
              jmp CheckDownButton
            NotLeft:
              lda XVelocity
              bpl CheckDownButton
              cmp #256-BRAKE
              bcc :+
                lda #256-BRAKE
              :
              adc #BRAKE
              sta XVelocity
CheckDownButton:
    ;; TODO:
CheckUpButton:
    ;; TODO:
EndInputCheck:

UpdateSpritePosition:
            lda XVelocity
            bpl :+
              dec XPosition+1
            :
            clc
            adc XPosition
            sta XPosition
            lda #0
            adc XPosition+1
            sta XPosition+1

DrawSpriteTile:
            lda XPosition+1
            sta $0203                ; Set the 1st sprite X position to be XPos
            sta $020B                ; Set the 3rd sprite X position to be XPos
            clc
            adc #8
            sta $0207                ; Set the 2nd sprite X position to be XPos + 8
            sta $020F                ; Set the 4th sprite X position to be XPos + 8

            lda YPosition+1
            sta $0200                ; Set the 1st sprite Y position to be YPos
            sta $0204                ; Set the 2nd sprite Y position to be YPos
            clc
            adc #8
            sta $0208                ; Set the 3rd sprite Y position to be YPos + 8
            sta $020C                ; Set the 4th sprite Y position to be YPos + 8

UpdateTileOffset:
            lda #0
            sta TileOffset
            lda XScroll
            and #%00000001
            beq :+
              lda #4
              sta TileOffset
            :

AnimateSpriteTile:
            lda #$18
            clc
            adc TileOffset
            sta $0201

            lda #$1A
            clc 
            adc TileOffset
            sta $0205

            lda #$19
            clc 
            adc TileOffset
            sta $0209

            lda #$1B
            clc 
            adc TileOffset
            sta $020D

LoopFrame:
            lda Frame
            cmp #60
            bne Skip
            inc Clock60

            lda #0
            sta Frame

Skip:
            rti

IRQ:
    rti   

PaletteData:
.byte $1D,$10,$20,$21, $1D,$1D,$2D,$24, $1D,$0C,$19,$1D, $1D,$06,$17,$07 ; Background palette
.byte $0F,$1D,$19,$29, $0F,$08,$18,$38, $0F,$0C,$1C,$3C, $0F,$2D,$10,$30 ; Sprite palette

BackgroundData0:
.incbin "nametable0.nam"      

BackgroundData1:
.incbin "nametable1.nam"   

SpriteData:
;       Y   tile#   attribs      X
.byte  $80,   $18,  %00000000,  $10  ; OAM sprite 1
.byte  $80,   $1A,  %00000000,  $18  ; OAM sprite 2
.byte  $88,   $19,  %00000000,  $10  ; OAM sprite 3
.byte  $88,   $1B,  %00000000,  $18  ; OAM sprite 4
; ----------------------------------------------------------------------------------

.segment "CHARS"
.incbin "battle.chr"

; ---- VECTORS ---------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       Reset
.word       IRQ
; ----------------------------------------------------------------------------------