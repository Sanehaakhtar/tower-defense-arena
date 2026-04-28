; ============================================================================
; data.asm — Global structs, constants, and shared variables
; Tower Defense Arena
; ============================================================================

option casemap:none

STARTING_LIVES          equ 3
STARTING_GOLD           equ 35
STATE_MENU              equ 0
STATE_LEVEL_SELECT      equ 5
TOWER_BASIC             equ 0
SCREEN_WIDTH            equ 60
SCREEN_HEIGHT           equ 25
MAX_ENEMIES             equ 20
MAX_TOWERS              equ 10
ENEMY_STRUCT_SIZE       equ 48
TOWER_STRUCT_SIZE       equ 48
MAX_LEVELS              equ 5

.data

public hStdOut
public hStdIn
hStdOut         dq 0
hStdIn          dq 0

; --- Game State ---
public game_state
public current_wave
public wave_in_level
public current_level
public levels_unlocked
public level_cursor
public wave_timer
public spawn_timer
public spawn_count
public enemies_alive
public frame_counter
public player_lives
public player_gold
public game_running

game_state      dd STATE_MENU
current_wave    dd 0
wave_in_level   dd 0          ; 1..WAVES_PER_LEVEL within current level
current_level   dd 1          ; 1..MAX_LEVELS
levels_unlocked dd 1          ; how many levels are unlocked (start with 1)
level_cursor    dd 0          ; 0-based index of highlighted level on select screen
wave_timer      dd 0
spawn_timer     dd 0
spawn_count     dd 0
enemies_alive   dd 0
frame_counter   dd 0
player_lives    dd STARTING_LIVES
player_gold     dd STARTING_GOLD
game_running    dd 1

; --- Cursor ---
public cursor_x
public cursor_y
public selected_tower_type
cursor_x        dd 5
cursor_y        dd 5
selected_tower_type dd TOWER_BASIC

; --- Enemy Array ---
public enemies
enemies         db MAX_ENEMIES * ENEMY_STRUCT_SIZE dup(0)

; --- Tower Array ---
public towers
towers          db MAX_TOWERS * TOWER_STRUCT_SIZE dup(0)

; ============================================================================
; 5 level paths  (x,y pairs as dwords)
; Level 1: simple S-curve across full width
; Level 2: Z-shape (top-left to bottom-right via middle)
; Level 3: spiral inward from top
; Level 4: U-shape (sides first, then base)
; Level 5: diagonal-ish zigzag
; ============================================================================

; --- Level 1 path (S-curve, 88 points) ---
public path_l1
public path_l1_len
path_l1  dd  1, 3,  4, 3,  7, 3, 10, 3, 13, 3, 16, 3, 19, 3, 22, 3
         dd 25, 3, 28, 3, 31, 3, 34, 3, 37, 3, 40, 3, 43, 3, 46, 3
         dd 49, 3, 52, 3, 55, 3
         dd 55, 4, 55, 5, 55, 6, 55, 7, 55, 8
         dd 52, 8, 49, 8, 46, 8, 43, 8, 40, 8, 37, 8, 34, 8, 31, 8
         dd 28, 8, 25, 8, 22, 8, 19, 8, 16, 8, 13, 8, 10, 8,  7, 8
         dd  4, 8,  1, 8
         dd  1, 9,  1,10,  1,11,  1,12,  1,13
         dd  4,13,  7,13, 10,13, 13,13, 16,13, 19,13, 22,13, 25,13
         dd 28,13, 31,13, 34,13, 37,13, 40,13, 43,13, 46,13, 49,13
         dd 52,13, 55,13
         dd 55,14, 55,15, 55,16, 55,17, 55,18
         dd 52,18, 49,18, 46,18, 43,18, 40,18, 37,18, 34,18, 31,18
         dd 28,18, 25,18, 22,18, 19,18, 16,18, 13,18, 10,18,  7,18
         dd  4,18,  1,18
path_l1_len dd 88

