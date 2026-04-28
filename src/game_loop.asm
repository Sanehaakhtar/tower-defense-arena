; ============================================================================
; game_loop.asm — Main game loop logic, wave/level state machine
; Tower Defense Arena
; ============================================================================

option casemap:none

include src/defs.inc

extrn enemies_update:proc
extrn enemies_spawn:proc
extrn enemies_init:proc
extrn towers_update:proc
extrn towers_init:proc
extrn collision_update:proc
extrn score_init:proc
extrn input_get_key:proc

public game_loop_init
public game_loop_update

.code

; ============================================================================
; game_loop_init — Full reset, go to menu
; ============================================================================
game_loop_init proc
    sub     rsp, 40

    ; Fill level_path_ptrs / level_path_lens tables at runtime
    ; (we need actual addresses, not link-time constants for the qword table)
    lea     rax, [path_l1]
    mov     [level_path_ptrs + 0],  rax
    lea     rax, [path_l2]
    mov     [level_path_ptrs + 8],  rax
    lea     rax, [path_l3]
    mov     [level_path_ptrs + 16], rax
    lea     rax, [path_l4]
    mov     [level_path_ptrs + 24], rax
    lea     rax, [path_l5]
    mov     [level_path_ptrs + 32], rax

    mov     eax, [path_l1_len]
    mov     [level_path_lens + 0],  eax
    mov     eax, [path_l2_len]
    mov     [level_path_lens + 4],  eax
    mov     eax, [path_l3_len]
    mov     [level_path_lens + 8],  eax
    mov     eax, [path_l4_len]
    mov     [level_path_lens + 12], eax
    mov     eax, [path_l5_len]
    mov     [level_path_lens + 16], eax

    mov     dword ptr [game_state],     STATE_MENU
    mov     dword ptr [current_wave],   0
    mov     dword ptr [wave_in_level],  0
    mov     dword ptr [current_level],  1
    ; levels_unlocked persists across restarts — only reset on very first call
    ; (it is initialised to 1 in data.asm)
    mov     dword ptr [level_cursor],   0
    mov     dword ptr [wave_timer],     0
    mov     dword ptr [spawn_timer],    0
    mov     dword ptr [spawn_count],    0
    mov     dword ptr [enemies_alive],  0
    mov     dword ptr [frame_counter],  0
    mov     dword ptr [player_lives],   STARTING_LIVES
    mov     dword ptr [player_gold],    STARTING_GOLD
    mov     dword ptr [game_running],   1

    add     rsp, 40
    ret
game_loop_init endp

; ============================================================================
; load_level_path — Point path_data / path_length at the current level's path
; Inputs:  none (reads current_level)
; ============================================================================
load_level_path proc
    sub     rsp, 40

    mov     eax, [current_level]
    dec     eax                        ; 0-based index
    ; clamp 0..MAX_LEVELS-1
    cmp     eax, MAX_LEVELS - 1
    jle     @@ok
    mov     eax, MAX_LEVELS - 1
@@ok:
    ; path_data is a qword pointer
    lea     rcx, [level_path_ptrs]
    mov     rax, [rcx + rax*8]        ; load the qword pointer
    mov     [path_data], rax

    mov     eax, [current_level]
    dec     eax
    cmp     eax, MAX_LEVELS - 1
    jle     @@ok2
    mov     eax, MAX_LEVELS - 1
@@ok2:
    lea     rcx, [level_path_lens]
    mov     edx, [rcx + rax*4]
    mov     [path_length], edx

    add     rsp, 40
    ret
load_level_path endp

; ============================================================================
; init_map — Mark path/spawn/base tiles from path_data
; ============================================================================
init_map proc
    sub     rsp, 40

    ; Clear map
    cld
    lea     rdi, [map_tiles]
    mov     ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    xor     eax, eax
    rep     stosb

    ; path_data is now a qword pointer — dereference it
    mov     rsi, [path_data]
    mov     ecx, [path_length]
    xor     edx, edx

@@path_loop:
    cmp     edx, ecx
    jge     @@path_done

    push    rcx
    push    rdx

    mov     eax, [rsi + rdx*8]        ; x
    mov     r8d, [rsi + rdx*8 + 4]    ; y

    imul    r8d, r8d, SCREEN_WIDTH
    add     r8d, eax
    lea     rdi, [map_tiles]
    mov     byte ptr [rdi + r8], TILE_PATH

    pop     rdx
    pop     rcx
    inc     edx
    jmp     @@path_loop

@@path_done:
    ; Spawn = first point
    mov     rsi, [path_data]
    mov     eax, [rsi]
    mov     r8d, [rsi + 4]
    imul    r8d, r8d, SCREEN_WIDTH
    add     r8d, eax
    lea     rdi, [map_tiles]
    mov     byte ptr [rdi + r8], TILE_SPAWN

    ; Base = last point
    mov     ecx, [path_length]
    dec     ecx
    mov     eax, [rsi + rcx*8]
    mov     r8d, [rsi + rcx*8 + 4]
    imul    r8d, r8d, SCREEN_WIDTH
    add     r8d, eax
    mov     byte ptr [rdi + r8], TILE_BASE

    add     rsp, 40
    ret
