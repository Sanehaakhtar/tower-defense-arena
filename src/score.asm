; ============================================================================
; score.asm — Score tracking and display
; Tower Defense Arena
;
; Owner: Khadija (502430)
; ============================================================================

option casemap:none

include src/defs.inc

; ============================================================================
; Public procedures
; ============================================================================
public score_init
public score_add
public score_get

.code

; ============================================================================
; score_init — Reset the score to zero
; Purpose: Initialize score at game start or restart
; Inputs:  none
; Outputs: none
; ============================================================================
score_init proc
    mov     dword ptr [player_score], 0
    ret
score_init endp

; ============================================================================
; score_add — Add points to the score
; Purpose: Increment the player's score
; Inputs:  ecx = points to add
; Outputs: none
; ============================================================================
score_add proc
    add     [player_score], ecx
    ret
score_add endp

; ============================================================================
; score_get — Get the current score
; Purpose: Return current score in eax
; Inputs:  none
; Outputs: eax = current score
; ============================================================================
score_get proc
    mov     eax, [player_score]
    ret
score_get endp

end
