[BITS 16]
[org 0x7C00]

; init BootLoader, boot.asm
times 510-($-$$) db 0x00
dw 0xaa55