init_map endp

; ============================================================================
; start_level — Set up path/map/enemies/towers for current_level, wave 1
; ============================================================================
start_level proc
    sub     rsp, 40

    ; Explicitly zero towers array before anything else
    cld
    lea     rdi, [towers]
    mov     ecx, MAX_TOWERS * TOWER_STRUCT_SIZE
    xor     eax, eax
    rep     stosb

    ; Explicitly zero enemies array
    cld
    lea     rdi, [enemies]
    mov     ecx, MAX_ENEMIES * ENEMY_STRUCT_SIZE
    xor     eax, eax
    rep     stosb

    mov     dword ptr [enemies_alive], 0

    call    load_level_path
    call    init_map
    call    enemies_init
    call    towers_init

    mov     dword ptr [wave_in_level], 1
    mov     dword ptr [spawn_count],   0
    mov     dword ptr [spawn_timer],   0
    mov     dword ptr [frame_counter], 0
    mov     dword ptr [player_lives],  STARTING_LIVES
    mov     dword ptr [player_gold],   STARTING_GOLD
    call    score_init

    mov     dword ptr [game_state], STATE_PLAYING

    add     rsp, 40
    ret
start_level endp

; ============================================================================
; enemies_this_wave — Calculate how many enemies to spawn
; Formula: ENEMY_BASE + (wave_in_level * ENEMY_WAVE_INC) + (current_level * ENEMY_LEVEL_INC)
; Returns: eax = enemy count
; ============================================================================
enemies_this_wave proc
    mov     eax, ENEMY_BASE
    mov     ecx, [wave_in_level]
    imul    ecx, ENEMY_WAVE_INC
    add     eax, ecx
    mov     ecx, [current_level]
    imul    ecx, ENEMY_LEVEL_INC
    add     eax, ecx
    ret
enemies_this_wave endp

; ============================================================================
; health_this_wave — Base health scaled by level+wave
; Returns: eax = health multiplier (percentage, 100 = base 50hp)
; ============================================================================
health_this_wave proc
    ; 100 + (current_level - 1)*30 + (wave_in_level - 1)*15
    mov     eax, 100
    mov     ecx, [current_level]
    dec     ecx
    imul    ecx, 30
    add     eax, ecx
    mov     ecx, [wave_in_level]
    dec     ecx
    imul    ecx, 15
    add     eax, ecx
    ret
health_this_wave endp

; ============================================================================
; game_loop_update — Frame tick dispatcher
; ============================================================================
game_loop_update proc
    sub     rsp, 40

    inc     dword ptr [frame_counter]

    mov     eax, [game_state]

    cmp     eax, STATE_MENU
    je      @@menu
    cmp     eax, STATE_LEVEL_SELECT
    je      @@lvlsel
    cmp     eax, STATE_PLAYING
    je      @@playing
    cmp     eax, STATE_WAVE_COMPLETE
    je      @@wavecomplete
    cmp     eax, STATE_LEVEL_COMPLETE
    je      @@levelcomplete
    cmp     eax, STATE_GAME_OVER
    je      @@gameover
    cmp     eax, STATE_WIN
    je      @@gameover
    jmp     @@done

@@menu:         call handle_menu          ; jmp @@done implicit via structure
    jmp     @@done
@@lvlsel:       call handle_level_select
    jmp     @@done
@@playing:      call handle_playing
    jmp     @@done
@@wavecomplete: call handle_wave_complete
    jmp     @@done
@@levelcomplete:call handle_level_complete
    jmp     @@done
@@gameover:     call handle_game_over
@@done:
    add     rsp, 40
    ret
game_loop_update endp

; ============================================================================
; handle_menu — ENTER goes to level select, Q quits
; ============================================================================
handle_menu proc
    sub     rsp, 40
    call    input_get_key
    cmp     eax, VK_RETURN
    je      @@go_select
    cmp     eax, VK_Q
    je      @@quit
    jmp     @@done
@@go_select:
    ; Reset cursor to first unlocked level
    mov     dword ptr [level_cursor], 0
    mov     dword ptr [game_state], STATE_LEVEL_SELECT
    jmp     @@done
@@quit:
    mov     dword ptr [game_running], 0
@@done:
    add     rsp, 40
    ret
handle_menu endp

; ============================================================================
; handle_level_select — LEFT/RIGHT navigate, ENTER play, Q back to menu
; ============================================================================
handle_level_select proc
    sub     rsp, 40
    call    input_get_key
    test    eax, eax
    jz      @@done

    cmp     eax, VK_LEFT
    je      @@go_left
    cmp     eax, VK_RIGHT
    je      @@go_right
    cmp     eax, VK_RETURN
    je      @@select
    cmp     eax, VK_Q
    je      @@back
    jmp     @@done

@@go_left:
    cmp     dword ptr [level_cursor], 0
    jle     @@done
    dec     dword ptr [level_cursor]
    jmp     @@done

@@go_right:
    mov     eax, [level_cursor]
    inc     eax
    cmp     eax, MAX_LEVELS
    jge     @@done
    mov     [level_cursor], eax
    jmp     @@done

