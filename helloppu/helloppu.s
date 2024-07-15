; ---- CONSTANTS -------------------------------------------------------------------
PPU_CTRL    = $2000
PPU_MASK    = $2001
PPU_STATUS  = $2002
OAM_ADDR    = $2003
OAM_DATA    = $2004
PPU_SCROLL  = $2005
PPU_ADDR    = $2006
PPU_DATA    = $2007
; ----------------------------------------------------------------------------------

; ---- INES HEADER -----------------------------------------------------------------
.segment "HEADER"
.org        $7FF0

.byte       $4E, $45, $53, $1A  ; 4 bytes with the characters "N", "E", "S", "\n"
.byte       $02                 ; How many 16kb will be used (32kb) -> Prog ROM
.byte       $01                 ; How many 8kb will be used -> CHAR ROM
.byte       %00000000           ; Horizontal mirroring, battery and other flags
.byte       %00000000           ; Mapper, etc
.byte       $00                 ; No PRG-RAM
.byte       $00                 ; NTSC TV Format
.byte       $00                 ; No PRG_RAM
.byte       $00,$00,$00,$00,$00 ; Unused padding to complete 16 bytes of the header
; ----------------------------------------------------------------------------------

; ---- CODE ------------------------------------------------------------------------
.segment "CODE"
.org        $8000

Reset:
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

Main:
            ldx #$3F
            stx PPU_ADDR
            ldx #$00
            stx PPU_ADDR
            lda #$2A            ; Send Lime green color to PPU_DATA
            sta PPU_DATA
            lda #%00011110
            sta PPU_MASK

LoopForever:
            jmp LoopForever

NMI:
            rti
IRQ:
            rti
; ----------------------------------------------------------------------------------

; ---- VECTORS ---------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       Reset
.word       IRQ
; ----------------------------------------------------------------------------------