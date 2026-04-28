; ============================================================================
; renderer.asm — All display output via Windows Console API
; Tower Defense Arena
; ============================================================================

option casemap:none

include src/defs.inc

public renderer_init
public renderer_draw

; ============================================================================
; Local string constants — must be in .data, NOT inline in .code
; ============================================================================
.data

rnd_lbracket    db '[', 0
rnd_rbracket    db ']', 0
rnd_open        db 'OPEN  ', 0
rnd_str_lvl     db 'Lvl:', 0
rnd_ch_path     db '.', 0
rnd_ch_spawn    db 'S', 0
rnd_ch_base     db 'B', 0
rnd_ch_basic    db 'T', 0
rnd_ch_sniper   db 'R', 0
rnd_ch_splash   db 'X', 0
rnd_ch_enemy    db 'E', 0
rnd_ch_cursor   db '*', 0

; SMALL_RECTs for console resize (must be in .data)
rnd_tiny_rect   dw 0, 0, 1, 1
rnd_win_rect    dw 0, 0, SCREEN_WIDTH-1, SCREEN_HEIGHT-1

.code

; ============================================================================
; renderer_init — Lock console to SCREEN_WIDTH x SCREEN_HEIGHT, hide cursor
; ============================================================================
renderer_init proc
    sub     rsp, 40

    mov     rcx, [hStdOut]
    mov     edx, 1
    lea     r8, [rnd_tiny_rect]
    call    SetConsoleWindowInfo

    mov     rcx, [hStdOut]
    mov     edx, (SCREEN_HEIGHT SHL 16) OR SCREEN_WIDTH
    call    SetConsoleScreenBufferSize

    mov     rcx, [hStdOut]
    mov     edx, 1
    lea     r8, [rnd_win_rect]
    call    SetConsoleWindowInfo

    mov     rcx, [hStdOut]
    lea     rdx, [cursor_info]
    call    SetConsoleCursorInfo

    add     rsp, 40
    ret
renderer_init endp

; ============================================================================
; renderer_draw — Dispatch based on game_state
; ============================================================================
renderer_draw proc
    sub     rsp, 40

    mov     eax, [game_state]

    cmp     eax, STATE_MENU
    je      @@menu
    cmp     eax, STATE_LEVEL_SELECT
    je      @@lvlsel
    cmp     eax, STATE_PLAYING
    je      @@game
    cmp     eax, STATE_WAVE_COMPLETE
    je      @@game
    cmp     eax, STATE_LEVEL_COMPLETE
    je      @@game
    cmp     eax, STATE_GAME_OVER
    je      @@end
    cmp     eax, STATE_WIN
    je      @@end
    jmp     @@done

@@menu:
    call    draw_menu_screen
    jmp     @@done
@@lvlsel:
    call    draw_level_select
    jmp     @@done
@@game:
    call    draw_game_screen
    jmp     @@done
@@end:
    call    draw_end_screen
@@done:
    add     rsp, 40
    ret
renderer_draw endp

; ============================================================================
; write_str_at  ecx=x  edx=y  r8=ptr
; Writes string into screen_buf at (x,y) — no console call, no flicker
; ============================================================================
write_str_at proc
    sub     rsp, 40

    ; offset = y * SCREEN_WIDTH + x
    mov     eax, edx
    imul    eax, SCREEN_WIDTH
    add     eax, ecx

    ; clamp: if offset >= W*H, skip
    cmp     eax, SCREEN_WIDTH * SCREEN_HEIGHT
    jge     @@done

    lea     rdi, [screen_buf]
    add     rdi, rax                   ; rdi = &screen_buf[offset]

@@copy:
    cmp     byte ptr [r8], 0
    je      @@done
    ; clamp per-char: don't write past end of buffer
    mov     al, [r8]
    mov     [rdi], al
    inc     r8
    inc     rdi
    ; check we haven't gone past buffer end
    lea     rax, [screen_buf]
    add     rax, SCREEN_WIDTH * SCREEN_HEIGHT
    cmp     rdi, rax
    jge     @@done
    jmp     @@copy

@@done:
    add     rsp, 40
    ret
write_str_at endp

; ============================================================================
; write_num_at  ecx=x  edx=y  r8d=number
; ============================================================================
write_num_at proc
    sub     rsp, 88

    mov     dword ptr [rsp+40], ecx
    mov     dword ptr [rsp+44], edx
    mov     eax, r8d

    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+56], 0

    lea     r9, [rsp+62]

    test    eax, eax
    jnz     @@conv
    mov     byte ptr [r9], '0'
    dec     r9
    jmp     @@write

