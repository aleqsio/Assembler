assume 			cs:code, ds:data, ss:stos   		;assigns segments to correct functions

data 	segment                           ;data segment
cmdsize		DB		0
errormsg	DB		"BLAD: odczyt pliku niemozliwy","$"
space		DB		" $"
filename	DW		200		dup("$") ;variable for storing filename
digit		DB		20		dup(0)
letter		DB		0
filehandle	DW		0
lines		DW		1
words		DW		0
chars		DW		0
wasword		DB		0
data	ends	
	
stos	segment stack 'stack'
		dw		256		DUP (0) 
stos	ends	

code 	segment  

close   proc   ;closes the program via 4ch subprogram of 21h
        mov 	AH,4Ch
		int 	21h
		ret
close 	endp    

print	macro	x
		mov 	AX,seg x
		mov 	DS,AX  ;prints input
		mov 	DX,offset x		                         
		mov		AH,09; set for string display subroutine of 21h system call                       
		int 	21h   ;prints string
	endm	

printnum proc ;prints from ax
		mov 	BX,seg digit ;can use filename to store digits
		mov 	DS,BX  
		xor 	BX,BX
		mov 	CX,10
nextdigit:
		xor 	DX,DX
		div 	CX
		xor 	DH,DH
		add 	DL, '0'
		mov 	DS:digit[BX],DL
		inc 	BX
		cmp 	AX, 0
		jnz 	nextdigit
printdigit:
		dec 	BX
		mov		DL,DS:digit[BX]
		mov 	ah,2  
		int 	21h
		
		cmp 	BX,0
		jnz		printdigit
		ret		
printnum endp
      
cmdread proc    
		mov		AH,62h
		xor		AX,AX
		mov		AL,DS:[80h]
		
		mov		cmdsize,AL 
		cmp		AL,2
		jl		goerror
		dec		AL
    
		xor		cx,cx
		MOV		cl,al     ;reads al into cx (loop counter)
		xor		bx,bx
		
		mov		DX,seg filename     ;reads cmdinput offset into ES
		mov		ES,DX
cpy:  					; reads consequtive chars into string
		mov 	ah,DS:[82h+BX]
		mov 	byte ptr ES:filename[BX],AH
		inc		BX
		loop	cpy                ;copies chars from 81h to name
		mov 	byte ptr ES:filename[BX],0
		ret
cmdread endp   

openfile proc 
		mov		AX,seg	filename
		mov 	DX,offset filename
		mov		DS,AX 
		xor		ax,ax
		
		mov 	ah,03DH
	
		int		21h
		jc 		goerror
		
		mov 	filehandle,ax
		ret
goerror:
		print	errormsg
		call	close
openfile endp

readfile proc
	readnext: 
		call	readletter       ; 3 cases - space - increases chars and adds word if existed
		cmp		letter,' '       ; newline - adds word if existed
		jz		isspace          ; something else - sets word to existing
	    cmp		letter,10
	    jz		isnewline
	    cmp		letter,13
	    jz		readend
	    jmp		somethingelse
	    
isspace:
	    inc 	chars
	    call 	incwords
	    jmp		readend
	    
isnewline:
	    inc		lines
	    call 	incwords
	    jmp		readend
somethingelse:
	    inc 	chars
	    mov 	wasword,1
	    jmp		readend
readend:    
		cmp		AX,1 
		jz		readnext
		dec 	chars
		call 	incwords
		ret
readfile endp

incwords proc
	    cmp		wasword,0
		jz 		dontadd
		inc 	words
		mov		wasword,0
dontadd:
		ret
incwords endp

readletter proc
		mov 	ah, 03FH
		mov 	cx,1
		mov 	bx,filehandle  ; pokazuje, ktory kanal ma byc odczytany
		mov 	DX,seg letter
		mov		DS,DX
		mov 	dx,offset ds:[letter] ; wskazuje bufor, do ktorego wczytujemy bajty
		int 	21h
		ret
readletter endp

closefile proc 
		mov ah,03EH
		mov bx,filehandle
		int 21h
		ret
closefile endp

main	proc
		call	cmdread
		call	openfile
		call	readfile
		call	closefile
		
	    mov 	AX,lines
	    call 	printnum
		print 	space
	
		mov 	AX,words
	    call 	printnum
		print 	space 
		
		mov 	AX,chars
	    call 	printnum
		print 	space
		call	close
		ret 
main	endp

start:
		call	main
code	ends
end		start	;sets entry point