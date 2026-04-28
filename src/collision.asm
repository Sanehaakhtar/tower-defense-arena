; ============================================================================
; collision.asm — Hit detection between towers and enemies
; Tower Defense Arena
;
; Owner: Saneha (517085)
; ============================================================================

option casemap:none

include src/defs.inc

; ============================================================================
; External module procedures
; ============================================================================
extrn score_add:proc

; ============================================================================
; Public procedures
; ============================================================================
public collision_init
public collision_update

.code

; ============================================================================
; collision_init — Initialize collision system
; Purpose: Nothing to init currently, placeholder
; Inputs:  none
; Outputs: none
; ============================================================================
collision_init proc
    ret
collision_init endp

; ============================================================================
; collision_update — Check all towers against all enemies
; Purpose: For each ready tower, find nearest enemy in range, deal damage
; Inputs:  none
; Outputs: none (modifies enemy health, tower cooldowns, score, gold)
; ============================================================================
collision_update proc
    sub     rsp, 56                     ; shadow + locals

    lea     r12, [towers]
    xor     ebx, ebx                    ; tower index

@@tower_loop:
    cmp     ebx, MAX_TOWERS
    jge     @@done

    mov     eax, ebx
    imul    eax, TOWER_STRUCT_SIZE
    lea     r13, [r12 + rax]            ; r13 = current tower ptr

    ; Skip inactive
    cmp     dword ptr [r13 + TOWER_ACTIVE], 0
    je      @@next_tower

    ; Skip if on cooldown
    cmp     dword ptr [r13 + TOWER_COOL_TIMER], 0
    jg      @@next_tower

    ; Tower is ready to fire — find nearest enemy in range
    mov     r14d, [r13 + TOWER_X]       ; tower x
    mov     r15d, [r13 + TOWER_Y]       ; tower y
    mov     edi, [r13 + TOWER_RANGE]    ; tower range

    ; Search enemies for closest in range
    lea     rsi, [enemies]
    xor     ecx, ecx                    ; enemy index
    mov     r8d, 9999                   ; best distance (Manhattan)
    mov     r9d, -1                     ; best enemy index

@@enemy_scan:
    cmp     ecx, MAX_ENEMIES
    jge     @@fire_check

    push    rcx
    mov     eax, ecx
    imul    eax, ENEMY_STRUCT_SIZE

    ; Skip inactive
    cmp     dword ptr [rsi + rax + ENEMY_ACTIVE], 0
    je      @@next_enemy

    ; Skip dead
    cmp     dword ptr [rsi + rax + ENEMY_HEALTH], 0
    jle     @@next_enemy

    ; Calculate Manhattan distance
    mov     edx, [rsi + rax + ENEMY_X]
    sub     edx, r14d                   ; dx = enemy_x - tower_x
    ; abs(dx)
    mov     r10d, edx
    sar     r10d, 31
    xor     edx, r10d
    sub     edx, r10d                   ; edx = abs(dx)

    mov     r10d, [rsi + rax + ENEMY_Y]
    sub     r10d, r15d                  ; dy = enemy_y - tower_y
    ; abs(dy)
    mov     r11d, r10d
    sar     r11d, 31
    xor     r10d, r11d
    sub     r10d, r11d                  ; r10d = abs(dy)

    add     edx, r10d                   ; distance = abs(dx) + abs(dy)

    ; Check if in range
    cmp     edx, edi
    jg      @@next_enemy

    ; Check if closer than current best
    cmp     edx, r8d
    jge     @@next_enemy

    mov     r8d, edx                    ; new best distance
    pop     rcx
    mov     r9d, ecx                    ; new best enemy index
    push    rcx

@@next_enemy:
    pop     rcx
    inc     ecx
    jmp     @@enemy_scan

@@fire_check:
    ; Did we find a target?
    cmp     r9d, -1
    je      @@next_tower

    ; Apply damage to the enemy
    mov     eax, r9d
    imul    eax, ENEMY_STRUCT_SIZE
    lea     rsi, [enemies]

    mov     edx, [r13 + TOWER_DAMAGE]
    sub     dword ptr [rsi + rax + ENEMY_HEALTH], edx

    ; Set tower cooldown
    mov     edx, [r13 + TOWER_COOLDOWN]
    mov     [r13 + TOWER_COOL_TIMER], edx

    ; Check if enemy died
    cmp     dword ptr [rsi + rax + ENEMY_HEALTH], 0
    jg      @@next_tower

    ; Enemy killed — award score and gold
    mov     dword ptr [rsi + rax + ENEMY_ACTIVE], 0
    dec     dword ptr [enemies_alive]
    cmp     dword ptr [enemies_alive], 0
    jge     @@alive_ok
    mov     dword ptr [enemies_alive], 0
@@alive_ok:

    ; Award gold
    add     dword ptr [player_gold], KILL_REWARD

    ; Award score (10 points per kill)
    mov     ecx, 10
    call    score_add

@@next_tower:
    inc     ebx
    jmp     @@tower_loop

@@done:
    add     rsp, 56
    ret
collision_update endp

end
