; ============================================================================
; renderer.asm — Console rendering with full color via WriteConsoleOutputA
; Uses CHAR_INFO buffer: 2 bytes per cell (char byte + attribute byte)
;
; Color attributes (foreground | background<<4):
;   0=Black 1=DkBlue 2=DkGreen 3=DkCyan 4=DkRed 5=DkMag 6=DkYellow 7=Gray
;   8=DkGray 9=Blue A=Green B=Cyan C=Red D=Magenta E=Yellow F=White
;
; Examples:
;   0x07 = gray text, black bg    (normal)
;   0x0A = green text, black bg   (path)
;   0x0C = red text, black bg     (enemy)
;   0x0E = yellow text, black bg  (basic tower)
;   0x0B = cyan text, black bg    (sniper tower)
;   0x0D = magenta text, black bg (splash tower)
;   0x2F = white text, green bg   (HUD)
;   0x4F = white text, red bg     (lives/danger)
;   0x1F = white text, blue bg    (title)
; ============================================================================

option casemap:none

include src/defs.inc

public renderer_init
public renderer_draw

; ============================================================================
; Color attribute constants
; ============================================================================
ATTR_DEFAULT    equ 07h   ; gray on black
ATTR_PATH       equ 02h   ; dark green on black  (path dots)
ATTR_SPAWN      equ 0Ah   ; bright green on black (spawn S)
ATTR_BASE       equ 0Ch   ; red on black          (base B)
ATTR_ENEMY      equ 0Ch   ; red on black          (enemy E)
ATTR_TOWER_T    equ 0Eh   ; yellow on black       (basic T)
ATTR_TOWER_R    equ 0Bh   ; cyan on black         (sniper R)
ATTR_TOWER_X    equ 0Dh   ; magenta on black      (splash X)
ATTR_HUD        equ 0Fh   ; bright white on black (HUD text)
ATTR_GOLD       equ 0Eh   ; yellow on black       (gold value)
ATTR_LIVES      equ 0Ch   ; red on black          (lives value)
ATTR_WAVE       equ 0Bh   ; cyan on black         (wave info)
ATTR_TITLE      equ 0Ah   ; green on black        (titles)
ATTR_LOCKED     equ 08h   ; dark gray on black    (locked)
ATTR_OPEN       equ 0Ah   ; green on black        (open)
ATTR_SELECTED   equ 0Eh   ; yellow on black       (selected slot)
ATTR_CTRL       equ 07h   ; gray on black         (controls)
ATTR_MSG        equ 0Eh   ; yellow on black       (messages)
ATTR_GAMEOVER   equ 0Ch   ; red on black          (game over)
ATTR_WIN        equ 0Ah   ; green on black        (you win)
ATTR_CURSOR     equ 0Fh   ; white on black        (cursor *)
ATTR_BG         equ 00h   ; black on black        (background)

; ============================================================================
; Local data
; ============================================================================
.data

rnd_lbracket    db '[', 0
rnd_rbracket    db ']', 0
rnd_open        db 'OPEN', 0
rnd_str_lvl     db 'Lvl:', 0
rnd_ch_path     db '.', 0
rnd_ch_spawn    db 'S', 0
rnd_ch_base     db 'B', 0
rnd_ch_basic    db 'T', 0
rnd_ch_sniper   db 'R', 0
rnd_ch_splash   db 'X', 0
rnd_ch_enemy    db 'E', 0
rnd_ch_cursor   db '*', 0
rnd_ch_space    db ' ', 0
hline_char      db '=', 0   ; set before calling draw_hline

rnd_tiny_rect   dw 0, 0, 1, 1
rnd_win_rect    dw 0, 0, SCREEN_WIDTH-1, SCREEN_HEIGHT-1

; WriteConsoleOutputA needs a SMALL_RECT for the region written
rnd_write_rect  dw 0, 0, SCREEN_WIDTH-1, SCREEN_HEIGHT-1

; Buffer size COORD for WriteConsoleOutputA (packed as dword: low=X, high=Y)
rnd_buf_size    dd (SCREEN_HEIGHT SHL 16) OR SCREEN_WIDTH

; Buffer coord top-left (0,0) packed as dword
rnd_buf_coord   dd 0

.code

