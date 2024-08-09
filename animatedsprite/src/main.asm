; ==================================================================================
;       __  __       _       
;      |  \/  | __ _(_)_ __  
;      | |\/| |/ _` | | '_ \ 
;      | |  | | (_| | | | | |
;      |_|  |_|\__,_|_|_| |_|
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

; ---- MARK: INCLUDES --------------------------------------------------------------
.include    "constants.inc"
.include    "header.inc"
.include    "reset.inc"
.include    "utils.inc"
.include    "assets.inc"
; ----------------------------------------------------------------------------------

; ---- MARK: VARIABLES -------------------------------------------------------------
.segment "ZEROPAGE"
PlayerAnimationFrame:   .res 1
FramesPerAnimation:     .res 1
AnimationClock:         .res 1
Frame:                  .res 1
Clock60:                .res 1
IsDrawComplete:         .res 1

; POINTERS
SpritePointer:          .res 2
BackgroundPointer:      .res 2

.segment "CODE"

.proc LoadBackground
    lda #<BackgroundData
    sta BackgroundPointer+0
    lda #>BackgroundData
    sta BackgroundPointer+1

    PPU_SETADDR $2000

    ldx #0
    ldy #0
    OuterBackgroundLoop:
        InnerBackgroundLoop:
            lda (BackgroundPointer), y
            sta PPU_DATA
            iny
            cpy #0
            beq IncreaseHiByte
            jmp InnerBackgroundLoop

        IncreaseHiByte:
            inc BackgroundPointer+1
            inx
            cpx #4
            bne OuterBackgroundLoop

    rts
.endproc

.proc UpdatePlayerAnimationFrame
    inc PlayerAnimationFrame
    lda PlayerAnimationFrame
    cmp FramesPerAnimation
    bne :+
        lda #0
        sta PlayerAnimationFrame
    :

    rts
.endproc

.proc UpdatePlayerIdleAnimation
    ldx PlayerAnimationFrame

    cpx #0
    bne :+
        lda #$01
        sta $0201
        lda #$02
        sta $0205
        lda #$03
        sta $0209
        lda #$04
        sta $020D
    :
    cpx #1
    bne :+
        lda #$05
        sta $0201
        lda #$06
        sta $0205
        lda #$07
        sta $0209
        lda #$08
        sta $020D
    :
    cpx #2
    bne :+
        lda #$09
        sta $0201
        lda #$0A
        sta $0205
        lda #$07
        sta $0209
        lda #$08
        sta $020D
    :
    cpx #3
    bne :+
        lda #$0B
        sta $0201
        lda #$0C
        sta $0205
        lda #$03
        sta $0209
        lda #$04
        sta $020D
    :

    rts
.endproc

; ---- MARK: GAME ------------------------------------------------------------------
.proc ResetHandler
    INIT_NES
.endproc

Game:
    PPU_DISABLE_NMI

    InitVariables:
        lda #0
        sta PlayerAnimationFrame
        sta Frame
        sta Clock60
        sta IsDrawComplete

        lda #4
        sta FramesPerAnimation

    Main:
        jsr LoadPalette
        jsr LoadBackground

        AddPlayer:
            lda #$02
            sta SpritePointer+1
            lda #$00
            sta SpritePointer+0

            ldy #0

            lda #200
            sta (SpritePointer),y
            iny

            lda #$01
            sta (SpritePointer),y
            iny

            lda #%00000000
            sta (SpritePointer),y
            iny

            lda #100
            sta (SpritePointer),y
            iny

            ; 2ND SPRITE
            lda #200
            sta (SpritePointer),y
            iny

            lda #$02
            sta (SpritePointer),y
            iny

            lda #%00000000
            sta (SpritePointer),y
            iny

            lda #100+8
            sta (SpritePointer),y
            iny

            ; 3RD SPRITE
            lda #200+8
            sta (SpritePointer),y
            iny

            lda #$03
            sta (SpritePointer),y
            iny

            lda #%00000000
            sta (SpritePointer),y
            iny

            lda #100
            sta (SpritePointer),y
            iny

            ; 4TH SPRITE
            lda #200+8
            sta (SpritePointer),y
            iny

            lda #$04
            sta (SpritePointer),y
            iny

            lda #%00000000
            sta (SpritePointer),y
            iny

            lda #100+8
            sta (SpritePointer),y
            iny

    EnablePPURendering:
        lda #%10010000
        sta PPU_CTRL
        lda #0
        sta PPU_SCROLL
        sta PPU_SCROLL
        lda #%00011110
        sta PPU_MASK

    GameLoop:
        jsr UpdatePlayerIdleAnimation

        WaitForVblank:
            lda IsDrawComplete
            beq WaitForVblank

        lda #0
        sta IsDrawComplete

        jmp GameLoop
; ----------------------------------------------------------------------------------

; ---- MARK: NMI Handler -----------------------------------------------------------
.proc NMIHandler
    inc Frame

    PUSH_REGISTERS

    OAMDMACopy:
        lda #$02
        sta PPU_OAM_DMA

    RefreshRendering:
        lda #%10010000
        sta PPU_CTRL
        lda #%00011110
        sta PPU_MASK

    SetAnimationClock:
        lda Frame
        cmp #20
        beq UpdateAnimationClock
        cmp #40
        beq UpdateAnimationClock
        cmp #60
        beq UpdateAnimationClock

        jmp SkipAnimationClock

        UpdateAnimationClock:
            inc AnimationClock
            jsr UpdatePlayerAnimationFrame

        SkipAnimationClock:

    SetGameClock:
        lda Frame
        cmp #60
        bne :+
            inc Clock60

            lda #0
            sta Frame
        :

    SetDrawComplete:
        lda #1
        sta IsDrawComplete

    PULL_REGISTERS

    rti
.endproc
; ----------------------------------------------------------------------------------

; ---- MARK: IRQ Handler -----------------------------------------------------------
.proc IRQHandler
    rti
.endproc
; ----------------------------------------------------------------------------------