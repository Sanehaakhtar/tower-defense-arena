; ============================================================================
; input.asm — Keyboard input via ReadConsoleInput
; Tower Defense Arena
;
; Owner: Saneha (517085)
; ============================================================================

option casemap:none

include src/defs.inc

; ============================================================================
; External module procedures
; ============================================================================
extrn towers_place:proc

; ============================================================================
; Public procedures
; ============================================================================
public input_init
public input_poll
public input_get_key

; ============================================================================
; Local data
; ============================================================================
.data
last_key        dd 0
key_ready       dd 0

.code

; ============================================================================
; input_init — Initialize input system
; Purpose: Set console input mode for raw key events
; Inputs:  none
; Outputs: none
; ============================================================================
input_init proc
    sub     rsp, 40

    ; Set input mode to get key events
    mov     rcx, [hStdIn]
    mov     edx, ENABLE_PROCESSED_INPUT or ENABLE_WINDOW_INPUT
    call    SetConsoleMode

    mov     dword ptr [last_key], 0
    mov     dword ptr [key_ready], 0

    add     rsp, 40
    ret
input_init endp

; ============================================================================
; input_poll — Poll for keyboard input and process game actions
; Purpose: Read console input events, handle movement, tower placement
; Inputs:  none
; Outputs: none (modifies cursor_x, cursor_y, and may call towers_place)
; ============================================================================
input_poll proc
    sub     rsp, 56

    mov     dword ptr [key_ready], 0
    mov     dword ptr [last_key], 0

    ; Check if there are pending events
    mov     rcx, [hStdIn]
    lea     rdx, [input_count]
    call    GetNumberOfConsoleInputEvents

    mov     eax, [input_count]
    test    eax, eax
    jz      @@done

    ; Read one input record
    mov     rcx, [hStdIn]
    lea     rdx, [input_record]
    mov     r8d, 1
    lea     r9, [input_count]
    call    ReadConsoleInputA

    ; Check if it's a key event
    lea     rsi, [input_record]
    movzx   eax, word ptr [rsi + IR_EVENT_TYPE]
    cmp     eax, KEY_EVENT
    jne     @@done

    ; Check if key down
    mov     eax, [rsi + IR_KEY_DOWN]
    test    eax, eax
    jz      @@done

    ; Get virtual key code
    movzx   eax, word ptr [rsi + IR_VKEY]
    mov     [last_key], eax
    mov     dword ptr [key_ready], 1

    ; Game state must be PLAYING or WAVE_COMPLETE for movement
    mov     ecx, [game_state]
    cmp     ecx, STATE_PLAYING
    je      @@handle_game_keys
    cmp     ecx, STATE_WAVE_COMPLETE
    je      @@handle_game_keys
    jmp     @@done

@@handle_game_keys:
    ; Arrow keys — move cursor
    cmp     eax, VK_LEFT
    je      @@move_left
    cmp     eax, VK_RIGHT
    je      @@move_right
    cmp     eax, VK_UP
    je      @@move_up
    cmp     eax, VK_DOWN
    je      @@move_down

    ; Tower type selection
    cmp     eax, VK_1
    je      @@select_basic
    cmp     eax, VK_2
    je      @@select_sniper
    cmp     eax, VK_3
    je      @@select_splash

    ; Place tower
    cmp     eax, VK_SPACE
    je      @@place_tower

    jmp     @@done

@@move_left:
    cmp     dword ptr [cursor_x], 1
    jle     @@done
    dec     dword ptr [cursor_x]
    jmp     @@done

@@move_right:
    cmp     dword ptr [cursor_x], SCREEN_WIDTH - 2
    jge     @@done
    inc     dword ptr [cursor_x]
    jmp     @@done

@@move_up:
    cmp     dword ptr [cursor_y], 1
    jle     @@done
    dec     dword ptr [cursor_y]
    jmp     @@done

@@move_down:
    cmp     dword ptr [cursor_y], SCREEN_HEIGHT - 4
    jge     @@done
    inc     dword ptr [cursor_y]
    jmp     @@done

@@select_basic:
    mov     dword ptr [selected_tower_type], TOWER_BASIC
    jmp     @@done

@@select_sniper:
    mov     dword ptr [selected_tower_type], TOWER_SNIPER
    jmp     @@done

@@select_splash:
    mov     dword ptr [selected_tower_type], TOWER_SPLASH
    jmp     @@done

@@place_tower:
    call    towers_place
    jmp     @@done

@@done:
    add     rsp, 56
    ret
input_poll endp

; ============================================================================
; input_get_key — Return the last pressed key
; Purpose: Return last key code to caller (used by game_loop state handlers)
; Inputs:  none
; Outputs: eax = virtual key code (0 if no key pressed)
; ============================================================================
input_get_key proc
    mov     eax, [key_ready]
    test    eax, eax
    jz      @@no_key

    mov     eax, [last_key]
    mov     dword ptr [key_ready], 0   ; consume the key
    ret

@@no_key:
    xor     eax, eax
    ret
input_get_key endp

end
