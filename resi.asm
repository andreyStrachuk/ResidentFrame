.186
.model tiny
.code
org 100h

.setVidReg		macro

	            mov cx, nextVidPage
				push VIDEOMEM
				pop es
				mov di, 0

				endm

.restoreCX		macro

				pop cx
				push cx

				endm

.nextLine		macro
				
				add di, dx
				
				endm

VIDEOMEM equ 0b800h
COLOR equ 0Ah
HEIGHT equ 4
nextVidPage equ 4000d
F1_			equ 3bh
F2_			equ 3ch
shift		equ 136d

start:      mov ax, 3508h			; saving addr of orig 08h interruptions
			int 21h
			mov di, offset Old08
			mov [di], bx
			mov [di + 2], es

			mov ax, 2508h			; put new addr of my own int
			mov dx, offset New08
			int 21h


			mov ax, 3509h			; saving addr of orig 09h interruptions
			int 21h
			mov di, offset Old09
			mov [di], bx
			mov [di + 2], es

			mov ax, 2509h			; put new addr of my own int
			mov dx, offset New09
			int 21h

            mov ax, 3100h 			; start TSR
            mov dx, offset EOP 		; End of programm
            shr dx, 4
            inc dx
            int 21h



New08       proc
			push ax bx cx dx sp di es ds
			;pusha
			mov cs:RegValues[0 + 2 * 0], ax		; saving regs
			mov cs:RegValues[0 + 2 * 1], bx
			mov cs:RegValues[0 + 2 * 2], cx
			mov cs:RegValues[0 + 2 * 3], dx

			cmp cs:IsF1, 1
			je checkF2
			jmp checkF1

checkF2:	cmp cs:ScnCode, F2_
			je Restore
			jmp DrawWSav

checkF1:	cmp cs:ScnCode, F1_
			je  Draw
			jmp exitOUT
			
Draw:       cmp cs:IsF1, 1 ;test cs:IsF1, cs:IsF1
			je DrawWSav

			mov cs:IsF1, 1
			call SavePage1

DrawWSav:	push cs
			pop ds

			mov dx, shift
			call PrintFrameRegs

			jmp exitOUT

Restore:	mov cs:IsF1, 0 ; xor ...
			call RestorePage

exitOUT:	pop ds es di sp dx cx bx ax
			; popa

Jump08:     db 0EAh				; jmp far to the previous handler
Old08:      dd 0h

            endp



New09       proc

            push ax

            in al, 60h
            mov cs:ScnCode, al

			cmp cs:ScnCode, F1_
			je F1
			jmp next_1
F1:			cmp cs:IsF1, 1			; ending int if F1 pressed but frame is already displayed
			je intending

next_1:		
			cmp cs:ScnCode, F2_
			je F2
			jmp next_2
F2:			cmp cs:IsF1, 0			; ending int if F2 pressed but frame is already displayed
			je intending

next_2:		
			cmp cs:IsF1, 1
			jne isF1p

			cmp cs:ScnCode, F2_
			jne ending
			jmp intending

isF1p:		cmp cs:ScnCode, F1_
			jne ending

intending:  in al, 61h			; sending message of finishing int
            mov ah, al
            or al, 80h
            out 61h, al
            xchg al, ah
            out 61h, al

			mov al, 20h
            out 20h, al

			pop ax
            iret

ending:		pop ax

Jmp09		db 0EAh				; jmp far to the previous handler
Old09		dd 0h

			endp

;------------------------------------------------
; This function saves 0h videopage to the next one
;
; Entry: None
; Exit: none
; Destr: es cx di
;------------------------------------------------
SavePage1   proc

            .setVidReg

cycle1:     mov dx, es:[di]

            mov es:[di + nextVidPage], dx
            add di, 2

            loop cycle1

            ret
            endp

;------------------------------------------------
; This function restores 0h videopage
;
; Entry: None
; Exit: none
; Destr: es cx di
;------------------------------------------------
RestorePage proc

            .setVidReg

cycle_:     mov dx, es:[di + nextVidPage]

            mov es:[di], dx
            add di, 2

            loop cycle_

            ret
            endp

IsF1		db 	0h
ScnCode		db	0h

RegVal		db	4 dup (0)

RegValues 	dw  4 dup (0)

include Frm.ASM

EOP:        mov ax, 4c00h
            int 21h
			 	
end start