; ============================================================================
; renderer_init
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
; renderer_draw
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
; buf_put_char — write CHAR_INFO into screen_buf at (x,y)
; CHAR_INFO = WORD char (ascii in low byte, 0 in high) + WORD attributes
; So 4 bytes total per cell: [char_lo][char_hi=0][attr_lo][attr_hi=0]
; Inputs: ecx=x, edx=y, r8b=char, r9b=attribute
; ============================================================================
buf_put_char proc
    ; offset = (y * SCREEN_WIDTH + x) * 4
    mov     eax, edx
    imul    eax, SCREEN_WIDTH
    add     eax, ecx
    imul    eax, 4                     ; *4 for CHAR_INFO size

    cmp     eax, SCREEN_WIDTH * SCREEN_HEIGHT * 4
    jge     @@done

    lea     rdi, [screen_buf]
    add     rdi, rax
    movzx   r10d, r8b
    mov     word ptr [rdi],   r10w     ; char as WORD (hi byte = 0)
    movzx   r10d, r9b
    mov     word ptr [rdi+2], r10w     ; attribute as WORD (hi byte = 0)

@@done:
    ret
buf_put_char endp

; ============================================================================
; write_str_at_col — write string into buffer with color
; Inputs: ecx=x, edx=y, r8=str_ptr, r9b=attribute
; ============================================================================
write_str_at_col proc
    push    rbx
    push    r12
    push    r13
    sub     rsp, 40

    mov     ebx, ecx                   ; x
    mov     r12d, edx                  ; y
    mov     r13, r8                    ; str ptr
    movzx   r10d, r9b                  ; attribute

@@loop:
    movzx   eax, byte ptr [r13]
    test    eax, eax
    jz      @@done

    ; bounds check x
    cmp     ebx, SCREEN_WIDTH
    jge     @@done

    mov     ecx, ebx
    mov     edx, r12d
    mov     r8b, al
    mov     r9b, r10b
    call    buf_put_char

    inc     ebx
    inc     r13
    jmp     @@loop

@@done:
    add     rsp, 40
    pop     r13
    pop     r12
    pop     rbx
    ret
write_str_at_col endp

; ============================================================================
; write_str_at — write string with default color (for compatibility)
; Inputs: ecx=x, edx=y, r8=str_ptr
; ============================================================================
write_str_at proc
    sub     rsp, 40
    mov     r9b, ATTR_DEFAULT
    call    write_str_at_col
    add     rsp, 40
    ret
write_str_at endp

; ============================================================================
; write_num_at_col — write number into buffer with color
; Inputs: ecx=x, edx=y, r8d=number, r9b=attribute
; ============================================================================
write_num_at_col proc
    push    rbx
    push    r12
    push    r13
    sub     rsp, 48

    mov     dword ptr [rsp+32], ecx
    mov     dword ptr [rsp+36], edx
    movzx   r13d, r9b                  ; save attribute
    mov     eax, r8d

    ; convert number to string in temp buffer
    lea     rbx, [rsp+44]              ; end of small buffer
    mov     byte ptr [rbx], 0

    test    eax, eax
    jnz     @@conv
    dec     rbx
    mov     byte ptr [rbx], '0'
    jmp     @@write

@@conv:
    jns     @@pos
    neg     eax
@@pos:
    mov     r12d, 10
@@div:
    test    eax, eax
    jz      @@write
    xor     edx, edx
    div     r12d
    add     dl, '0'
    dec     rbx
    mov     [rbx], dl
    jmp     @@div

@@write:
    mov     ecx, dword ptr [rsp+32]
    mov     edx, dword ptr [rsp+36]
    mov     r8, rbx
    mov     r9b, r13b
    call    write_str_at_col

    add     rsp, 48
    pop     r13
    pop     r12
    pop     rbx
    ret
write_num_at_col endp

; ============================================================================
; write_num_at — write number with default color
; ============================================================================
write_num_at proc
    sub     rsp, 40
    mov     r9b, ATTR_DEFAULT
    call    write_num_at_col
    add     rsp, 40
    ret
write_num_at endp


; ============================================================================
; clear_screen — fill entire CHAR_INFO buffer with space + default attribute
; Each cell = 4 bytes: WORD char (' '=0x0020) + WORD attr
; ============================================================================
clear_screen proc
    push    rbx
    sub     rsp, 40

    lea     rbx, [screen_buf]
    mov     ecx, SCREEN_WIDTH * SCREEN_HEIGHT
@@loop:
    test    ecx, ecx
    jz      @@done
    mov     word ptr [rbx],   20h      ; space character as WORD
    mov     word ptr [rbx+2], ATTR_DEFAULT ; attribute as WORD
    add     rbx, 4
    dec     ecx
    jmp     @@loop
@@done:
    add     rsp, 40
    pop     rbx
    ret
clear_screen endp

