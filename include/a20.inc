;******************************************
;   A20 Gate Enable 
;   EnableA20_SystemControll
;******************************************
EnableA20_SystemControll:
    push    eax
    mov     al, 2
    out     0x92, al
    pop     eax
    ret
 
;******************************************
;   A20 Gate Enable 
;   EnableA20_BiosCall
;******************************************
EnableA20_BiosCall:
    push    eax
    mov     ax, 0x2401
    int     0x15
    pop     eax
    ret
 
;******************************************
;   A20 Gate Enable 
;   EnableA20_Keyboard
;******************************************
EnableA20_Keyboard:     
        cli
        pusha
            call    WaitInput
 
            mov     al, 0xAD    ; 0xAD = 키보드 Disable
            out     0x64, al
            call    WaitInput
 
            mov     al, 0xD0    ; 0xD0 = 컨트롤러의 데이터 읽음
            out     0x64, al
            call    WaitOutput
 
            in      al, 0x60    ; 버퍼에 전송된 컨트롤러값 읽음
            push    eax
            call    WaitInput
 
            mov     al, 0xD1    ; 0xD1 = 출력버퍼의 내용을 컨트롤러가 읽음
            out     0x64, al
            call    WaitInput
 
            pop     eax
            or      al, 2       ; 2진수(10) = A20 Gate Enable
            out     0x60, al    ; 출력 버퍼에 전송
            call    WaitInput
 
            mov     al, 0xAE    ; 키보드 Enable
            out     0x64, al
            call    WaitInput
        popa
        sti
        ret
 
    ;******************************************
    ;   WaitInput, WaitOutput (Kerboard Contoller)
    ;******************************************
    WaitInput:
        in      al, 0x64
        test    al, 2
        jnz     WaitInput
        ret
    WaitOutput:
        in      al, 0x64
        test    al, 1
        jz      WaitOutput
        ret
;******************************************
;   A20Test
;   output - ax : 1=A20 Enabled, 0=A20 Disabled 
;******************************************
A20Test:
    pusha
        mov     ax, 0
        mov     ds, ax
        mov     si, 0x500               ; 0x00500
 
        mov     ax, 0xFFFF
        mov     es, ax
        mov     di, 0x510               ; 0x100500
 
        mov     word [ds:si], 0x0000    ; 0x500 초기화 
        mov     word [es:di], 0x0000    ; 0x100500 초기화
 
        mov     ax, 0x1234              ; 0x100500에 0x1234 기록
        mov     word [es:di], ax
         
        mov     ax, word [ds:si]        ; 0x500에 0x1234 기록됐나?
        cmp     ax, 0x1234              ; 기록됐으면 A20 에러
        je      .A20Disabled
 
    .A20Enabled:
    popa
    mov     ax, 1
    ret
 
    .A20Disabled:
    popa
    mov     ax, 0
    ret