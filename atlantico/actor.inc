; ----------------------------------------------------------------------------------
;      Filename: actor.inc
;      Description: Actors struct
; ----------------------------------------------------------------------------------
.enum ActorType
    NULL        = 0
    PLAYER      = 1
    SUBMARINE   = 2
    AIRPLANE    = 3
    MISSILE     = 4
    BOMB        = 5
    SPRITE0     = 7
.endenum

.struct Actor
    Type        .byte
    XPosition   .byte
    YPosition   .byte
    Screen      .byte
.endstruct