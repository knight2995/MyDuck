;��Ʈ�δ�, bootsect.asm
org     0x7C00
jmp     Entry
%include ".\include\func.inc"
 
 
Entry:
    ; ��� �����
    mov     ax, 0xB800
    mov     es, ax
    mov     ax, 0
    mov     di, ax
    mov     cx, 80*20*2
    rep stosd

   ; Ŀ�� �ε�
    mov     ax, 2
    mov     ebx, 0x8000
    mov     ecx, 1
    call    ReadSectors
 
    jmp     0x8000
      
;*********************************************
;   ���� ����
;*********************************************
message#1   db  "Now Booting...\n                                                                                                                                                                        ", 0

times 510-($-$$) db 0x00
dw 0xaa55