@@conv:
    jns     @@pos
    neg     eax
@@pos:
    mov     ecx, 10
@@div:
    test    eax, eax
    jz      @@write
    xor     edx, edx
    div     ecx
    add     dl, '0'
    mov     [r9], dl
    dec     r9
    jmp     @@div

@@write:
    inc     r9
    mov     ecx, dword ptr [rsp+40]
    mov     edx, dword ptr [rsp+44]
    mov     r8, r9
    call    write_str_at

    add     rsp, 88
    ret
write_num_at endp

; ============================================================================
; clear_screen — move cursor to 0,0 only (screen_buf handles actual output)
; We no longer blast FillConsole every frame — frame_render does one write
; ============================================================================
clear_screen proc
    sub     rsp, 40

    ; Fill screen_buf with spaces
    lea     rdi, [screen_buf]
    mov     ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov     al, ' '
    rep     stosb

    add     rsp, 40
    ret
clear_screen endp

; ============================================================================
; frame_render — write each row at exact position (handles any console width)
; Uses SetConsoleCursorPosition + WriteConsoleA per row = correct alignment
; ============================================================================
frame_render proc
    sub     rsp, 40

    xor     ebx, ebx                   ; row = 0

@@row_loop:
    cmp     ebx, SCREEN_HEIGHT
    jge     @@done

    ; SetConsoleCursorPosition(hStdOut, COORD{x=0, y=row})
    mov     rcx, [hStdOut]
    mov     edx, ebx
    shl     edx, 16                    ; Y in high word, X=0 in low word
    call    SetConsoleCursorPosition

    ; WriteConsoleA(hStdOut, &screen_buf[row*W], W, &written, NULL)
    mov     rcx, [hStdOut]
    lea     rdx, [screen_buf]
    mov     eax, ebx
    imul    eax, SCREEN_WIDTH
    add     rdx, rax                   ; rdx = row start in buffer
    mov     r8d, SCREEN_WIDTH
    lea     r9, [temp_written]
    mov     qword ptr [rsp+32], 0
    call    WriteConsoleA

    inc     ebx
    jmp     @@row_loop

@@done:
    add     rsp, 40
    ret
frame_render endp

; ============================================================================
; draw_menu_screen
; ============================================================================
draw_menu_screen proc
    sub     rsp, 40

    call    clear_screen

    mov     ecx, 16
    mov     edx, 9
    lea     r8, [str_menu_title]
    call    write_str_at

    mov     ecx, 10
    mov     edx, 12
    lea     r8, [str_menu_quit]
    call    write_str_at

    mov     ecx, 14
    mov     edx, 15
    lea     r8, [str_menu_play]
    call    write_str_at

    call    frame_render
    add     rsp, 40
    ret
draw_menu_screen endp

; ============================================================================
; draw_level_select — 5 slots, LEFT/RIGHT nav, locked/open state
; ============================================================================
draw_level_select proc
    sub     rsp, 40

    call    clear_screen

    mov     ecx, 20
    mov     edx, 8
    lea     r8, [str_level_select_title]
    call    write_str_at

    mov     ecx, 11
    mov     edx, 19
    lea     r8, [str_level_select_hint]
    call    write_str_at

    xor     ebx, ebx                   ; i = 0

@@slot_loop:
    cmp     ebx, MAX_LEVELS
    jge     @@slots_done

    ; x = 5 + i*11
    mov     eax, ebx
    imul    eax, 11
    add     eax, 5
    mov     dword ptr [rsp+32], eax    ; save slot x

    ; Draw bracket if this is the cursor position
    cmp     ebx, [level_cursor]
    jne     @@draw_label

    mov     ecx, dword ptr [rsp+32]
    dec     ecx
    mov     edx, 12
    lea     r8, [rnd_lbracket]
    call    write_str_at

    mov     ecx, dword ptr [rsp+32]
    add     ecx, 7
    mov     edx, 12
    lea     r8, [rnd_rbracket]
    call    write_str_at

