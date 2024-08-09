; ==================================================================================
;      __     __        _                 
;      \ \   / /__  ___| |_ ___  _ __ ___ 
;       \ \ / / _ \/ __| __/ _ \| '__/ __|
;        \ V /  __/ (__| || (_) | |  \__ \
;         \_/ \___|\___|\__\___/|_|  |___/
;
; ----------------------------------------------------------------------------------
;      DESCRIPTION: This file contains the asset data for the project, including the 
;      palette data for color settings, the background data for the levels, and 
;      the character data for game graphics. The asset data is organized in a way
;      to be easily accessed and utilized by the game's main logic.
; ==================================================================================

; ---- MARK: IMPORT ----------------------------------------------------------------
.import     NMIHandler
.import     ResetHandler
.import     IRQHandler
; ----------------------------------------------------------------------------------

; ---- MARK: VECTOR ----------------------------------------------------------------
.segment "VECTORS"
.word NMIHandler
.word ResetHandler
.word IRQHandler
; ----------------------------------------------------------------------------------