; ============================================================================
; frame_render — blast screen_buf to console via WriteConsoleOutputA
; WriteConsoleOutputA(hStdOut, buf, bufSize, bufCoord, &writeRegion)
; ============================================================================
frame_render proc
    sub     rsp, 40

    mov     rcx, [hStdOut]
    lea     rdx, [screen_buf]
    mov     r8d,  [rnd_buf_size]       ; COORD{W,H} as dword
    mov     r9d,  [rnd_buf_coord]      ; COORD{0,0}
    lea     rax, [rnd_write_rect]
    mov     [rsp+32], rax
    call    WriteConsoleOutputA

    add     rsp, 40
    ret
frame_render endp

; ============================================================================
; draw_hline — draw horizontal bar
; Inputs: ecx=x, edx=y, r8d=count, r9b=attr
; Uses hline_char (module var) for the character to draw
; ============================================================================
draw_hline proc
    push    rbx
    push    r12
    push    r13
    sub     rsp, 40

    mov     ebx, ecx
    mov     r12d, edx
    mov     r13d, r8d
    movzx   r10d, r9b
    movzx   r11d, byte ptr [hline_char]

@@loop:
    test    r13d, r13d
    jz      @@done
    mov     ecx, ebx
    mov     edx, r12d
    mov     r8b,  r11b
    mov     r9b,  r10b
    call    buf_put_char
    inc     ebx
    dec     r13d
    jmp     @@loop
@@done:
    add     rsp, 40
    pop     r13
    pop     r12
    pop     rbx
    ret
draw_hline endp

; ============================================================================
; draw_menu_screen
; ============================================================================
draw_menu_screen proc
    sub     rsp, 40

    call    clear_screen

    ; Background — fill whole screen with dark blue tint
    ; (just use clear_screen default for now, add border)

    ; Top border line
    mov     ecx, 0
    mov     edx, 0
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_TITLE
    mov     byte ptr [hline_char], '='
    call    draw_hline

    ; Bottom border
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 1
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_TITLE
    mov     byte ptr [hline_char], '='
    call    draw_hline

    ; Title
    mov     ecx, 16
    mov     edx, 9
    lea     r8, [str_menu_title]
    mov     r9b, ATTR_TITLE
    call    write_str_at_col

    ; Description
    mov     ecx, 10
    mov     edx, 12
    lea     r8, [str_menu_quit]
    mov     r9b, ATTR_HUD
    call    write_str_at_col

    ; Play prompt
    mov     ecx, 14
    mov     edx, 15
    lea     r8, [str_menu_play]
    mov     r9b, ATTR_SELECTED
    call    write_str_at_col

    call    frame_render
    add     rsp, 40
    ret
draw_menu_screen endp

; ============================================================================
; draw_level_select
; ============================================================================
draw_level_select proc
    push    rbx
    push    r12
    sub     rsp, 40

    call    clear_screen

    ; Border
    mov     ecx, 0
    mov     edx, 0
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_TITLE
    mov     byte ptr [hline_char], '='
    call    draw_hline

    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 1
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_TITLE
    mov     byte ptr [hline_char], '='
    call    draw_hline

    ; Title
    mov     ecx, 20
    mov     edx, 8
    lea     r8, [str_level_select_title]
    mov     r9b, ATTR_TITLE
    call    write_str_at_col

    ; Hint
    mov     ecx, 11
    mov     edx, 19
    lea     r8, [str_level_select_hint]
    mov     r9b, ATTR_CTRL
    call    write_str_at_col

    ; Draw 5 level slots
    xor     ebx, ebx

@@slot_loop:
    cmp     ebx, MAX_LEVELS
    jge     @@slots_done

    ; x = 5 + i*11
    mov     eax, ebx
    imul    eax, 11
    add     eax, 5
    mov     r12d, eax                  ; slot x in r12

    ; Is this the cursor?
    cmp     ebx, [level_cursor]
    jne     @@not_selected

    ; Draw brackets in yellow
    mov     ecx, r12d
    dec     ecx
    mov     edx, 12
    lea     r8, [rnd_lbracket]
    mov     r9b, ATTR_SELECTED
    call    write_str_at_col

    mov     ecx, r12d
    add     ecx, 7
    mov     edx, 12
    lea     r8, [rnd_rbracket]
    mov     r9b, ATTR_SELECTED
    call    write_str_at_col