@@draw_label:
    ; "LEVEL " text
    mov     ecx, dword ptr [rsp+32]
    mov     edx, 12
    lea     r8, [str_level_label]
    call    write_str_at

    ; level number
    mov     ecx, dword ptr [rsp+32]
    add     ecx, 6
    mov     edx, 12
    mov     r8d, ebx
    inc     r8d
    call    write_num_at

    ; locked or open?
    mov     eax, ebx
    mov     ecx, [levels_unlocked]
    dec     ecx
    cmp     eax, ecx
    jle     @@show_open

    mov     ecx, dword ptr [rsp+32]
    mov     edx, 14
    lea     r8, [str_locked]
    call    write_str_at
    jmp     @@next_slot

@@show_open:
    mov     ecx, dword ptr [rsp+32]
    mov     edx, 14
    lea     r8, [rnd_open]
    call    write_str_at

@@next_slot:
    inc     ebx
    jmp     @@slot_loop

@@slots_done:
    call    frame_render
    add     rsp, 40
    ret
draw_level_select endp

; ============================================================================
; draw_game_screen
; ============================================================================
draw_game_screen proc
    sub     rsp, 40

    call    clear_screen

    ; Wave X/3
    mov     ecx, 0
    mov     edx, 0
    lea     r8, [str_wave_text]
    call    write_str_at

    mov     ecx, 6
    mov     edx, 0
    mov     r8d, [wave_in_level]
    call    write_num_at

    mov     ecx, 7
    mov     edx, 0
    lea     r8, [str_wave_of]
    call    write_str_at

    mov     ecx, 8
    mov     edx, 0
    mov     r8d, WAVES_PER_LEVEL
    call    write_num_at

    ; Lvl:N
    mov     ecx, 11
    mov     edx, 0
    lea     r8, [rnd_str_lvl]
    call    write_str_at

    mov     ecx, 15
    mov     edx, 0
    mov     r8d, [current_level]
    call    write_num_at

    ; Score
    mov     ecx, 18
    mov     edx, 0
    lea     r8, [str_score_text]
    call    write_str_at

    mov     ecx, 25
    mov     edx, 0
    mov     r8d, [player_score]
    call    write_num_at

    ; Gold
    mov     ecx, 32
    mov     edx, 0
    lea     r8, [str_gold_text]
    call    write_str_at

    mov     ecx, 38
    mov     edx, 0
    mov     r8d, [player_gold]
    call    write_num_at

    ; Lives
    mov     ecx, 44
    mov     edx, 0
    lea     r8, [str_lives_text]
    call    write_str_at

    mov     ecx, 51
    mov     edx, 0
    mov     r8d, [player_lives]
    call    write_num_at

    call    draw_map
    call    draw_towers
    call    draw_enemies
    call    draw_cursor

    ; Bottom controls
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 2
    lea     r8, [str_controls]
    call    write_str_at

    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 1
    lea     r8, [str_tower_basic]
    call    write_str_at

    mov     ecx, 14
    mov     edx, SCREEN_HEIGHT - 1
    lea     r8, [str_tower_sniper]
    call    write_str_at

    mov     ecx, 29
    mov     edx, SCREEN_HEIGHT - 1
    lea     r8, [str_tower_splash]
    call    write_str_at

    ; State messages
    mov     eax, [game_state]
    cmp     eax, STATE_WAVE_COMPLETE
    je      @@wave_msg
    cmp     eax, STATE_LEVEL_COMPLETE
    je      @@level_msg
    jmp     @@done

@@wave_msg:
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 3
    lea     r8, [str_wave_complete]
    call    write_str_at
    jmp     @@done

@@level_msg:
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 3
    lea     r8, [str_level_complete]
    call    write_str_at

@@done:
    call    frame_render
    add     rsp, 40
    ret
draw_game_screen endp

; ============================================================================
; draw_map
; ============================================================================
draw_map proc
    push    rbx
    push    r12
    push    rsi
    sub     rsp, 40

    lea     rsi, [map_tiles]
    xor     ebx, ebx                   ; row counter — callee-saved

@@row:
    cmp     ebx, SCREEN_HEIGHT
    jge     @@done
    xor     r12d, r12d                 ; col counter — callee-saved

@@col:
    cmp     r12d, SCREEN_WIDTH
    jge     @@next_row

    mov     eax, ebx
    imul    eax, SCREEN_WIDTH
    add     eax, r12d
    movzx   edx, byte ptr [rsi + rax]

    cmp     edx, TILE_PATH
    je      @@path
    cmp     edx, TILE_SPAWN
    je      @@spawn
    cmp     edx, TILE_BASE
    je      @@base
    jmp     @@next_col

