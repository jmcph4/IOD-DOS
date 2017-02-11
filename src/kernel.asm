    BITS 16

    ; Version macros
    %DEFINE IOD_VERSION '0.1'
    %DEFINE IOD_MAJOR_VERSION 0
    %DEFINE IOD_MINOR_VERSION 1

    %DEFINE IOD_API_VERSION '1'

    IOD_KERN_DISK_BUF equ 24576

; ******************************************************************************
; KERNEL CALL TABLE
; ******************************************************************************
iod_kern_call_table:
    jmp iod_kern_main                ; 0000h
    jmp iod_kern_string_print        ; 0003h
    jmp iod_kern_string_length       ; 0006h

; ******************************************************************************
; KERNEL INITIALISATION
; ******************************************************************************

IOD_KERN_SPLASH_L1 db 'WELCOME TO IOD-DOS!', 0

iod_kern_main:
    ; print splash screen
    mov si, IOD_KERN_SPLASH_L1
    call iod_kern_string_print

    ; set stack up
    cli
    mov ax, 0
    mov ss, ax
    mov sp, 0FFFFh
    sti

    cld

    ; align segments (we don't need them)
    mov ax, 2000h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ax, 1003h
    mov bx, 0
    int 10h

; ******************************************************************************
; KERNEL SUBSYSTEMS
; ******************************************************************************
    %INCLUDE "src/string.asm"    ; strings

