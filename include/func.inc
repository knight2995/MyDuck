;******************************************
;   func.inc
;******************************************
;******************************************
;   PrintString
;   input - ds:si : 문자열 주소
;******************************************
PrintString:
    pusha
    mov     ax, 0xB800
    mov     es, ax
    mov     ah, 0x07            ; 문자속성
    mov     di, 0               ; 비디오 오프셋
    .loop:
        mov     al, [ds:si]     ; 1문자 로드
        cmp     al, 0           ; NULL인지 비교
        je      .endFunc        ; NULL이면 종료
         
        mov     [es:di], ax     ; 비디오 메모리에 출력
        add     si, 1           ; 다음 문자
        add     di, 2           ; 다음 비디오 메모리
        jmp     .loop
.endFunc:
    popa
    ret
;******************************************
;   ReadSectors
;   input - ax : 읽을 섹터 수
;           ebx: 로드될 메모리(Seg:Off)
;           ecx : LBA 번호
;******************************************
ReadSectors:
    pusha
    .retry:
        push    ax
 
        ; DAP 작성
        mov     dl, 0x10
        mov     [0x500], dl         ; 구조체 크기
        mov     dl, 0
        mov     [0x501], dl         ; 미사용 영역
        mov     [0x502], ax         ; 읽을 섹터1 수
        mov     [0x504], ebx        ; 로드 될 주소
        mov     [0x508], ecx        ; 시작 LBA
 
        ; 명령어 실행
        mov     ax, 0x500           ; DAP 주소
        mov     si, ax
        mov     ax, 0
        mov     ds, ax
 
        mov     ah, 0x42            ; 명령어 번호
        mov     dl, 0x80            ; 하드 번호
        int     0x13
 
        pop     ax
        jc      .retry
    popa
    ret