@@not_selected:
    ; Is level unlocked?
    mov     eax, ebx
    mov     ecx, [levels_unlocked]
    dec     ecx
    cmp     eax, ecx
    jle     @@draw_open

    ; LOCKED — gray
    mov     ecx, r12d
    mov     edx, 12
    lea     r8, [str_level_label]
    mov     r9b, ATTR_LOCKED
    call    write_str_at_col

    mov     ecx, r12d
    add     ecx, 6
    mov     edx, 12
    mov     r8d, ebx
    inc     r8d
    mov     r9b, ATTR_LOCKED
    call    write_num_at_col

    mov     ecx, r12d
    mov     edx, 14
    lea     r8, [str_locked]
    mov     r9b, ATTR_LOCKED
    call    write_str_at_col
    jmp     @@next_slot

@@draw_open:
    ; Determine label color: selected=yellow, unlocked=green
    mov     r10b, ATTR_OPEN
    cmp     ebx, [level_cursor]
    jne     @@label_color_done
    mov     r10b, ATTR_SELECTED
@@label_color_done:

    mov     ecx, r12d
    mov     edx, 12
    lea     r8, [str_level_label]
    mov     r9b, r10b
    call    write_str_at_col

    mov     ecx, r12d
    add     ecx, 6
    mov     edx, 12
    mov     r8d, ebx
    inc     r8d
    mov     r9b, r10b
    call    write_num_at_col

    mov     ecx, r12d
    mov     edx, 14
    lea     r8, [rnd_open]
    mov     r9b, ATTR_OPEN
    call    write_str_at_col

@@next_slot:
    inc     ebx
    jmp     @@slot_loop

@@slots_done:
    call    frame_render
    add     rsp, 40
    pop     r12
    pop     rbx
    ret
draw_level_select endp

; ============================================================================
; draw_game_screen
; ============================================================================
draw_game_screen proc
    sub     rsp, 40

    call    clear_screen

    ; HUD top bar background (row 0)
    mov     ecx, 0
    mov     edx, 0
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_HUD
    mov     byte ptr [hline_char], ' '
    call    draw_hline

    ; Wave X/3 — cyan
    mov     ecx, 0
    mov     edx, 0
    lea     r8, [str_wave_text]
    mov     r9b, ATTR_WAVE
    call    write_str_at_col

    mov     ecx, 6
    mov     edx, 0
    mov     r8d, [wave_in_level]
    mov     r9b, ATTR_WAVE
    call    write_num_at_col

    mov     ecx, 7
    mov     edx, 0
    lea     r8, [str_wave_of]
    mov     r9b, ATTR_WAVE
    call    write_str_at_col

    mov     ecx, 8
    mov     edx, 0
    mov     r8d, WAVES_PER_LEVEL
    mov     r9b, ATTR_WAVE
    call    write_num_at_col

    ; Lvl — cyan
    mov     ecx, 11
    mov     edx, 0
    lea     r8, [rnd_str_lvl]
    mov     r9b, ATTR_WAVE
    call    write_str_at_col

    mov     ecx, 15
    mov     edx, 0
    mov     r8d, [current_level]
    mov     r9b, ATTR_WAVE
    call    write_num_at_col

    ; Score — white
    mov     ecx, 18
    mov     edx, 0
    lea     r8, [str_score_text]
    mov     r9b, ATTR_HUD
    call    write_str_at_col

    mov     ecx, 25
    mov     edx, 0
    mov     r8d, [player_score]
    mov     r9b, ATTR_HUD
    call    write_num_at_col

    ; Gold — yellow
    mov     ecx, 32
    mov     edx, 0
    lea     r8, [str_gold_text]
    mov     r9b, ATTR_GOLD
    call    write_str_at_col

    mov     ecx, 38
    mov     edx, 0
    mov     r8d, [player_gold]
    mov     r9b, ATTR_GOLD
    call    write_num_at_col

    ; Lives — red
    mov     ecx, 44
    mov     edx, 0
    lea     r8, [str_lives_text]
    mov     r9b, ATTR_LIVES
    call    write_str_at_col

    mov     ecx, 51
    mov     edx, 0
    mov     r8d, [player_lives]
    mov     r9b, ATTR_LIVES
    call    write_num_at_col

    call    draw_map
    call    draw_towers
    call    draw_enemies
    call    draw_cursor

    ; Bottom bar background (row SCREEN_HEIGHT-2 and -1)
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 2
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_CTRL
    mov     byte ptr [hline_char], ' '
    call    draw_hline

    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 1
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_CTRL
    mov     byte ptr [hline_char], ' '
    call    draw_hline

    ; Controls — gray
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 2
    lea     r8, [str_controls]
    mov     r9b, ATTR_CTRL
    call    write_str_at_col

    ; Tower options — colored by type
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 1
    lea     r8, [str_tower_basic]
    mov     r9b, ATTR_TOWER_T
    call    write_str_at_col

    mov     ecx, 14
    mov     edx, SCREEN_HEIGHT - 1
    lea     r8, [str_tower_sniper]
    mov     r9b, ATTR_TOWER_R
    call    write_str_at_col

    mov     ecx, 29
    mov     edx, SCREEN_HEIGHT - 1
    lea     r8, [str_tower_splash]
    mov     r9b, ATTR_TOWER_X
    call    write_str_at_col

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
    mov     r9b, ATTR_MSG
    call    write_str_at_col
    jmp     @@done

