;---------------------------------------------------------
; This function prints frame
;
; Entry: ES, DI
; Exit: none
; Destr CX, BX, AX, BP, SI
;--------------------------------------------------------
PrintFrame	proc

			push bp

			mov bp, sp

			mov si, [bp+4]    ; get 1st arg

			call printLine

			mov cx, HEIGHT

@@printFrameSS:
			mov bx, cx
			mov cx, [bp + 10] ; get 4th arg

			mov si, [bp + 6] ; get 2nd arg

			call printLine

			mov cx, bx
			loop @@printFrameSS

			mov cx, [bp + 10] ; get 4th arg

			mov si, [bp + 8] ; get 3rd arg

			call printLine

			pop bp

			ret
			endp



;---------------------------------------------------------
; This function prints line
;
; Entry: SI, DI
; Exit: none
; Destr: AX, SI, DI
;---------------------------------------------------------
printLine		proc
		
				mov ah, COLOR

				lodsb				; print left corner
				stosw
							
				lodsb				; print middle part
				rep stosw

				lodsb				; print right corner
				stosw

				.nextLine
				
				ret
				endp


;--------------------------------------------------------
; This function prints text
;
; Entry: DI, BP - addr of string, BX - val
;
;
;
;
;--------------------------------------------------------
PrintReg		proc

				mov ah, 0Ah

cycle:			cmp byte ptr cs:[bp], '$'
				je EndOut

				mov al, byte ptr cs:[bp]
				mov es:[di], ax
				inc bp
				add di, 2

				jmp cycle

EndOut:			mov si, offset cs:RegVal
				mov cx, 10h
				call itoa

				mov ah, 0Ah

				mov al, cs:[si + 3]
				mov es:[di], ax

				mov al, cs:[si + 2]
				mov es:[di + 2], ax

				mov al, cs:[si + 1]
				mov es:[di + 4], ax

				mov al, cs:[si + 0]
				mov es:[di + 6], ax

				ret
				endp

;-------------------------------------------
; This function prints AX, BX, CX, and DX
;
; Entry: DI - video addr, DX - addr of reg values
;		 ES - video seg, SI - buff with reg val
;-------------------------------------------
Print4Regs		proc									; make a macro

				mov bp, offset cs:a_x
				mov bx, cs:RegValues [0 + 0 * 2]
				call PrintReg

				mov bp, offset cs:b_x
				mov bx, cs:RegValues[0 + 1 * 2]
				mov di, 1830d
				call PrintReg

				mov bp, offset cs:c_x
				mov bx, cs:RegValues[0 + 2 * 2]
				mov di, 1990d
				call PrintReg

				mov bp, offset cs:d_x
				mov bx, cs:RegValues[0 + 3 * 2]
				mov di, 2150d
				call PrintReg

				ret
				endp

;-----------------------------------------------
; Prints frame with regs
;-----------------------------------------------
PrintFrameRegs	proc
				push ax bx cx dx si di bp sp ds es ss

				mov ax, 0b800h
				mov es, ax

				mov cx, 10d
				mov di, 1508d
				mov dx, shift

				push cx
				push offset cs:BottomD
				push offset cs:MidD
				push offset cs:TopD

				call PrintFrame

				pop cx
				pop cx
				pop cx
				pop cx

				mov di, 1670d
				call Print4Regs

				pop ss es ds sp bp di si dx cx bx ax

				ret
				endp

;--------------------------------------------
; Converts an integer value to a null-terminated string using
; the specified base and stores the result in the array given by str parameter.
;
; Entry: 	DS - segment of data
;			SI - addr of the string
;			BX - number
;			CX - base of numeric system
;
; Exit:		SI - addr of the string
;
; Destr:	AX, BX, DX
;--------------------------------------------
itoa		proc

            mov ax, bx          

count:
            xor dx, dx
            div cx

            cmp ax, 0
            je MainFunc
            inc si
            jmp count

MainFunc:
            mov ax, bx

itoaloop:
            xor dx, dx
            div cx

            mov bx, dx
            mov dl, cs:[bx + offset ConvertTable]   

            mov cs:[si], dl     
            dec si

            cmp ax, 0
            jne itoaloop

            inc si

			ret
			endp

ConvertTable	db '0123456789ABCDEF'


TopD		db 0C9h, 0CDh, 0BBh
MidD		db 0BAh, 32d, 0BAh
BottomD		db 0C8h, 0CDh, 0BCh

a_x			db 'ax = $'
b_x			db 'bx = $'
c_x			db 'cx = $'
d_x			db 'dx = $'