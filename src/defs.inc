; ============================================================================
; defs.inc — Constants, struct offsets, equates, and extern declarations
; Tower Defense Arena
; ============================================================================

ifndef DEFS_INC
DEFS_INC equ 1

option casemap:none

; ============================================================================
; Windows API Constants
; ============================================================================
STD_INPUT_HANDLE        equ -10
STD_OUTPUT_HANDLE       equ -11
ENABLE_PROCESSED_INPUT  equ 01h
ENABLE_WINDOW_INPUT     equ 08h
KEY_EVENT               equ 01h
INVALID_HANDLE_VALUE    equ -1

; ============================================================================
; Game Constants
; ============================================================================
SCREEN_WIDTH            equ 60
SCREEN_HEIGHT           equ 25
MAX_ENEMIES             equ 20
MAX_TOWERS              equ 10
MAX_PATH_LEN            equ 100
ENEMY_STRUCT_SIZE       equ 48
TOWER_STRUCT_SIZE       equ 48

; Level / wave constants
MAX_LEVELS              equ 5
WAVES_PER_LEVEL         equ 3
; Enemies in wave = ENEMY_BASE + (wave_in_level * ENEMY_WAVE_INC) + (level * ENEMY_LEVEL_INC)
ENEMY_BASE              equ 4
ENEMY_WAVE_INC          equ 3
ENEMY_LEVEL_INC         equ 3

; Game states
STATE_MENU              equ 0
STATE_PLAYING           equ 1
STATE_WAVE_COMPLETE     equ 2
STATE_GAME_OVER         equ 3
STATE_WIN               equ 4
STATE_LEVEL_SELECT      equ 5
STATE_LEVEL_COMPLETE    equ 6

; Tile types
TILE_EMPTY              equ 0
TILE_PATH               equ 1
TILE_TOWER              equ 2
TILE_BASE               equ 3
TILE_SPAWN              equ 4

; Tower types
TOWER_BASIC             equ 0
TOWER_SNIPER            equ 1
TOWER_SPLASH            equ 2

; Timing
FRAME_DELAY_MS          equ 50
ENEMY_MOVE_TICKS        equ 6
TOWER_COOLDOWN_BASIC    equ 5
TOWER_COOLDOWN_SNIPER   equ 10
TOWER_COOLDOWN_SPLASH   equ 8

; Tower stats
TOWER_RANGE_BASIC       equ 3
TOWER_RANGE_SNIPER      equ 6
TOWER_RANGE_SPLASH      equ 4
TOWER_DMG_BASIC         equ 10
TOWER_DMG_SNIPER        equ 25
TOWER_DMG_SPLASH        equ 15

; Economy
STARTING_GOLD           equ 50
TOWER_COST_BASIC        equ 20
TOWER_COST_SNIPER       equ 40
TOWER_COST_SPLASH       equ 30
STARTING_LIVES          equ 3
KILL_REWARD             equ 5

; Spawn interval
SPAWN_INTERVAL          equ 30

; ============================================================================
; Struct offsets — Enemy (48 bytes)
; ============================================================================
ENEMY_X                 equ 0
ENEMY_Y                 equ 4
ENEMY_HEALTH            equ 8
ENEMY_MAX_HEALTH        equ 12
ENEMY_SPEED             equ 16
ENEMY_PATH_IDX          equ 20
ENEMY_ACTIVE            equ 24
ENEMY_MOVE_TIMER        equ 28
ENEMY_TYPE              equ 32

; ============================================================================
; Struct offsets — Tower (48 bytes)
; ============================================================================
TOWER_X                 equ 0
TOWER_Y                 equ 4
TOWER_RANGE             equ 8
TOWER_DAMAGE            equ 12
TOWER_COOLDOWN          equ 16
TOWER_COOL_TIMER        equ 20
TOWER_TYPE              equ 24
TOWER_ACTIVE            equ 28

; ============================================================================
; INPUT_RECORD struct offsets
; ============================================================================
IR_EVENT_TYPE           equ 0
IR_KEY_DOWN             equ 4
IR_VKEY                 equ 10
IR_UCHAR                equ 14

; Virtual key codes
VK_LEFT                 equ 25h
VK_UP                   equ 26h
VK_RIGHT                equ 27h
VK_DOWN                 equ 28h
VK_RETURN               equ 0Dh
VK_ESCAPE               equ 1Bh
VK_SPACE                equ 20h
VK_1                    equ 31h
VK_2                    equ 32h
VK_3                    equ 33h
VK_Q                    equ 51h

; ============================================================================
; Extern Windows API (kernel32.dll)
; ============================================================================
extrn GetStdHandle:proc
extrn WriteConsoleOutputCharacterA:proc
extrn SetConsoleCursorPosition:proc
extrn ReadConsoleInputA:proc
extrn GetNumberOfConsoleInputEvents:proc
extrn SetConsoleCursorInfo:proc
extrn SetConsoleTitleA:proc
extrn Sleep:proc
extrn ExitProcess:proc
extrn WriteConsoleA:proc
extrn SetConsoleMode:proc
extrn GetConsoleMode:proc
extrn FillConsoleOutputCharacterA:proc
extrn SetConsoleTextAttribute:proc
extrn FillConsoleOutputAttribute:proc
extrn SetConsoleScreenBufferSize:proc
extrn SetConsoleWindowInfo:proc

; ============================================================================
; Extern shared data (defined in data.asm)
; ============================================================================
extrn hStdOut:qword
extrn hStdIn:qword

extrn game_state:dword
extrn current_wave:dword
extrn wave_in_level:dword
extrn current_level:dword
extrn levels_unlocked:dword
extrn level_cursor:dword
extrn wave_timer:dword
extrn spawn_timer:dword
extrn spawn_count:dword
extrn enemies_alive:dword
extrn frame_counter:dword
extrn player_lives:dword
extrn player_gold:dword
extrn game_running:dword

extrn cursor_x:dword
extrn cursor_y:dword
extrn selected_tower_type:dword

extrn enemies:byte
extrn towers:byte

extrn path_data:qword
extrn path_length:dword

; 5 level paths stored flat — each level's path pointer and length
extrn level_path_ptrs:qword
extrn level_path_lens:dword

extrn map_tiles:byte
extrn screen_buf:byte

extrn player_score:dword

extrn temp_dword:dword
extrn temp_coord:dword
extrn temp_written:dword

extrn str_title:byte
extrn str_menu_title:byte
extrn str_menu_play:byte
extrn str_menu_quit:byte
extrn str_game_over:byte
extrn str_you_win:byte
extrn str_wave_text:byte
extrn str_score_text:byte
extrn str_gold_text:byte
extrn str_lives_text:byte
extrn str_controls:byte
extrn str_tower_basic:byte
extrn str_tower_sniper:byte
extrn str_tower_splash:byte
extrn str_wave_complete:byte
extrn str_next_wave:byte
extrn str_level_complete:byte
extrn str_locked:byte
extrn str_level_label:byte
extrn str_level_select_title:byte
extrn str_level_select_hint:byte
extrn str_wave_of:byte

extrn num_buf:byte
extrn input_record:byte
extrn input_count:dword
extrn cursor_info:dword

; Per-level paths (declared in data.asm)
extrn path_l1:dword
extrn path_l2:dword
extrn path_l3:dword
extrn path_l4:dword
extrn path_l5:dword
extrn path_l1_len:dword
extrn path_l2_len:dword
extrn path_l3_len:dword
extrn path_l4_len:dword
extrn path_l5_len:dword

endif ; DEFS_INC
