; ----------------------------------------------------------------------------------
;      Filename: Header.inc
;      Description: Contains the header of the rom
; ----------------------------------------------------------------------------------
.segment "HEADER"
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