@@level_msg:
    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 3
    lea     r8, [str_level_complete]
    mov     r9b, ATTR_WIN
    call    write_str_at_col

@@done:
    call    frame_render
    add     rsp, 40
    ret
draw_game_screen endp

; ============================================================================
; draw_map — colored path tiles
; ============================================================================
draw_map proc
    push    rbx
    push    r12
    push    rsi
    sub     rsp, 40

    lea     rsi, [map_tiles]
    xor     ebx, ebx

@@row:
    cmp     ebx, SCREEN_HEIGHT
    jge     @@done
    xor     r12d, r12d

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
    mov     r9b, ATTR_PATH
    call    write_str_at_col
    jmp     @@next_col

@@spawn:
    mov     ecx, r12d
    mov     edx, ebx
    lea     r8, [rnd_ch_spawn]
    mov     r9b, ATTR_SPAWN
    call    write_str_at_col
    jmp     @@next_col

@@base:
    mov     ecx, r12d
    mov     edx, ebx
    lea     r8, [rnd_ch_base]
    mov     r9b, ATTR_BASE
    call    write_str_at_col

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
; draw_towers — each tower type has its own color
; ============================================================================
draw_towers proc
    push    rbx
    push    rsi
    sub     rsp, 40

    lea     rsi, [towers]
    xor     ebx, ebx

@@loop:
    cmp     ebx, MAX_TOWERS
    jge     @@done

    mov     eax, ebx
    imul    eax, TOWER_STRUCT_SIZE
    lea     rdi, [rsi + rax]

    cmp     dword ptr [rdi + TOWER_ACTIVE], 0
    je      @@next

    mov     edx, [rdi + TOWER_TYPE]

    cmp     edx, TOWER_BASIC
    jne     @@try_sniper
    lea     r8, [rnd_ch_basic]
    mov     r9b, ATTR_TOWER_T
    jmp     @@draw

@@try_sniper:
    cmp     edx, TOWER_SNIPER
    jne     @@splash
    lea     r8, [rnd_ch_sniper]
    mov     r9b, ATTR_TOWER_R
    jmp     @@draw

@@splash:
    lea     r8, [rnd_ch_splash]
    mov     r9b, ATTR_TOWER_X

@@draw:
    mov     ecx, [rdi + TOWER_X]
    mov     edx, [rdi + TOWER_Y]
    call    write_str_at_col

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
; draw_enemies — bright red
; ============================================================================
draw_enemies proc
    push    rbx
    push    rsi
    sub     rsp, 40

    lea     rsi, [enemies]
    xor     ebx, ebx

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
    mov     r9b, ATTR_ENEMY
    call    write_str_at_col

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
; draw_cursor — blinking white *
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
    mov     r9b, ATTR_CURSOR
    call    write_str_at_col

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

    ; Border
    mov     ecx, 0
    mov     edx, 0
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_TITLE
    mov     byte ptr [hline_char], '='
    call    draw_hline

    mov     ecx, 0
    mov     edx, SCREEN_HEIGHT - 1
    mov     r8d, SCREEN_WIDTH
    mov     r9b, ATTR_TITLE
    mov     byte ptr [hline_char], '='
    call    draw_hline

    mov     eax, [game_state]
    cmp     eax, STATE_WIN
    je      @@win

    ; Game Over — red
    mov     ecx, 9
    mov     edx, 10
    lea     r8, [str_game_over]
    mov     r9b, ATTR_GAMEOVER
    call    write_str_at_col
    jmp     @@score

@@win:
    ; You Win — green
    mov     ecx, 11
    mov     edx, 10
    lea     r8, [str_you_win]
    mov     r9b, ATTR_WIN
    call    write_str_at_col

@@score:
    ; Score — yellow
    mov     ecx, 0
    mov     edx, 13
    lea     r8, [str_score_text]
    mov     r9b, ATTR_GOLD
    call    write_str_at_col

    mov     ecx, 7
    mov     edx, 13
    mov     r8d, [player_score]
    mov     r9b, ATTR_GOLD
    call    write_num_at_col

    call    frame_render
    add     rsp, 40
    ret
draw_end_screen endp

end
