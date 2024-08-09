; ==================================================================================
;          _                 _       
;         / \   ___ ___  ___| |_ ___ 
;        / _ \ / __/ __|/ _ \ __/ __|
;       / ___ \\__ \__ \  __/ |_\__ \
;      /_/   \_\___/___/\___|\__|___/
;
; ----------------------------------------------------------------------------------
;      DESCRIPTION: This file contains the asset data for the project, including the 
;      palette data for color settings, the background data for the levels, and 
;      the character data for game graphics. The asset data is organized in a way
;      to be easily accessed and utilized by the game's main logic.
; ==================================================================================

; ---- MARK: EXPORT ----------------------------------------------------------------
.export     PaletteData
.export     BackgroundData
; ----------------------------------------------------------------------------------

; ---- MARK: ASSET DATA -----------------------------------------------------------
PaletteData:
.byte $21,$37,$27,$0D, $21,$01,$11,$21, $21,$06,$16,$26, $21,$09,$19,$29
.byte $21,$37,$27,$0D, $21,$01,$11,$21, $21,$06,$16,$26, $21,$09,$19,$29

BackgroundData:
.incbin "first_level.nam"

.segment "CHAR"
.incbin "game.chr"
; ----------------------------------------------------------------------------------