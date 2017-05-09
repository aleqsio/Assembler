assume 			cs:code, ds:data, ss:stos   		;assigns segments to correct functions
data 	segment                           ;data segment
help 		DB 		"-h -  wyswietla help",10,13,"-i  - dodaje plik wejsciowy",10,13
help2		DB		"-o  - okresla nazwe pliku wyjsciowego",10,13,"-t  - znak wstawiany do pliku wynikowego rozdzielajacy wiersze",10,13
help3		DB		"(albo pola) z plikow wejsciowych. Domyslnie jest to spacja.",10,13,"$"
error_nocmd	DB		"BLAD: brak lub nieprawidlowe argumenty","$"
error_wr	DB		"BLAD: odczyt lub zapis pliku niemozliwy","$"
error_unkn	DB		"BLAD: nieznany blad","$"

cmdsize 	DB		? ;variable for storing command line length
cmdinput	DW		200		dup("$") ;variable for storing command line data
data	ends
 
	
	
stos	segment stack 'stack'
		dw		256		DUP (0) 
stos	ends	

code 	segment  

errorp 	proc
		cmp		AX,0
		jnz		skiperr1
		mov 	AX,seg error_nocmd
		mov 	DS,AX
		mov 	DX,offset error_nocmd
		skiperr1:
		cmp		AX,1
		jnz		skiperr2
		mov 	AX,seg error_wr
		mov 	DS,AX
		mov 	DX,offset error_wr
		skiperr2:
		cmp		AX,2
		jnz		skiperr3
		mov 	AX,seg error_unkn
		mov 	DS,AX
		mov 	DX,offset error_unkn
		skiperr3:
		call	print
		call	close
		ret
errorp	endp
close   proc   ;closes the program via 4ch subprogram of 21h
        mov 	AH,4Ch
		int 	21h
		ret
close 	endp
print	proc                         
		mov		AH,09; set for string display subroutine of 21h system call                       
		int 	21h   ;prints string
		ret      ;returns
print	endp	

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

cmdlen proc    
		mov		AH,62h
		int		21h
		mov		DS,BX
		xor		AX,AX
		mov		AL,DS:[80h]
		cmp		AL,0
		jnz		skip
		mov		AX,0
		call	errorp
		skip:
		mov		cmdsize,AL
		call	printreg
		ret
cmdlen endp

prthelp	proc     ;sets segment and offset of help byte
		push	AX
        mov 	AX,seg help
		mov 	DS,AX
		mov 	DX,offset help
		call	print
		pop		AX
		ret
prthelp endp

main	proc   
		call	cmdlen
	    call	prthelp
	    call	close
		ret 
main	endp

	    start:
		call	main
code 	ends
		end		start	;sets entry point
