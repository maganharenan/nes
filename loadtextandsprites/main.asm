; ---- INCLUDES --------------------------------------------------------------------
.include    "constants.inc"
.include    "header.inc"
.include    "reset.inc"
.include    "utils.inc"
; ----------------------------------------------------------------------------------

; ---- ZERO-PAGE -------------------------------------------------------------------
.segment "ZEROPAGE"
Buttons:    .res 1
XPosition:  .res 1
YPosition:  .res 1
Frame:      .res 1              ; Reserve 1 byte to store the number of frames
Clock60:    .res 1              ; Reserve 1 byte to store a counter that increments every second (60 frames)
BgPointer:  .res 2              ; Ponter to the background address (Lo-byte and Hi-byte -> Little Endian)

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

.proc LoadText
            PPU_SETADDR $21CB
            ldy #0
LoopText:
            lda TextMessage, y
            beq EndLoop

            cmp #32
            bne DrawLetter

DrawSpace:
            lda #$24
            sta PPU_DATA
            jmp NextChar

DrawLetter:
            sec
            sbc #55
            sta PPU_DATA

NextChar:
            iny
            jmp LoopText

EndLoop:
            rts
.endproc

.proc LoadBackground
            lda #<BackgroundData
            sta BgPointer
            lda #>BackgroundData
            sta BgPointer+1

            PPU_SETADDR $2000

            ldx #0
            ldy #0
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

Reset: 
            INIT_NES

InitVariables:
            lda #0
            sta Frame
            sta Clock60

            ldx #0
            lda SpriteData, x
            sta XPosition
            ldx #3
            lda SpriteData, x
            sta YPosition
Main:
            jsr LoadPalette
            jsr LoadBackground
            jsr LoadText
            jsr LoadSprites

EnablePPURendering:
            lda #%10010000          ; Enable NMI and set the background to use the 2nd pattern table
            sta PPU_CTRL
            lda #0
            sta PPU_SCROLL          ; disables scroll x
            sta PPU_SCROLL          ; disables scroll y
            lda #%00011110
            sta PPU_MASK

LoopForever:
            jmp LoopForever

NMI:
            inc Frame
OAMDMACopy:
            lda #$02
            sta PPU_OAM_DMA

ReadController:
            jsr ReadControllers

CheckRightButton:
            lda Buttons
            and #BUTTON_RIGHT
            beq CheckLeftButton
              inc XPosition

CheckLeftButton:
            lda Buttons
            and #BUTTON_LEFT
            beq CheckDownButton
              dec XPosition

CheckDownButton:
            lda Buttons
            and #BUTTON_DOWN
            beq CheckUpButton
              inc YPosition

CheckUpButton:
            lda Buttons
            and #BUTTON_UP
            beq UpdateSpritePosition
              dec YPosition

UpdateSpritePosition:
            lda XPosition
            sta $0203
            sta $020B
            clc
            adc #8
            sta $0207
            sta $020F

            lda YPosition
            sta $0200
            sta $0204
            adc #8
            sta $0208
            sta $020C

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
.byte $22,$29,$1A,$0F, $22,$36,$17,$0F, $22,$30,$21,$0F, $22,$27,$17,$0F ; Background palette
.byte $22,$16,$27,$18, $22,$1A,$30,$27, $22,$16,$30,$27, $22,$0F,$36,$17 ; Sprite palette

BackgroundData:
.incbin "background.nam"
SpriteData:
; Mario:
;      Y   #tile  attribute    X
.byte $AE,  $3A,  %00000000,  $98
.byte $AE,  $37,  %00000000,  $A0
.byte $B6,  $4F,  %00000000,  $98
.byte $B6,  $4F,  %01000000,  $A0
; Goomba:
;      Y   #tile  attribute    X
.byte $93,  $70,  %00000011,  $C7
.byte $93,  $70,  %01100011,  $CF
.byte $9B,  $72,  %00100011,  $C7
.byte $9B,  $73,  %00100011,  $CF


; Sprite Attribute Byte
; -------------------------------
; 76543210
; |||   ||
; |||   ++- Color Palette of Sprite
; |||
; ||+------ Priority (0: in front of background; 1: behind background)
; |+------- Flip sprite horizontally
; +-------- Flip sprite vertically

TextMessage:
.byte "HELLO WORLD", $0
; ----------------------------------------------------------------------------------

.segment "CHARS"
.incbin     "mario.chr"

; ---- VECTORS ---------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       Reset
.word       IRQ
; ----------------------------------------------------------------------------------