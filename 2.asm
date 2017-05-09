assume 			cs:code, ds:data, ss:stos   		;assigns segments to correct functions
data 	segment                           ;data segment
help 		DB 		"-h -  wyswietla help",10,13,"-i  - dodaje plik wejsciowy",10,13,"$"
help3		DB		"(albo pola) z plikow wejsciowych. Domyslnie jest to spacja.",10,13,"$"
help2		DB		"-o  - okresla nazwe pliku wyjsciowego",10,13,"-t  - znak wstawiany do pliku wynikowego rozdzielajacy wiersze",10,13,"$"
error_nocmd	DB		"BLAD: brak lub nieprawidlowe argumenty","$"
error_wr	DB		"BLAD: odczyt lub zapis pliku niemozliwy","$"
error_unkn	DB		"BLAD: nieznany blad","$"

status		DB		0 ;0-skips space 1-awaits option 2-reads input file 3-reads output file 4-reads delimiter 5 shows help
skiped		DB		0	;skips space after arg letter
delimiter	DB	" $" ;default delimiter
cmdsize 	DB		0 ;variable for storing command line length
cmdinput	DW		200		dup("$") ;variable for storing command line data
newline		DB	10,13,"$"
output		DB "$"
data	ends
 
	
	
stos	segment stack 'stack'
		dw		256		DUP (0) 
stos	ends	

code 	segment  

errorp 	macro	error_code
		mov		AX,error_code
		cmp		AX,0
		jnz		skiperr1
		print 	error_nocmd
		skiperr1:
		cmp		AX,1
		jnz		skiperr2
		print 	error_wr
		skiperr2:
		cmp		AX,2
		jnz		skiperr3
		print	error_unkn
		skiperr3:
		call	close
errorp	endm       

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
print	endm	

printreg proc
	MOV CX, 4
next_digit:
  	PUSH CX
  	MOV CL, 4
  	ROL AX, CL
  	PUSH AX
  	AND AL, 0Fh
  	ADD AL, '0'
  	CMP AL, '9'
  	JLE not_a_letter
  	ADD AL, 'A'-'9'-1
not_a_letter:
	mov DL,AL
	mov	AH,06h
	int	21h
  	POP AX
  	POP CX
  	LOOP next_digit
	ret
printreg endp


parsechar	macro	x     ;sets status based on char
	
	
	 
        cmp		skiped,1
        jnz		skipparse0
        mov		skiped,0
        jmp		skipdone
        skipparse0:
        
		cmp		x,'-'     ;1-awaits option 2-reads input file 3-reads output file 4-reads delimiter
		jnz		skipparse1
		mov		status,1
		jmp		skipdone
skipparse1:

		cmp		x,' '     ;0-skips space 
		jnz		skipparse2
		mov		status,0
skipparse2:
		cmp		status,1     ; 5-shows help
		jnz		skipparse3
        cmp		x,'h'
        jnz		skipparse3
		mov		status,5
		mov		skiped,1
		call	prthelp
skipparse3:
		cmp		status,1     ; 2 reads input
		jnz		skipparse4
        cmp		x,'i'
        jnz		skipparse4
		mov		status,2
		mov		skiped,1
		jmp		skipdone
skipparse4:
		cmp		status,1    ; 3 reads output
		jnz		skipparse5
        cmp		x,'o'
        mov		BX,0
        jnz		skipparse5
		mov		status,3
		mov		skiped,1
		jmp		skipdone
skipparse5:
cmp		status,1    ; 3 reads delimiter
		jnz		skipparse6
        cmp		x,'d'
        jnz		skipparse6
		mov		status,4
		mov		skiped,1
		jmp		skipdone
skipparse6:

        cmp		status,4
jnz		skipparse7
		push	BX
        push	DS
        
		mov		BX,seg delimiter
		mov		DS,BX
	
		mov 	ds:[delimiter],x
		pop		DS
		pop		BX
skipparse7:
		 cmp		status,3
		 jnz	skipparse8
		 push	BX
		 mov	BX,seg output
		 mov	DS,BX
		 pop	BX
		 mov	DL,x
		 mov 	ds:[output+BX],x
		 inc	BX
skipparse8:
skipdone:	
		mov		DL,status
parsechar	endm      
      
      
cmdread proc    
		mov		AH,62h
		;int		21h
		;mov		DS,BX
		xor		AX,AX
		mov		AL,DS:[80h]
		cmp		AL,1
		jg		skip
		mov		AX,0          ;reads length
		errorp   0
		skip:
		mov		cmdsize,AL     
		
		xor		cx,cx
		MOV		cl,al     ;reads al into cx (loop counter)
		xor		bx,bx
		mov		DX,seg cmdinput     ;reads cmdinput offset into ES
		mov		ES,DX
cpy:  					; reads consequtive chars into string
		mov ah,DS:[81h+BX]
		mov byte ptr ES:cmdinput[BX],AH
		parsechar	ah	
		inc		BX
		loop	cpy                ;copies chars from 81h to cmdinput parsing them along the way
		mov		AL,cmdsize
		
		print  delimiter	
		print	output
		
		ret
cmdread endp   

prthelp	proc  					   ;sets segment and offset of help byte
		print	help 
		print	help2
		print	help3
		call	close
		ret
prthelp endp

main	proc   
		call	cmdread  
	    call	close
		ret 
main	endp

	    start:
		call	main
code 	ends
		end		start	;sets entry point