@@path:
    mov     ecx, r12d
    mov     edx, ebx
    lea     r8, [rnd_ch_path]
    call    write_str_at               ; rbx/r12/rsi preserved
    jmp     @@next_col

@@spawn:
    mov     ecx, r12d
    mov     edx, ebx
    lea     r8, [rnd_ch_spawn]
    call    write_str_at
    jmp     @@next_col

@@base:
    mov     ecx, r12d
    mov     edx, ebx
    lea     r8, [rnd_ch_base]
    call    write_str_at

@@next_col:
    inc     r12d
    jmp     @@col

@@next_row:
    inc     ebx
    jmp     @@row

@@done:
    add     rsp, 40
    pop     rsi
    pop     r12
    pop     rbx
    ret
draw_map endp

; ============================================================================
; draw_towers
; ============================================================================
draw_towers proc
    push    rbx
    push    rsi
    sub     rsp, 40

    lea     rsi, [towers]
    xor     ebx, ebx                   ; use rbx as loop counter (callee-saved)

@@loop:
    cmp     ebx, MAX_TOWERS
    jge     @@done

    mov     eax, ebx
    imul    eax, TOWER_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    cmp     dword ptr [rdi + TOWER_ACTIVE], 0
    je      @@next

    mov     edx, [rdi + TOWER_TYPE]
    lea     r8, [rnd_ch_basic]
    cmp     edx, TOWER_BASIC
    je      @@draw
    lea     r8, [rnd_ch_sniper]
    cmp     edx, TOWER_SNIPER
    je      @@draw
    lea     r8, [rnd_ch_splash]

@@draw:
    mov     ecx, [rdi + TOWER_X]
    mov     edx, [rdi + TOWER_Y]
    call    write_str_at               ; rbx/rsi preserved across this call

@@next:
    inc     ebx
    jmp     @@loop

@@done:
    add     rsp, 40
    pop     rsi
    pop     rbx
    ret
draw_towers endp

; ============================================================================
; draw_enemies
; ============================================================================
draw_enemies proc
    push    rbx
    push    rsi
    sub     rsp, 40

    lea     rsi, [enemies]
    xor     ebx, ebx                   ; use rbx as loop counter (callee-saved)

@@loop:
    cmp     ebx, MAX_ENEMIES
    jge     @@done

    mov     eax, ebx
    imul    eax, ENEMY_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    cmp     dword ptr [rdi + ENEMY_ACTIVE], 0
    je      @@next
    cmp     dword ptr [rdi + ENEMY_HEALTH], 0
    jle     @@next

    mov     ecx, [rdi + ENEMY_X]
    mov     edx, [rdi + ENEMY_Y]
    lea     r8, [rnd_ch_enemy]
    call    write_str_at               ; rbx/rsi preserved across this call

@@next:
    inc     ebx
    jmp     @@loop

@@done:
    add     rsp, 40
    pop     rsi
    pop     rbx
    ret
draw_enemies endp

; ============================================================================
; draw_cursor
; ============================================================================
draw_cursor proc
    sub     rsp, 40

    mov     eax, [game_state]
    cmp     eax, STATE_PLAYING
    je      @@draw
    cmp     eax, STATE_WAVE_COMPLETE
    je      @@draw
    jmp     @@done

@@draw:
    mov     eax, [frame_counter]
    and     eax, 8
    test    eax, eax
    jnz     @@done

    mov     ecx, [cursor_x]
    mov     edx, [cursor_y]
    lea     r8, [rnd_ch_cursor]
    call    write_str_at

@@done:
    add     rsp, 40
    ret
draw_cursor endp

; ============================================================================
; draw_end_screen
; ============================================================================
draw_end_screen proc
    sub     rsp, 40

    call    clear_screen

    mov     eax, [game_state]
    cmp     eax, STATE_WIN
    je      @@win

    mov     ecx, 9
    mov     edx, 10
    lea     r8, [str_game_over]
    call    write_str_at
    jmp     @@score

@@win:
    mov     ecx, 11
    mov     edx, 10
    lea     r8, [str_you_win]
    call    write_str_at

@@score:
    mov     ecx, 0
    mov     edx, 13
    lea     r8, [str_score_text]
    call    write_str_at

    mov     ecx, 7
    mov     edx, 13
    mov     r8d, [player_score]
    call    write_num_at

    call    frame_render
    add     rsp, 40
    ret
draw_end_screen endp

end
