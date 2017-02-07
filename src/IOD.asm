; IOD.ASM
; Bootloader for IOD-DOS

    BITS 16
    
start:
    mov ax, 07c0h
    add ax, 288
    mov ss, ax
    mov sp, 4096
    
    mov ax, 07c0h
    mov ds, ax
    
    ; change background colour
    mov bl, 08h
    call bg_colour
    
    ; print splash message
    mov si, splash_msg_line1
    call print_string
    
    jmp $
    
    splash_msg_line1 db 'WELCOME TO IOD-DOS!', 0Ah
    splash_msg_line2 db 'SYSTEM OK.', 0
    
; Change background colour to colour code in BL
bg_colour:
    mov ah, 0Bh
    mov bh, 00h
    int 10h
    ret

; Print the string in SI
print_string:
    mov ah, 0Eh
    
    .repeat:
        lodsb ; get char from string
        cmp al, 0 ; check for NUL byte
        je .done
        int 10h
        jmp .repeat
    
    .done:
        ret
    
    times 510-($-$$) db 0 ; padding
    dw 0xAA55 ; boot signature
