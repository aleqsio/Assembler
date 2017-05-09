assume 			cs:code, ds:data, ss:stos   		;assigns segments to correct functions

data 	segment        
	   ballx	 dw		?
	   bally	 dw		?
	   ay		 dw		? 
	    by		 dw		?
		ballxvec dw		?
		ballyvec dw		?
		errormsg	DB		"GAME OVER","$"
data	ends	
	
stos	segment stack 'stack'
		dw		256		DUP (0)
stos	ends	

code 	segment  

init	proc

		mov word ptr ds:[ay],100
		mov word ptr ds:[ballx],100
		mov word ptr ds:[bally],100
		mov word ptr ds:[ballyvec],-1
		mov word ptr ds:[ballxvec],-2
		mov word ptr ds:[by],100
		ret
init 	endp

print	macro	x
		mov 	AX,seg x
		mov 	DS,AX  ;prints input
		mov 	DX,offset x		                         
		mov		AH,09; set for string display subroutine of 21h system call                       
		int 	21h   ;prints string
	endm	

close   proc   ;closes the program via 4ch subprogram of 21h
call	unswitch
print errormsg
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
		pop DX
		mov es:[di], dl ; And we put the pixel
		pop CX
		pop BX
		pop AX
		ret
drwpx	endp
drawball	proc
		mov	AX,word ptr ds:[bally]
		mov	CX,word ptr ds:[bally]
		add CX,5
		sub AX,5   
	  
		dback:
		inc AX
		mov	BX,word ptr ds:[ballx]
		sub BX,5
		cback:
		add BX,10
			mov dl, 7 ; gray color.
		call drwpx
		inc	BX
		sub BX,10
		cmp	BX,word ptr ds:[ballx]
		jl	cback
		
		
		cmp AX,CX
		jl  dback
		ret		
drawball	endp
drawpalletes	 proc	
		mov	AX,word ptr ds:[ay]
		mov	CX,word ptr ds:[ay]
		add CX,20
		sub AX,20   
		mov dl, 10 ; green color.  
		bback:
		inc AX
		mov	BX,5
		aback:
		call drwpx
		inc	BX
		cmp	BX,10
		jl	aback
		cmp AX,CX

		jl  bback 
		
		mov	AX,word ptr ds:[by]
		mov	CX,word ptr ds:[by]
		add CX,20
		sub AX,20   
		mov dl, 12 ; red color.  
		bback2:
		inc AX
		mov	BX,310
		mov	BX,310
		aback2:
		call drwpx
		inc	BX
		cmp	BX,315
		jl	aback2
		cmp AX,CX
		jl  bback2
		
		ret
drawpalletes endp
readkey		proc
	    xor ax,ax 		
	    mov ah,01h 		
	    int 16h 		
	    jz skip 		
	    xor ax,ax 		
	    int 16h
	    cmp ah,01h
	    jne skip1
	    call close
	    
	    skip1: 		
	    cmp ah,50h
	    je up 		
	    cmp ah,48h 
	    je down
	    ret 		
	    up:
		cmp		word ptr ds:[ay],180
		jg nomove1
	    add word ptr ds:[ay],4
	    nomove1:
	    
	    
	    
	    ret
	    down:
		cmp		word ptr ds:[ay],20
		jl nomove2
	    sub word ptr ds:[ay],4
	    nomove2:
	    skip:
	    ret
readkey	endp
moves	macro
		mov		BX,word ptr ds:[ballxvec]
		mov		AX,word ptr ds:[ballx]
		add AX,BX
		mov	word ptr ds:[ballx],AX
		
		mov		BX,word ptr ds:[ballyvec]
		mov		AX,word ptr ds:[bally]
		add AX,BX
		mov	word ptr ds:[bally],AX
		cmp		AX,20
		jl		noadju
		cmp		AX,180
		jg		noadju
		mov	word ptr ds:[by],AX
		noadju:
endm
logic	proc
push	AX
push	BX
;moves the ball
		moves
		;detects palletes
		mov		AX,word ptr ds:[ballx]
		cmp		AX,5
		jl		gotleft
		cmp		AX,300
		jg		gotright
		
		jmp		skip3
		gotleft:
		mov		AX,word ptr ds:[bally]
		mov		BX,word ptr ds:[ay]
		sub		AX,BX
		cmp		AX,15
		jg		over
		cmp		AX,-15
		jl		over
		mov		BX,word ptr ds:[ballxvec]
		xor		AX,AX
		sub		AX,BX
		
		mov		word ptr ds:[ballxvec],AX
		
		
		
		
		jmp		skip3
		
		gotright:
		mov		BX,word ptr ds:[ballxvec]
		xor		AX,AX
		sub		AX,BX
		mov		word ptr ds:[ballxvec],AX
		skip3:
		
		mov		AX,word ptr ds:[bally]
		cmp		AX,0
		jl		turn
		cmp		AX,200
		jg		turn
		jmp		skip4
		turn:
		mov		BX,word ptr ds:[ballyvec]
		xor		AX,AX
		sub		AX,BX
		mov		word ptr ds:[ballyvec],AX
		
		skip4:
		
		
		
		
		pop		BX
		pop		AX
		ret
		over:
		call	close
		
		ret
logic 	endp

draw	proc
		;draws ball
		call	readkey
		call	logic
		call	drawball
		call	drawpalletes
		
		
		
		
		
		ret
draw	endp  

clean	proc 		
		mov cx,0
		mov bx,0
		mov dx,63999
		mov ah,06h
		mov al,0
		int 10h 
		ret
clean	endp
sleep	proc 
	 	mov 	AH,86h
		push	CX
		push	DX
		mov		CX,0                                        
        mov		DX,40000	  
        int 	15h
        pop		DX
        pop		CX
        ret
sleep	endp
main	proc
	
		call 	switch
		nxtframe:
		call 	clean
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