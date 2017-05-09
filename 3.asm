assume 			cs:code, ds:data, ss:stos   		;assigns segments to correct functions

data 	segment        
	   ballx	 dw		?
	   bally	 dw		?
	   ay		 dw		?
	   by		dw		?
data	ends	
	
stos	segment stack 'stack'
		dw		256		DUP (0)
stos	ends	

code 	segment  

init	proc

		mov word ptr ds:[ay],100
		ret
init 	endp

close   proc   ;closes the program via 4ch subprogram of 21h
        mov 	AH,4Ch
		int 	21h
		ret
close 	endp 

switch	proc
		mov ax, 13h ; AH=0 (Change video mode), AL=13h (Mode)
		int 10h ; Video BIOS interrupt 
		
		ret
switch	endp  
unswitch proc 	
	mov ax,03h 		
	int 10h 		
	ret
unswitch endp
drwpx	proc            ;BX:AX
		push AX
		push BX
		push CX
		push DX
		mov cx,320
		mul cx
		add ax,bx
		mov di,ax
		mov     ax, 0a000h
		mov     es, ax
		mov es:[di], dl ; And we put the pixel
		pop DX
		pop CX
		pop BX
		pop AX
		ret
drwpx	endp

drawpallete	 proc	
		mov	AX,word ptr ds:[ay]
		mov	CX,word ptr ds:[ay]
		add CX,10
		sub AX,10
		bback:
		mov	BX,5
		aback:
		mov dl, 7 ; Grey color.  
		call drwpx
		inc	BX
		cmp	BX,10
		jl	aback
		cmp AX,CX
		inc AX
		jl  bback
		ret
drawpallete endp

draw	proc
		;draws ball
		
		call	drawpallete
        inc	ballx
		mov	bx,word ptr ballx
		mov	ax,word ptr bally
		mov dl, 7 ; Grey color.  
		
		call	drwpx
		
		
		
		ret
draw	endp  
sleep	proc 
	 	mov 	AH,86h
		push	CX
		push	DX
		mov		CX,0                                         
        mov		DX,300  
        int 	15h
        pop		DX
        pop		CX
        ret
sleep	endp
main	proc
	call 	switch
		nxtframe:
		
		call 	draw
		call	sleep
		jmp		nxtframe
		ret 
main	endp

start:	
		call	init
		call	main
code	ends
end		start	;sets entry point