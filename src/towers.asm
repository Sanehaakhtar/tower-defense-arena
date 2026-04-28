; ============================================================================
; towers.asm — Tower struct, placement, attack, cooldown
; Tower Defense Arena
;
; Owner: Saneha (517085)
; ============================================================================

option casemap:none

include src/defs.inc

; ============================================================================
; Public procedures
; ============================================================================
public towers_init
public towers_update
public towers_place

.code

; ============================================================================
; towers_init — Initialize all towers to inactive
; Purpose: Clear the tower array
; Inputs:  none
; Outputs: none
; ============================================================================
towers_init proc
    sub     rsp, 40

    cld
    lea     rdi, [towers]
    mov     ecx, MAX_TOWERS * TOWER_STRUCT_SIZE
    xor     eax, eax
    rep     stosb

    add     rsp, 40
    ret
towers_init endp

; ============================================================================
; towers_place — Attempt to place a tower at cursor position
; Purpose: Place a tower if the cell is valid and player has enough gold
; Inputs:  none (reads cursor_x, cursor_y, selected_tower_type, player_gold)
; Outputs: eax = 1 if placed, 0 if failed
; ============================================================================
towers_place proc
    sub     rsp, 40

    ; Check map tile — must be empty
    mov     eax, [cursor_y]
    imul    eax, SCREEN_WIDTH
    add     eax, [cursor_x]
    lea     rsi, [map_tiles]
    movzx   edx, byte ptr [rsi + rax]
    cmp     edx, TILE_EMPTY
    jne     @@fail

    ; Check cursor is in playable area (not HUD rows)
    mov     eax, [cursor_y]
    cmp     eax, 1
    jl      @@fail
    cmp     eax, SCREEN_HEIGHT - 3
    jge     @@fail

    ; Determine cost
    mov     ecx, [selected_tower_type]
    cmp     ecx, TOWER_BASIC
    je      @@cost_basic
    cmp     ecx, TOWER_SNIPER
    je      @@cost_sniper
    cmp     ecx, TOWER_SPLASH
    je      @@cost_splash
    jmp     @@fail

@@cost_basic:
    mov     edx, TOWER_COST_BASIC
    jmp     @@check_gold
@@cost_sniper:
    mov     edx, TOWER_COST_SNIPER
    jmp     @@check_gold
@@cost_splash:
    mov     edx, TOWER_COST_SPLASH

@@check_gold:
    cmp     [player_gold], edx
    jl      @@fail

    ; Find inactive tower slot
    lea     rsi, [towers]
    xor     ecx, ecx

@@find_slot:
    cmp     ecx, MAX_TOWERS
    jge     @@fail

    mov     eax, ecx
    imul    eax, TOWER_STRUCT_SIZE
    cmp     dword ptr [rsi + rax + TOWER_ACTIVE], 0
    je      @@found_slot
    inc     ecx
    jmp     @@find_slot

@@found_slot:
    mov     eax, ecx
    imul    eax, TOWER_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    ; Set position
    mov     eax, [cursor_x]
    mov     [rdi + TOWER_X], eax
    mov     eax, [cursor_y]
    mov     [rdi + TOWER_Y], eax

    ; Set stats based on type
    mov     ecx, [selected_tower_type]
    mov     [rdi + TOWER_TYPE], ecx

    cmp     ecx, TOWER_BASIC
    je      @@stats_basic
    cmp     ecx, TOWER_SNIPER
    je      @@stats_sniper
    jmp     @@stats_splash

@@stats_basic:
    mov     dword ptr [rdi + TOWER_RANGE], TOWER_RANGE_BASIC
    mov     dword ptr [rdi + TOWER_DAMAGE], TOWER_DMG_BASIC
    mov     dword ptr [rdi + TOWER_COOLDOWN], TOWER_COOLDOWN_BASIC
    sub     dword ptr [player_gold], TOWER_COST_BASIC
    jmp     @@activate

@@stats_sniper:
    mov     dword ptr [rdi + TOWER_RANGE], TOWER_RANGE_SNIPER
    mov     dword ptr [rdi + TOWER_DAMAGE], TOWER_DMG_SNIPER
    mov     dword ptr [rdi + TOWER_COOLDOWN], TOWER_COOLDOWN_SNIPER
    sub     dword ptr [player_gold], TOWER_COST_SNIPER
    jmp     @@activate

@@stats_splash:
    mov     dword ptr [rdi + TOWER_RANGE], TOWER_RANGE_SPLASH
    mov     dword ptr [rdi + TOWER_DAMAGE], TOWER_DMG_SPLASH
    mov     dword ptr [rdi + TOWER_COOLDOWN], TOWER_COOLDOWN_SPLASH
    sub     dword ptr [player_gold], TOWER_COST_SPLASH

@@activate:
    mov     dword ptr [rdi + TOWER_COOL_TIMER], 0
    mov     dword ptr [rdi + TOWER_ACTIVE], 1

    ; Mark tile as tower
    mov     eax, [cursor_y]
    imul    eax, SCREEN_WIDTH
    add     eax, [cursor_x]
    lea     rsi, [map_tiles]
    mov     byte ptr [rsi + rax], TILE_TOWER

    mov     eax, 1
    add     rsp, 40
    ret

@@fail:
    xor     eax, eax
    add     rsp, 40
    ret
towers_place endp

; ============================================================================
; towers_update — Update all active towers (cooldown tick)
; Purpose: Decrement cooldown timers each frame
; Inputs:  none
; Outputs: none
; ============================================================================
towers_update proc
    sub     rsp, 40

    lea     rsi, [towers]
    xor     ecx, ecx

@@tower_loop:
    cmp     ecx, MAX_TOWERS
    jge     @@done

    mov     eax, ecx
    imul    eax, TOWER_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    ; Skip inactive
    cmp     dword ptr [rdi + TOWER_ACTIVE], 0
    je      @@next

    ; Decrement cooldown timer
    cmp     dword ptr [rdi + TOWER_COOL_TIMER], 0
    jle     @@next
    dec     dword ptr [rdi + TOWER_COOL_TIMER]

@@next:
    inc     ecx
    jmp     @@tower_loop

@@done:
    add     rsp, 40
    ret
towers_update endp

end
