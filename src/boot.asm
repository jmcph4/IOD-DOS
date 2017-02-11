; IOD.ASM
; Bootloader for IOD-DOS

    BITS 16
    jmp iod_boot_start    
    nop

    ; **************************************************************************
    ; VARIABLES
    ; **************************************************************************
    
    ; Boot media description
    IOD_BOOT_OEM_LABEL db "IODBOOT"
    IOD_BOOT_SEC_LEN dw 512
    IOD_BOOT_SEC_PER_CLUSTER db 1
    IOD_BOOT_RESERVED dw 1
    IOD_BOOT_NUM_FAT db 2
    IOD_BOOT_ROOT_NUM_ENTRIES dw 224
    IOD_BOOT_NUM_SECTORS dw 2880
    IOD_BOOT_MED_BYTE db 0F0h
    IOD_BOOT_SEC_PER_FAT dw 9
    IOD_BOOT_SEC_PER_TRACK dw 18
    IOD_BOOT_NUM_SIDES dw 2
    IOD_BOOT_NUM_SEC_HIDDEN dd 0
    IOD_BOOT_NUM_BIG_SEC dd 0
    IOD_BOOT_DRIVE_NUM dw 0
    IOD_BOOT_SIG db 41
    IOD_BOOT_VOLUME_NUM dd 00000000h
    IOD_BOOT_VOLUME_LABEL db "IOD-DOS    "
    IOD_BOOT_FILE_SYSTEM db "FAT12      "
    
    ; General
    DEV_NUM dw 0
    CLUSTER dw 0
    POINTER dw 0

    ; Strings
    IOD_BOOT_KERN_NAME db "KERNEL.BIN"
    IOD_BOOT_ERR_MEDIA db "[ERROR] BOOT MEDIA FAULT!", 0
    IOD_BOOT_ERR_KERNEL_MISSING db "[ERROR] KERNEL MISSING!", 0

iod_boot_start:
    mov ax, 07c0h
    add ax, 288
    mov ss, ax
    mov sp, 4096
    
    mov ax, 07c0h
    mov ds, ax

iod_boot_splash:
    ; change background colour
    mov bl, 08h
    call iod_boot_bg_colour

iod_boot_init_media:
    mov [DEV_NUM], dl
    mov ah, 8
    int 13h
    jc iod_boot_disk_fatal
    and cx, 3Fh
    mov [IOD_BOOT_SEC_PER_TRACK], cx
    movzx dx, dh
    add dx, 1
    mov [IOD_BOOT_NUM_SIDES], dx
    
iod_boot_media_ok:
    mov ax, 19 ; IOD_BOOT_NUM_SECTORS_READ
    call iod_boot_cyl_addr
    
    mov si, iod_kern_buf
    mov bx, ds
    mov es, bx
    mov bx, si

    mov ah, 2
    mov al, 19 ; IOD_BOOT_NUM_SECTORS_READ

    pusha

iod_boot_read_root:
    popa
    pusha
    
    int 13h
    
    jnc iod_boot_scan_root
    call iod_boot_reset_media
    jnc iod_boot_read_root
    call iod_boot_disk_fatal

iod_boot_scan_root:
    popa

    mov ax, ds
    mov es, ax
    mov di, iod_kern_buf

    mov cx, word [IOD_BOOT_ROOT_NUM_ENTRIES]
    mov ax, 0

iod_boot_next_root_entry:
    xchg cx, dx
    mov si, IOD_BOOT_KERN_NAME
    mov cx, 11
    rep cmpsb
    je iod_boot_found_file
    
    add ax, 32 ; increment entries found

    mov di, iod_kern_buf
    add di, ax

    xchg dx, cx
    loop iod_boot_next_root_entry
    
    ; print error message
    mov si, IOD_BOOT_ERR_KERNEL_MISSING
    call iod_boot_print_string

    jmp iod_boot_reboot

iod_boot_found_file:
    mov ax, word [es:di+0Fh]
    mov word [CLUSTER], ax
    
    mov ax, 1
    call iod_boot_cyl_addr

    mov di, iod_kern_buf
    mov bx, di

    mov ah, 2
    mov al, 9

    pusha

iod_boot_read_fat:
    popa
    pusha

    stc
    int 13h

    jnc iod_boot_read_fat_ok
    call iod_boot_reset_media
    jnc iod_boot_read_fat
    call iod_boot_disk_fatal

iod_boot_read_fat_ok:
    popa

    mov ax, 2000h
    mov es, ax
    mov bx, 0

    mov ah, 2
    mov al, 1

    push ax

iod_boot_load_sector:
    mov ax, word [CLUSTER]
    add ax, 31

    call iod_boot_cyl_addr

    mov ax, 2000h
    mov es, ax
    mov bx, word [POINTER]

    pop ax
    push ax

    stc
    int 13h

    jnc iod_boot_calc_next_cluster

    call iod_boot_reset_media
    jmp iod_boot_load_sector

iod_boot_calc_next_cluster:
    mov ax, [CLUSTER]
    mov dx, 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    mov si, iod_kern_buf
    add si, ax
    mov ax, word [ds:si]

    or dx, dx
    jz iod_boot_cluster_even

iod_boot_cluster_odd:
    shr ax, 4
    jmp short iod_boot_next_cluster_cont

iod_boot_cluster_even:
    and ax, 0FFFh

iod_boot_next_cluster_cont:
    mov word [CLUSTER], ax
    
    cmp ax, 0FF8h
    jae iod_boot_end

    add word [POINTER], IOD_BOOT_SEC_LEN
    jmp iod_boot_load_sector

iod_boot_end:
    pop ax
    mov dl, byte [DEV_NUM]

    jmp 2000h:000h ; jump to loaded kernel

; ******************************************************************************
; BOOTLOADER SUBROUTINES
; ******************************************************************************

; Display error message and reboot
iod_boot_disk_fatal:
    mov si, IOD_BOOT_ERR_MEDIA
    call iod_boot_print_string
    jmp iod_boot_reboot

; Reboot
iod_boot_reboot:
    mov ax, 0
    int 16h
    mov ax, 0
    int 19h

; Change background colour to colour code in BL
iod_boot_bg_colour:
    mov ah, 0Bh
    mov bh, 00h
    int 10h
    ret

; Print the string in SI
iod_boot_print_string:
    mov ah, 0Eh
    
    .loop:
        lodsb ; get char from string
        cmp al, 0 ; check for NUL byte
        je .done
        int 10h
        jmp .loop
    
    .done:
        ret

iod_boot_reset_media:
    push ax
    push dx
    mov ax, 0
    mov dl, byte [DEV_NUM]
    stc
    int 13h
    pop dx
    pop ax
    ret

iod_boot_cyl_addr:
    push bx
    push ax
    
    mov bx, ax

    mov dx, 0
    div word [IOD_BOOT_SEC_PER_TRACK]
    add dl, 01h
    mov cl, dl
    mov ax, bx

    mov dx, 0
    div word [IOD_BOOT_SEC_PER_TRACK]
    mov dx, 0
    div word [IOD_BOOT_NUM_SIDES]
    mov dh, dl
    mov ch, al
    
    pop ax
    pop bx
    mov dl, byte [DEV_NUM]
    
    ret

    times 510-($-$$) db 0 ; zero-padding
    dw 0xAA55 ; boot signature

iod_kern_buf:
    ; kernel-space buffer

