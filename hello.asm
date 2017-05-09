		.model tiny
		.stack 100h
		.CODE
		org 100h
hello 	proc
		mov ax,cs
		mov ds,ax
		mov ah,09h
		lea dx,msg
		int 21h
		mov ax,4c00h
		int 21h
hello 	endp
msg		ds 'Hello$'
		end hello