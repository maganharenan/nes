; ==================================================================================
;        ____                        _   _                _           
;       / ___| __ _ _ __ ___   ___  | | | | ___  __ _  __| | ___ _ __ 
;      | |  _ / _` | '_ ` _ \ / _ \ | |_| |/ _ \/ _` |/ _` |/ _ \ '__|
;      | |_| | (_| | | | | | |  __/ |  _  |  __/ (_| | (_| |  __/ |   
;       \____|\__,_|_| |_| |_|\___| |_| |_|\___|\__,_|\__,_|\___|_|   
;
; ----------------------------------------------------------------------------------
;      Description: This segment defines the header of the NES ROM.
;      The header is 16 bytes long and provides essential information about 
;      the ROM, such as the size of the PRG and CHR ROMs, the mirroring type, 
;      mapper number, and other flags.
; ==================================================================================

; ---- MARK: HEADER ----------------------------------------------------------------
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