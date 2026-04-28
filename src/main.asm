; ============================================================================
; main.asm — Entry point for Tower Defense Arena
; Tower Defense Arena
;
; Owner: Shared
;
; Purpose: Program entry point. Initializes all subsystems, runs game loop.
; ============================================================================

option casemap:none

include src/defs.inc

; ============================================================================
; External module procedures
; ============================================================================
extrn renderer_init:proc
extrn renderer_draw:proc
extrn input_init:proc
extrn input_poll:proc
extrn game_loop_init:proc
extrn game_loop_update:proc
extrn enemies_init:proc
extrn towers_init:proc
extrn collision_init:proc
extrn score_init:proc

; ============================================================================
; Code
; ============================================================================
.code

; ============================================================================
; mainCRTStartup — PE entry point
; Purpose: Initialize subsystems and run main game loop
; Inputs:  none
; Outputs: none (calls ExitProcess)
; ============================================================================
mainCRTStartup proc
    sub     rsp, 40                 ; shadow space + alignment

    ; --- Get console handles ---
    mov     ecx, STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     [hStdOut], rax

    mov     ecx, STD_INPUT_HANDLE
    call    GetStdHandle
    mov     [hStdIn], rax

    ; --- Set console title ---
    lea     rcx, [str_title]
    call    SetConsoleTitleA

    ; --- Initialize all subsystems ---
    call    renderer_init
    call    input_init
    call    score_init
    call    enemies_init
    call    towers_init
    call    collision_init
    call    game_loop_init

    ; --- Main loop ---
@@main_loop:
    ; Poll input
    call    input_poll

    ; Update game logic
    call    game_loop_update

    ; Render frame
    call    renderer_draw

    ; Frame delay
    mov     ecx, FRAME_DELAY_MS
    call    Sleep

    ; Check if game is still running
    mov     eax, [game_running]
    test    eax, eax
    jnz     @@main_loop

    ; --- Exit ---
    xor     ecx, ecx
    call    ExitProcess

mainCRTStartup endp

end
