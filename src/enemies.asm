; ============================================================================
; enemies.asm — Enemy struct management, spawning, movement, path logic
; Tower Defense Arena
;
; Owner: Khadija (502430)
; ============================================================================

option casemap:none

include src/defs.inc

; ============================================================================
; Public procedures
; ============================================================================
public enemies_init
public enemies_update
public enemies_spawn

.code

; ============================================================================
; enemies_init — Initialize all enemies to inactive
; Purpose: Clear the enemy array
; Inputs:  none
; Outputs: none
; ============================================================================
enemies_init proc
    sub     rsp, 40

    cld
    lea     rdi, [enemies]
    mov     ecx, MAX_ENEMIES * ENEMY_STRUCT_SIZE
    xor     eax, eax
    rep     stosb

    mov     dword ptr [enemies_alive], 0

    add     rsp, 40
    ret
enemies_init endp

; ============================================================================
; enemies_spawn — Spawn a new enemy at the path start
; Purpose: Find an inactive enemy slot and initialize it
; Inputs:  ecx = health multiplier (percentage, 100 = base)
; Outputs: none
; ============================================================================
enemies_spawn proc
    sub     rsp, 40

    mov     r10d, ecx                  ; save health mult

    ; Find first inactive enemy slot
    lea     rsi, [enemies]
    xor     ecx, ecx

@@find_slot:
    cmp     ecx, MAX_ENEMIES
    jge     @@done                     ; no slots available

    mov     eax, ecx
    imul    eax, ENEMY_STRUCT_SIZE
    cmp     dword ptr [rsi + rax + ENEMY_ACTIVE], 0
    je      @@found_slot
    inc     ecx
    jmp     @@find_slot

@@found_slot:
    mov     eax, ecx
    imul    eax, ENEMY_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    ; Set position to first path point
    mov     r8, [path_data]           ; path_data is now a pointer
    mov     edx, [r8]                 ; start x
    mov     [rdi + ENEMY_X], edx
    mov     edx, [r8 + 4]             ; start y
    mov     [rdi + ENEMY_Y], edx

    ; Set health: base 50, scaled by multiplier
    ; NOTE: cdq sign-extends eax into edx, so divisor must NOT be in edx
    mov     eax, 50
    imul    eax, r10d                  ; * multiplier (eax = 50 * mult)
    cdq                                ; sign-extend eax into edx (edx = 0)
    mov     ecx, 100                   ; divisor in ecx (not edx!)
    idiv    ecx                        ; eax = health = (50 * mult) / 100
    mov     [rdi + ENEMY_HEALTH], eax
    mov     [rdi + ENEMY_MAX_HEALTH], eax

    ; Set speed (ticks between moves)
    mov     dword ptr [rdi + ENEMY_SPEED], ENEMY_MOVE_TICKS

    ; Set path index
    mov     dword ptr [rdi + ENEMY_PATH_IDX], 0

    ; Activate
    mov     dword ptr [rdi + ENEMY_ACTIVE], 1

    ; Timer
    mov     dword ptr [rdi + ENEMY_MOVE_TIMER], 0

    ; Type
    mov     dword ptr [rdi + ENEMY_TYPE], 0

    ; Increment alive count
    inc     dword ptr [enemies_alive]

@@done:
    add     rsp, 40
    ret
enemies_spawn endp

; ============================================================================
; enemies_update — Update all active enemies (movement along path)
; Purpose: Move enemies along the path, check if they reach the base
; Inputs:  none
; Outputs: none (modifies enemies array, player_lives)
; ============================================================================
enemies_update proc
    sub     rsp, 40

    lea     rsi, [enemies]
    xor     ecx, ecx                   ; enemy index

@@enemy_loop:
    cmp     ecx, MAX_ENEMIES
    jge     @@done

    push    rcx

    mov     eax, ecx
    imul    eax, ENEMY_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    ; Skip inactive
    cmp     dword ptr [rdi + ENEMY_ACTIVE], 0
    je      @@next

    ; Check health <= 0 (killed by tower)
    cmp     dword ptr [rdi + ENEMY_HEALTH], 0
    jle     @@deactivate

    ; Increment move timer
    inc     dword ptr [rdi + ENEMY_MOVE_TIMER]
    mov     eax, [rdi + ENEMY_MOVE_TIMER]
    cmp     eax, [rdi + ENEMY_SPEED]
    jl      @@next                     ; not time to move yet

    ; Reset timer
    mov     dword ptr [rdi + ENEMY_MOVE_TIMER], 0

    ; Advance path index
    inc     dword ptr [rdi + ENEMY_PATH_IDX]
    mov     eax, [rdi + ENEMY_PATH_IDX]

    ; Check if reached end of path
    cmp     eax, [path_length]
    jge     @@reached_base

    ; Move to next path point
    mov     r8, [path_data]           ; path_data is now a pointer
    mov     edx, [r8 + rax*8]         ; new x
    mov     [rdi + ENEMY_X], edx
    mov     edx, [r8 + rax*8 + 4]     ; new y
    mov     [rdi + ENEMY_Y], edx
    jmp     @@next

@@reached_base:
    ; Enemy reached the base — lose a life
    dec     dword ptr [player_lives]
    jmp     @@deactivate

@@deactivate:
    mov     dword ptr [rdi + ENEMY_ACTIVE], 0
    dec     dword ptr [enemies_alive]
    ; Ensure alive count doesn't go negative
    cmp     dword ptr [enemies_alive], 0
    jge     @@next
    mov     dword ptr [enemies_alive], 0

@@next:
    pop     rcx
    inc     ecx
    jmp     @@enemy_loop

@@done:
    add     rsp, 40
    ret
enemies_update endp

end
