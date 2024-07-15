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
; ----------------------------------------------------------------------------------

RESET:
            sei                 ; Disable all IRQ interrupts
            cld                 ; clear the decimal mode flag (Unsupported by the NES)
            ldx #$FF
            txs                 ; Initialize the stack pointer at the $01FF

            lda #0
            ldx #0              ; inx would also be a good call here
MemLoop:
            sta $0, x           ; Store the value of A into the address $FF
            dex                 ; x--, if I decrement 0 it will become $FF and all values will be zero
            bne MemLoop         ; X != 0 keep looping

NMI:
            rti
IRQ:
            rti

; ---- VECTOR ----------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       RESET
.word       IRQ
; ----------------------------------------------------------------------------------