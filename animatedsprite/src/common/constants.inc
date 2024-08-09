; ==================================================================================
;     ____                _              _       
;    / ___|___  _ __  ___| |_ __ _ _ __ | |_ ___ 
;   | |   / _ \| '_ \/ __| __/ _` | '_ \| __/ __|
;   | |__| (_) | | | \__ \ || (_| | | | | |_\__ \
;    \____\___/|_| |_|___/\__\__,_|_| |_|\__|___/
;
; ----------------------------------------------------------------------------------
;    DESCRIPTION: 
;    This file defines constant values for the NES (Nintendo Entertainment System) 
;    hardware registers and button inputs. These constants are used to interface 
;    with the PPU (Picture Processing Unit) and read the state of the joypad buttons.
;
;    The defined constants make the code more readable and maintainable by 
;    providing meaningful names for hardware addresses and button values.
; ==================================================================================

; ---- MARK: PPU -------------------------------------------------------------------
PPU_CTRL        = $2000
PPU_MASK        = $2001
PPU_STATUS      = $2002
OAM_ADDR        = $2003
OAM_DATA        = $2004
PPU_SCROLL      = $2005
PPU_ADDR        = $2006
PPU_DATA        = $2007
PPU_OAM_DMA     = $4014
; ----------------------------------------------------------------------------------

; ---- MARK: BUTTONS ---------------------------------------------------------------
JOYPAD_1        = $4016
JOYPAD_2        = $4017

BUTTON_A        = $80
BUTTON_B        = $40
BUTTON_SELECT   = $20
BUTTON_START    = $10
BUTTON_UP       = $08
BUTTON_DOWN     = $04
BUTTON_LEFT     = $02
BUTTON_RIGHT    = $01   
; ----------------------------------------------------------------------------------