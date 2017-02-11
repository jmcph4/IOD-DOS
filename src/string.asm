; ******************************************************************************
; IOD-DOS KERNEL
; STRING SUBSYSTEM
; ******************************************************************************

IOD_KERN_STRING_SENTINEL db 0

; ------------------------------------------------------------------------------
; iod_kern_string_print
; IN:  si - string to print (NULL terminated)
; OUT: None
; 
; Prints the string to the console.
; ------------------------------------------------------------------------------
iod_kern_string_print:
    mov ah, 0Eh
    
    .loop:
        lodsb ; get char from string
        cmp al, 0 ; check for NUL byte
        je .done
        int 10h
        jmp .loop
    
    .done:
        ret    

; ------------------------------------------------------------------------------
; iod_kern_string_length
; IN:  si - string to get length of
; OUT: ax - length of the string
; 
; Returns the length of the string (excluding sentinel).
; ------------------------------------------------------------------------------
iod_kern_string_length:
    pusha ; save registers
    mov si, bx ; save string location to bx
    mov cx, 0 ; initialise cx for our counter

    .more:
        cmp byte [bx], IOD_KERN_STRING_SENTINEL
        je .done
        inc bx
        inc cx
        jmp .more

    .done:
        mov word [.tmp_res], cx ; save counter
        popa

        mov ax, [.tmp_res]
        ret

        .tmp_res dw 0

