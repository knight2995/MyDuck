;Ŀ��, kernel.asm
[bits 16]
org     0x8000
jmp     Entry16
 
%include ".\include\func.inc"
%include ".\include\a20.inc"
;*********************************************
;   16��Ʈ ��Ʈ�� ( ��Ʈ�δ� -> �̰� ���� )
;*********************************************
Entry16:
    ; Ŀ�� �ε�
    mov     ax, 5           ; Ŀ���� ũ��
    mov     ebx, 0x10000000 ; Ŀ���� �ö� ��ġ, Seg:Off�̹Ƿ� 0x10000�� �ȴ�.
    mov     ecx, 3          ; Ŀ���� ���� LBA
    call    ReadSectors

; A20 Gate Enable
    .A20_Enable:
        ; �ý��� ��Ʈ�� ��Ʈ �õ�
        call    EnableA20_SystemControll
        call    A20Test
        cmp     ax, 1
        je      .A20_Complete
 
        ; ���̿��� �� �õ�
        call    EnableA20_BiosCall
        call    A20Test
        cmp     ax, 1
        je      .A20_Complete
 
        ; Ű���� ��Ʈ�ѷ� �õ�
        call    EnableA20_Keyboard
        call    A20Test
        cmp     ax, 1
        je      .A20_Complete
         
        ; �����޽��� ���
        mov     ax, 0
        mov     ds, ax
        mov     si, messageA20Off
        call    PrintString
        jmp     $
    .A20_Complete:
 
    ; GDT ���
    xor     ax, ax
    lgdt    [gdtr]  
    cli
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax
 
    jmp     $+2
    nop
    nop
 
    jmp     0x08:Entry32
 
;*********************************************
;   32��Ʈ ��Ʈ��
;*********************************************
[bits   32]
Entry32:
    ; ���׸�Ʈ �������� �ʱ�ȭ
    mov     bx, dataDescriptor
    mov     ds, bx
    mov     es, bx
    mov     fs, bx
    mov     gs, bx
    mov     ss, bx
    xor     esp, esp
    mov     esp, 0x9FFFF
 
 
    ; EXE �δ�
    mov     esi, 0x10000            ; EXEĿ���� �ε�� �޸�
    xor     edx, edx
    xor     eax, eax
 
    ; Dos Headers
    ; Image Nt Headers�� ��ġ
    add     edx, 0x3C               ; Dos Stub�� ũ��
    mov     eax, dword [esi + edx]
    mov     [imageNTHeaders], eax
 
    ; NT Headers . File Header
    ; ������ ����
    mov     ebx, [imageNTHeaders]
    mov     edx, 0x06               ; ������ ���� =
    add     edx, ebx                ; NTHeaders + 0x06
    mov     ax, word [esi + edx]
    mov     [numberOfSections], word ax
 
    ; �ɼų� ����� ũ��
    mov     edx, 0x14               ; �ɼų� ����� ũ�� = 
    add     edx, ebx                ; NTHeaders + 0x14 
    mov     ax, word [esi + edx]
    mov     [sizeOfOptionalHeader], word ax
 
    ; NT Headers . Optional Header
    ; ��Ʈ�� �ּ�
    mov     edx, 0x28               ; ��Ʈ�� �ּ� =
    add     edx, ebx                ; NTHeaders + 0x28
    mov     eax, dword [esi + edx]
    mov     [entryPoint], dword eax
 
    ; Base Address ( �ε�� �ּ� )
    mov     edx, 0x34               ; Base Address = 
    add     edx, ebx                ; NTHeaders + 0x34
    mov     eax, dword [esi + edx]
    mov     [baseAddress], dword eax
 
    ; Image Section Header�� ��ġ
    mov     edx, 0x18               ; Section Header ��ġ = 
    add     dx, word [sizeOfOptionalHeader]
    add     edx, ebx                ; NT��� + ������� + �ɼų� ���
    mov     eax, edx
    mov     [imageSectionHeader], dword eax
 
 
    ; ������ �޸𸮿�!!
    xor     ecx, ecx
    mov     cx, [numberOfSections]
    sectionRelocation:
        mov     esi, 0x10000        ; exe Ŀ���� �ε�� ��ġ
        mov     ebx, [imageSectionHeader]
 
        ; RVA ����
        mov     edx, 0x0C           ; RVA = 
        add     edx, ebx            ; ������� + 0x0C
        mov     eax, dword [esi + edx]
        mov     [RVA], dword eax
 
        ; ������ ũ������( size of raw data )
        mov     edx, 0x10           ; ���� ũ�� = 
        add     edx, ebx            ; ������� + 0x10
        mov     eax, dword [esi + edx]
        mov     [sizeOfRawData], dword eax
 
        ; ������ ���� ��ġ ( pointer to raw data )
        mov     edx, 0x14           ; ������ ���� ��ġ = 
        add     edx, ebx            ; ������� + 0x14
        mov     eax, dword [esi + edx]
        mov     [pointerToRawData], dword eax
 
        ; ������ ���� ��ġ ( ������ ���� )
        add     esi, [pointerToRawData]
 
        ; ����� �޸� ��ġ ( base add + rva )
        mov     edi, [baseAddress]
        add     edi, [RVA]
 
        ; ����
        push    ecx                 ; ���� �� ���� �� ���
        cld
        mov     ecx, [sizeOfRawData]; ������ ũ�� (������ũ��)
        repz    movsb               ; �������
        pop     ecx                 ; ���� �� ����
 
        ; ���� ����
        mov     eax, [imageSectionHeader]
        add     eax, 40
        mov     [imageSectionHeader], eax
        loop    sectionRelocation
 
 
    ; Ŀ�� ����
    mov     eax, [baseAddress]
    add     eax, [entryPoint]
    call    eax
 