@@select:
    ; Only allow if cursor <= levels_unlocked - 1
    mov     eax, [level_cursor]
    mov     ecx, [levels_unlocked]
    dec     ecx
    cmp     eax, ecx
    jg      @@done                     ; locked — ignore
    ; Set current_level = cursor + 1
    inc     eax
    mov     [current_level], eax
    call    start_level
    jmp     @@done

@@back:
    mov     dword ptr [game_state], STATE_MENU
@@done:
    add     rsp, 40
    ret
handle_level_select endp

; ============================================================================
; handle_playing — Spawn, update, check wave/level/life end
; ============================================================================
handle_playing proc
    sub     rsp, 40

    call    input_get_key
    cmp     eax, VK_Q
    je      @@quit

    ; How many enemies total this wave?
    call    enemies_this_wave          ; eax = total
    mov     r10d, eax

    ; Spawn if not all spawned yet
    mov     ecx, [spawn_count]
    cmp     ecx, r10d
    jge     @@no_spawn

    ; First enemy spawns immediately (spawn_count=0), rest use interval
    cmp     dword ptr [spawn_count], 0
    je      @@do_spawn

    inc     dword ptr [spawn_timer]
    mov     eax, [spawn_timer]
    cmp     eax, SPAWN_INTERVAL
    jl      @@no_spawn

@@do_spawn:
    mov     dword ptr [spawn_timer], 0
    inc     dword ptr [spawn_count]

    call    health_this_wave           ; eax = health multiplier
    mov     ecx, eax
    call    enemies_spawn

@@no_spawn:
    call    enemies_update
    call    towers_update
    call    collision_update

    ; Check lives
    cmp     dword ptr [player_lives], 0
    jle     @@game_over

    ; Check wave complete: all spawned AND none alive
    call    enemies_this_wave
    mov     r10d, eax
    mov     eax, [spawn_count]
    cmp     eax, r10d
    jl      @@done                     ; still spawning
    cmp     dword ptr [enemies_alive], 0
    jnz     @@done                     ; still alive

    ; Wave done — is this the last wave of the level?
    mov     eax, [wave_in_level]
    cmp     eax, WAVES_PER_LEVEL
    jge     @@level_done

    ; More waves in this level
    mov     dword ptr [game_state], STATE_WAVE_COMPLETE
    jmp     @@done

@@level_done:
    ; Is this the last level?
    mov     eax, [current_level]
    cmp     eax, MAX_LEVELS
    jge     @@win

    ; Unlock next level if needed
    mov     eax, [current_level]
    inc     eax                        ; next level number
    mov     ecx, [levels_unlocked]
    cmp     eax, ecx
    jle     @@skip_unlock
    mov     [levels_unlocked], eax
@@skip_unlock:
    mov     dword ptr [game_state], STATE_LEVEL_COMPLETE
    jmp     @@done

@@win:
    mov     dword ptr [game_state], STATE_WIN
    jmp     @@done

@@game_over:
    mov     dword ptr [game_state], STATE_GAME_OVER
    jmp     @@done

@@quit:
    mov     dword ptr [game_state], STATE_LEVEL_SELECT
@@done:
    add     rsp, 40
    ret
handle_playing endp

; ============================================================================
; handle_wave_complete — between waves within a level
; ============================================================================
handle_wave_complete proc
    sub     rsp, 40
    call    input_get_key
    cmp     eax, VK_RETURN
    jne     @@done

    inc     dword ptr [wave_in_level]
    mov     dword ptr [spawn_count],  0
    mov     dword ptr [spawn_timer],  0
    add     dword ptr [player_gold],  25
    mov     dword ptr [game_state],   STATE_PLAYING
@@done:
    add     rsp, 40
    ret
handle_wave_complete endp

; ============================================================================
; handle_level_complete — between levels
; ============================================================================
handle_level_complete proc
    sub     rsp, 40
    call    input_get_key
    cmp     eax, VK_RETURN
    je      @@next
    cmp     eax, VK_Q
    je      @@menu
    jmp     @@done

@@next:
    inc     dword ptr [current_level]
    call    start_level
    jmp     @@done

@@menu:
    mov     dword ptr [game_state], STATE_LEVEL_SELECT
    mov     eax, [current_level]      ; pre-select the next level on return
    mov     [level_cursor], eax       ; cursor = (new current_level - 1) already incremented above
    dec     dword ptr [level_cursor]
@@done:
    add     rsp, 40
    ret
handle_level_complete endp

; ============================================================================
; handle_game_over — ENTER restarts level, Q goes to level select
; ============================================================================
handle_game_over proc
    sub     rsp, 40
    call    input_get_key
    cmp     eax, VK_RETURN
    je      @@restart
    cmp     eax, VK_Q
    je      @@menu
    jmp     @@done

@@restart:
    call    enemies_init
    call    towers_init
    call    start_level
    jmp     @@done

@@menu:
    mov     dword ptr [game_state], STATE_LEVEL_SELECT
@@done:
    add     rsp, 40
    ret
handle_game_over endp

end
