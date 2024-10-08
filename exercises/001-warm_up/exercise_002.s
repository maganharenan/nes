; ---- INES HEADER -----------------------------------------------------------------
.segment "HEADER"
.org        $7FF0
.byte       $4E,$45,$53,$1A,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; ----------------------------------------------------------------------------------

; ---- CODE ------------------------------------------------------------------------
.segment "CODE"
.org        $8000

Reset:      
            lda #$A
            ldx #%11111111
            sta $80
            stx $81

            jmp Reset

NMI:
            rti

IRQ:
            rti
; ----------------------------------------------------------------------------------

; ---- VECTOR ----------------------------------------------------------------------
.segment "VECTORS"
.org        $FFFA
.word       NMI
.word       Reset
.word       IRQ
; ----------------------------------------------------------------------------------