;*********************************************
;   ���� ����
;*********************************************
; �δ�
imageNTHeaders          dd  0
numberOfSections        dw  0
sizeOfOptionalHeader    dw  0
entryPoint              dd  0
baseAddress             dd  0
imageSectionHeader      dd  0
RVA                     dd  0
sizeOfRawData           dd  0
pointerToRawData        dd  0
messageA20Off   db  "A20 Off", 0
 
;*********************************************
;   GDT ����
;*********************************************
gdtr:
    dw gdt_end - gdt - 1    ; GDT�� limit
    dd gdt                  ; GDT�� ���̽� ��巹��
gdt:
; NULL ��ũ����
nullDescriptor  equ 0x00
    dw 0
    dw 0
    db 0
    db 0
    db 0
    db 0
; �ڵ� ��ũ����
codeDescriptor  equ 0x08
    dw 0xFFFF               ; limit:0xFFFF
    dw 0x0000               ; base 0~15 : 0
    db 0x00                 ; base 16~23: 0
    db 0x9A                 ; P:1, DPL:0, Code, non-conforming, readable
    db 0xCF                 ; G:1, D:1, limit:0xF
    db 0x00                 ; base 24~32: 0
; ������ ��ũ����
dataDescriptor  equ 0x10
    dw 0xFFFF               ; limit 0xFFFF
    dw 0x0000               ; base 0~15 : 0
    db 0x00                 ; base 16~23: 0
    db 0x92                 ; P:1, DPL:0, data, readable, writable
    db 0xCF                 ; G:1, D:1, limit:0xF
    db 0x00                 ; base 24~32: 0
; ���� ��ũ����
videoDescriptor equ 0x18
    dw 0xFFFF               ; limit 0xFFFF
    dw 0x8000               ; base 0~15 : 0x8000
    db 0x0B                 ; base 16~23: 0x0B
    db 0x92                 ; P:1, DPL:0, data, readable, writable
    db 0xCF                 ; G:1, D:1, limit:0xF
    db 0x00                 ; base 24~32: 0
gdt_end:
   
times 1024-($-$$) db 0x00