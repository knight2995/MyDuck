;******************************************
;   func.inc
;******************************************
;******************************************
;   PrintString
;   input - ds:si : ���ڿ� �ּ�
;******************************************
PrintString:
    pusha
    mov     ax, 0xB800
    mov     es, ax
    mov     ah, 0x07            ; ���ڼӼ�
    mov     di, 0               ; ���� ������
    .loop:
        mov     al, [ds:si]     ; 1���� �ε�
        cmp     al, 0           ; NULL���� ��
        je      .endFunc        ; NULL�̸� ����
         
        mov     [es:di], ax     ; ���� �޸𸮿� ���
        add     si, 1           ; ���� ����
        add     di, 2           ; ���� ���� �޸�
        jmp     .loop
.endFunc:
    popa
    ret
;******************************************
;   ReadSectors
;   input - ax : ���� ���� ��
;           ebx: �ε�� �޸�(Seg:Off)
;           ecx : LBA ��ȣ
;******************************************
ReadSectors:
    pusha
    .retry:
        push    ax
 
        ; DAP �ۼ�
        mov     dl, 0x10
        mov     [0x500], dl         ; ����ü ũ��
        mov     dl, 0
        mov     [0x501], dl         ; �̻�� ����
        mov     [0x502], ax         ; ���� ����1 ��
        mov     [0x504], ebx        ; �ε� �� �ּ�
        mov     [0x508], ecx        ; ���� LBA
 
        ; ���ɾ� ����
        mov     ax, 0x500           ; DAP �ּ�
        mov     si, ax
        mov     ax, 0
        mov     ds, ax
 
        mov     ah, 0x42            ; ���ɾ� ��ȣ
        mov     dl, 0x80            ; �ϵ� ��ȣ
        int     0x13
 
        pop     ax
        jc      .retry
    popa
    ret