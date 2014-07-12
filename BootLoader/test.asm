;부트로더, bootLoader.asm
org 0x7C00  

;비디오 메모리
mov ax, 0xB800
mov es, ax

;배경 지우기
mov ax, [Background]
mov bx, 0
mov cx, 80*25*2
CLS:
	mov [es:bx], ax
	add bx, 1
	loop CLS

;하드 섹터 읽기
READ:
	mov ax, 0x0800
	mov es, ax
	mov bx, 0

	mov ah, 2
	mov al, 1
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, 0x80

	int 0x13
	jc READ

jmp 0x8000

;변수 영역
Background db 0x00

times 510-($-$$) db 0x00
dw 0xaa55