; --- Level 2 path (Z-shape, 58 points) ---
; Top row L->R, diagonal step down, bottom row L->R
public path_l2
public path_l2_len
path_l2  dd  1, 2,  4, 2,  7, 2, 10, 2, 13, 2, 16, 2, 19, 2, 22, 2
         dd 25, 2, 28, 2, 31, 2, 34, 2, 37, 2, 40, 2, 43, 2, 46, 2
         dd 49, 2, 52, 2, 55, 2
         dd 52, 5, 49, 8, 46,11, 43,14, 40,17, 37,20
         dd 34,20, 31,20, 28,20, 25,20, 22,20, 19,20, 16,20, 13,20
         dd 10,20,  7,20,  4,20,  1,20
         dd  1,18,  1,16,  1,14,  1,12,  1,10,  1, 8,  1, 6,  1, 4
         dd  4, 4,  7, 4, 10, 4, 13, 4, 16, 4, 19, 4, 22, 4, 25, 4
         dd 28, 4, 31, 4, 34, 4, 37, 4, 40, 4, 43, 4, 46, 4, 49, 4
         dd 52, 4, 55, 4
         dd 55, 7, 55,10, 55,13, 55,16, 55,20
path_l2_len dd 58

; --- Level 3 path (U-shape — down left side, across bottom, up right side) ---
public path_l3
public path_l3_len
path_l3  dd  1, 2,  1, 4,  1, 6,  1, 8,  1,10,  1,12,  1,14,  1,16
         dd  1,18,  1,20
         dd  4,20,  7,20, 10,20, 13,20, 16,20, 19,20, 22,20, 25,20
         dd 28,20, 31,20, 34,20, 37,20, 40,20, 43,20, 46,20, 49,20
         dd 52,20, 55,20
         dd 55,18, 55,16, 55,14, 55,12, 55,10, 55, 8, 55, 6, 55, 4
         dd 55, 2
         dd 52, 2, 49, 2, 46, 2, 43, 2, 40, 2, 37, 2, 34, 2, 31, 2
         dd 28, 2, 25, 2, 22, 2, 19, 2, 16, 2, 13, 2, 10, 2,  7, 2
         dd  4, 2
         dd  4, 5,  4, 8,  4,11,  4,14,  4,17
         dd  7,17, 10,17, 13,17, 16,17, 19,17, 22,17, 25,17, 28,17
         dd 31,17, 34,17, 37,17, 40,17, 43,17, 46,17, 49,17, 52,17
         dd 52,14, 52,11, 52, 8, 52, 5
         dd 49, 5, 46, 5, 43, 5, 40, 5, 37, 5, 34, 5, 31, 5, 28, 5
         dd 25, 5, 22, 5, 19, 5, 16, 5, 13, 5, 10, 5,  7, 5
path_l3_len dd 78

; --- Level 4 path (cross/plus shape — top down center, then arms) ---
public path_l4
public path_l4_len
path_l4  dd 28, 1, 28, 3, 28, 5, 28, 7, 28, 9, 28,11
         dd 25,11, 22,11, 19,11, 16,11, 13,11, 10,11,  7,11,  4,11,  1,11
         dd  1,13,  1,15,  1,17,  1,19,  1,21
         dd  4,21,  7,21, 10,21, 13,21, 16,21, 19,21, 22,21, 25,21
         dd 28,21, 31,21, 34,21, 37,21, 40,21, 43,21, 46,21, 49,21
         dd 52,21, 55,21
         dd 55,19, 55,17, 55,15, 55,13, 55,11
         dd 52,11, 49,11, 46,11, 43,11, 40,11, 37,11, 34,11, 31,11
         dd 31, 9, 31, 7, 31, 5, 31, 3, 31, 1
         dd 34, 1, 37, 1, 40, 1, 43, 1, 46, 1, 49, 1, 52, 1, 55, 1
         dd 55, 4, 55, 7, 55,10
         dd 52,10, 49,10, 46,10, 43,10, 40,10
         dd 40,13, 40,16, 40,19
         dd 37,19, 34,19, 31,19, 28,19, 25,19, 22,19, 19,19
         dd 19,16, 19,13, 19,10
         dd 16,10, 13,10, 10,10,  7,10,  4,10,  1,10
         dd  1, 7,  1, 4,  1, 1
         dd  4, 1,  7, 1, 10, 1, 13, 1, 16, 1, 19, 1, 22, 1, 25, 1
path_l4_len dd 82

