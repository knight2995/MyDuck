org 0x8000

mov ax, 0xB800
mov es, ax

mov ah, 0x09
mov al, 'H'
mov [es:0000], ax
mov al, 'I'
mov [es:0002], ax

jmp $

times 512-($-$$) db 0x00