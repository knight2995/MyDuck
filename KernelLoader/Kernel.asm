;커널, kernel.asm
[bits 16]
org     0x8000
jmp     Entry16
 
%include ".\include\func.inc"
%include ".\include\a20.inc"
;*********************************************
;   16비트 엔트리 ( 부트로더 -> 이곳 점프 )
;*********************************************
Entry16:
    ; 커널 로드
    mov     ax, 5           ; 커널의 크기
    mov     ebx, 0x10000000 ; 커널이 올라갈 위치, Seg:Off이므로 0x10000이 된다.
    mov     ecx, 3          ; 커널의 시작 LBA
    call    ReadSectors

; A20 Gate Enable
    .A20_Enable:
        ; 시스템 컨트롤 포트 시도
        call    EnableA20_SystemControll
        call    A20Test
        cmp     ax, 1
        je      .A20_Complete
 
        ; 바이오스 콜 시도
        call    EnableA20_BiosCall
        call    A20Test
        cmp     ax, 1
        je      .A20_Complete
 
        ; 키보드 컨트롤러 시도
        call    EnableA20_Keyboard
        call    A20Test
        cmp     ax, 1
        je      .A20_Complete
         
        ; 에러메시지 출력
        mov     ax, 0
        mov     ds, ax
        mov     si, messageA20Off
        call    PrintString
        jmp     $
    .A20_Complete:
 
    ; GDT 등록
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
;   32비트 엔트리
;*********************************************
[bits   32]
Entry32:
    ; 세그먼트 레지스터 초기화
    mov     bx, dataDescriptor
    mov     ds, bx
    mov     es, bx
    mov     fs, bx
    mov     gs, bx
    mov     ss, bx
    xor     esp, esp
    mov     esp, 0x9FFFF
 
 
    ; EXE 로더
    mov     esi, 0x10000            ; EXE커널이 로드된 메모리
    xor     edx, edx
    xor     eax, eax
 
    ; Dos Headers
    ; Image Nt Headers의 위치
    add     edx, 0x3C               ; Dos Stub의 크기
    mov     eax, dword [esi + edx]
    mov     [imageNTHeaders], eax
 
    ; NT Headers . File Header
    ; 섹션의 갯수
    mov     ebx, [imageNTHeaders]
    mov     edx, 0x06               ; 섹션의 갯수 =
    add     edx, ebx                ; NTHeaders + 0x06
    mov     ax, word [esi + edx]
    mov     [numberOfSections], word ax
 
    ; 옵셔널 헤더의 크기
    mov     edx, 0x14               ; 옵셔널 헤더의 크기 = 
    add     edx, ebx                ; NTHeaders + 0x14 
    mov     ax, word [esi + edx]
    mov     [sizeOfOptionalHeader], word ax
 
    ; NT Headers . Optional Header
    ; 엔트리 주소
    mov     edx, 0x28               ; 엔트리 주소 =
    add     edx, ebx                ; NTHeaders + 0x28
    mov     eax, dword [esi + edx]
    mov     [entryPoint], dword eax
 
    ; Base Address ( 로드될 주소 )
    mov     edx, 0x34               ; Base Address = 
    add     edx, ebx                ; NTHeaders + 0x34
    mov     eax, dword [esi + edx]
    mov     [baseAddress], dword eax
 
    ; Image Section Header의 위치
    mov     edx, 0x18               ; Section Header 위치 = 
    add     dx, word [sizeOfOptionalHeader]
    add     edx, ebx                ; NT헤더 + 파일헤더 + 옵셔널 헤더
    mov     eax, edx
    mov     [imageSectionHeader], dword eax
 
 
    ; 섹션을 메모리에!!
    xor     ecx, ecx
    mov     cx, [numberOfSections]
    sectionRelocation:
        mov     esi, 0x10000        ; exe 커널이 로드된 위치
        mov     ebx, [imageSectionHeader]
 
        ; RVA 저장
        mov     edx, 0x0C           ; RVA = 
        add     edx, ebx            ; 섹션헤더 + 0x0C
        mov     eax, dword [esi + edx]
        mov     [RVA], dword eax
 
        ; 섹션의 크기저장( size of raw data )
        mov     edx, 0x10           ; 섹션 크기 = 
        add     edx, ebx            ; 섹션헤더 + 0x10
        mov     eax, dword [esi + edx]
        mov     [sizeOfRawData], dword eax
 
        ; 섹션의 파일 위치 ( pointer to raw data )
        mov     edx, 0x14           ; 섹션의 파일 위치 = 
        add     edx, ebx            ; 섹션헤더 + 0x14
        mov     eax, dword [esi + edx]
        mov     [pointerToRawData], dword eax
 
        ; 복사할 원본 위치 ( 섹션의 파일 )
        add     esi, [pointerToRawData]
 
        ; 복사될 메모리 위치 ( base add + rva )
        mov     edi, [baseAddress]
        add     edi, [RVA]
 
        ; 복사
        push    ecx                 ; 복사 전 섹션 수 백업
        cld
        mov     ecx, [sizeOfRawData]; 복사할 크기 (섹션의크기)
        repz    movsb               ; 복사시작
        pop     ecx                 ; 섹션 수 복원
 
        ; 다음 섹션
        mov     eax, [imageSectionHeader]
        add     eax, 40
        mov     [imageSectionHeader], eax
        loop    sectionRelocation
 
 
    ; 커널 점프
    mov     eax, [baseAddress]
    add     eax, [entryPoint]
    call    eax
 
;*********************************************
;   변수 영역
;*********************************************
; 로더
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
;   GDT 영역
;*********************************************
gdtr:
    dw gdt_end - gdt - 1    ; GDT의 limit
    dd gdt                  ; GDT의 베이스 어드레스
gdt:
; NULL 디스크립터
nullDescriptor  equ 0x00
    dw 0
    dw 0
    db 0
    db 0
    db 0
    db 0
; 코드 디스크립터
codeDescriptor  equ 0x08
    dw 0xFFFF               ; limit:0xFFFF
    dw 0x0000               ; base 0~15 : 0
    db 0x00                 ; base 16~23: 0
    db 0x9A                 ; P:1, DPL:0, Code, non-conforming, readable
    db 0xCF                 ; G:1, D:1, limit:0xF
    db 0x00                 ; base 24~32: 0
; 데이터 디스크립터
dataDescriptor  equ 0x10
    dw 0xFFFF               ; limit 0xFFFF
    dw 0x0000               ; base 0~15 : 0
    db 0x00                 ; base 16~23: 0
    db 0x92                 ; P:1, DPL:0, data, readable, writable
    db 0xCF                 ; G:1, D:1, limit:0xF
    db 0x00                 ; base 24~32: 0
; 비디오 디스크립터
videoDescriptor equ 0x18
    dw 0xFFFF               ; limit 0xFFFF
    dw 0x8000               ; base 0~15 : 0x8000
    db 0x0B                 ; base 16~23: 0x0B
    db 0x92                 ; P:1, DPL:0, data, readable, writable
    db 0xCF                 ; G:1, D:1, limit:0xF
    db 0x00                 ; base 24~32: 0
gdt_end:
   
times 1024-($-$$) db 0x00