; --- Level 5 path (tight zigzag filling whole screen) ---
public path_l5
public path_l5_len
path_l5  dd  1, 2,  4, 2,  7, 2, 10, 2, 13, 2, 16, 2, 19, 2, 22, 2
         dd 25, 2, 28, 2, 31, 2, 34, 2, 37, 2, 40, 2, 43, 2, 46, 2
         dd 49, 2, 52, 2, 55, 2
         dd 55, 4, 55, 6
         dd 52, 6, 49, 6, 46, 6, 43, 6, 40, 6, 37, 6, 34, 6, 31, 6
         dd 28, 6, 25, 6, 22, 6, 19, 6, 16, 6, 13, 6, 10, 6,  7, 6
         dd  4, 6,  1, 6
         dd  1, 8,  1,10
         dd  4,10,  7,10, 10,10, 13,10, 16,10, 19,10, 22,10, 25,10
         dd 28,10, 31,10, 34,10, 37,10, 40,10, 43,10, 46,10, 49,10
         dd 52,10, 55,10
         dd 55,12, 55,14
         dd 52,14, 49,14, 46,14, 43,14, 40,14, 37,14, 34,14, 31,14
         dd 28,14, 25,14, 22,14, 19,14, 16,14, 13,14, 10,14,  7,14
         dd  4,14,  1,14
         dd  1,16,  1,18
         dd  4,18,  7,18, 10,18, 13,18, 16,18, 19,18, 22,18, 25,18
         dd 28,18, 31,18, 34,18, 37,18, 40,18, 43,18, 46,18, 49,18
         dd 52,18, 55,18
         dd 55,20, 55,21
path_l5_len dd 96

; --- active path pointer and length (set by game_loop when level starts) ---
public path_data
public path_length
path_data       dq 0          ; pointer to current level's path (qword — address)
path_length     dd 0

; --- level path pointer table (qwords, filled at runtime in game_loop_init) ---
public level_path_ptrs
public level_path_lens
level_path_ptrs dq 0, 0, 0, 0, 0     ; 5 qword pointers
level_path_lens dd 0, 0, 0, 0, 0     ; 5 dword lengths

; --- Map Buffer ---
public map_tiles
map_tiles       db SCREEN_WIDTH * SCREEN_HEIGHT dup(0)

public screen_buf
screen_buf      db SCREEN_WIDTH * SCREEN_HEIGHT dup(' ')

; --- Score ---
public player_score
player_score    dd 0

; --- Temp variables ---
public temp_dword
public temp_coord
public temp_written
temp_dword      dd 0
temp_coord      dd 0
temp_written    dd 0

; --- Strings ---
public str_title
public str_menu_title
public str_menu_play
public str_menu_quit
public str_game_over
public str_you_win
public str_wave_text
public str_score_text
public str_gold_text
public str_lives_text
public str_controls
public str_tower_basic
public str_tower_sniper
public str_tower_splash
public str_wave_complete
public str_next_wave
public str_level_complete
public str_locked
public str_level_label
public str_level_select_title
public str_level_select_hint
public str_wave_of

str_title            db "Tower Defense Arena", 0
str_menu_title       db "=== TOWER DEFENSE ARENA ===", 0
str_menu_play        db "[ENTER] Select Level    [Q] Quit", 0
str_menu_quit        db "Defend your base from waves of enemies!", 0
str_game_over        db "=== GAME OVER ===  ENTER:Restart  Q:Quit", 0
str_you_win          db "=== YOU WIN! ===  ENTER:Menu  Q:Quit", 0
str_wave_text        db "Wave: ", 0
str_score_text       db "Score: ", 0
str_gold_text        db "Gold: ", 0
str_lives_text       db "Lives: ", 0
str_controls         db "Arrows:Move  1/2/3:Tower  SPACE:Place  Q:Quit", 0
str_tower_basic      db "[1]Basic $20 ", 0
str_tower_sniper     db "[2]Sniper $40 ", 0
str_tower_splash     db "[3]Splash $30 ", 0
str_wave_complete    db "Wave Complete!  +25 Gold  ENTER:Next Wave", 0
str_next_wave        db "Next wave starting...", 0
str_level_complete   db "LEVEL COMPLETE!  ENTER:Next Level  Q:Menu", 0
str_locked           db "LOCKED", 0
str_level_label      db "LEVEL ", 0
str_level_select_title db "=== SELECT LEVEL ===", 0
str_level_select_hint  db "LEFT/RIGHT:Choose  ENTER:Play  Q:Back", 0
str_wave_of          db "/", 0

; --- Number conversion buffer ---
public num_buf
num_buf         db 16 dup(0)

; --- Input record buffer ---
public input_record
input_record    db 32 dup(0)
public input_count
input_count     dd 0

; --- CURSOR_INFO ---
public cursor_info
cursor_info     dd 1
                dd 0

public wave_enemy_counts
public wave_health_mult
wave_enemy_counts dd 4, 6, 8, 10, 14
wave_health_mult  dd 100, 120, 150, 200, 250

end
