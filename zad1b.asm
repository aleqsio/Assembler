assume 			cs:code, ds:data, ss:stos   		;assigns segments to correct functions
;#####################################
; VARIABLES WITH HORIZONTAL LINES
;#################################### 


data 	segment                           ;data segment
hline 	DB 		' #####',"$"          ;display horizontal lines
lonly   DB		'#',10,13,"$"
ronly	DB		'      #',10,13,'$'
both	DB		'#     #',10,13,'$'
break	DB		10,13,'$';enters are typed after each horizontal line, only if no vertical line was drawn (then 3 times)
pos		DW		0
digits	DB		01111110b,00110000b,01101101b,01111001b,00110011b,01011011b,01011111b,01110000b,01111111b,01111011b
data	ends
 
	
	
stos	segment stack 'stack'
	db	64		DUP (0) 
stos	ends	
	

code 	segment  	
;#####################################
; SUBROUTINES FOR DRAWING HORIZONTAL LINES
;####################################
h_p		proc     ;procedure responsible for drawing a horizontal line #####
		mov 	AX,seg hline ;segment of hline variable adress moved to DS trough AX
		mov 	DS,AX        
		mov 	DX,offset hline ;offset moved to DX, cause 21h prints string from DS:DX adress
		mov		AH,09; set for string display subroutine of 21h system call                       
		
		int 	21h   ;prints string
		ret      ;returns
h_p		endp		
		
brk_p		proc   
		mov 	AX,seg break
		mov 	DS,AX        
		mov 	DX,offset break
		mov		AH,09                       
		int 	21h
		ret
brk_p		endp

l_p		proc      ;prints '#    ' 3 times
		mov 	AX,seg lonly
		mov 	DS,AX
		mov 	DX,offset lonly
		mov		AH,09
		int 	21h
		int 	21h
		int 	21h
		ret
l_p		endp

r_p		proc   ;prints '    #' 3 times
		mov 	AX,seg ronly
		mov 	DS,AX
		mov 	DX,offset ronly
		mov		AH,09
		int 	21h
		int 	21h
		int 	21h
		ret
r_p		endp 

b_p		proc   ;prints '#   #' 3 times
		                       
		mov 	AX,seg both
		mov 	DS,AX
		mov 	DX,offset both
		mov		AH,09
		int 	21h
		int 	21h
		int 	21h
		ret
b_p		endp



close   proc   ;closes the program via 4ch subprogram of 21h
		pop		DX
		pop		CX
		pop		BX
		pop		AX
        mov 	AH,4Ch
		int 	21h
		ret
close 	endp

;#####################################
; MAIN SUBROUTINE
;####################################

pr7seg	proc
	;grabs encoded segments from AL 
	    
	    ;######FIRST HORIZONTAL SEGMENT
	    
		mov		CL,AL  ;stores mask in cl, cause AL is used in lines display
		mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,10111111b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh         ;first horizontal
		jnz 	skipfail1
	    call 	h_p
	    skipfail1: 
	    call brk_p
	    ;######FIRST VERITCAL SEGMENT
	    
	    mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11011101b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh
		jnz 	skipfail2     ;first_both
	    call 	b_p
	    jz		skipsuccess1
	    skipfail2:  
	    
	       mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11111101b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh
		jnz 	skipfail3    ;first_left
	    call 	l_p
	    jz		skipsuccess1
	    skipfail3:
	    
	       mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11011111b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh
		jnz 	skipfail4      ;first right
	    call 	r_p
	    jz		skipsuccess1
	    skipfail4:  
	    
	    call brk_p
	    call brk_p    ;draws empty 3 lines if no segments lit up
	    call brk_p 
	    
	    skipsuccess1:   ;end of first vertical segment
	    
	    ;######SECOND HORIZONTAL SEGMENT
	    
	   mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11111110b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh         ;second horizontal
		jnz 	skipfail5
	    call 	h_p
	    
	    skipfail5: 
	    call brk_p    	
		;######SECOND VERTICAL SEGMENT
	    
	    mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11101011b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh
		jnz 	skipfail6     ;second both
	    call 	b_p
	    jz		skipsuccess2
	    skipfail6:  
	    
	       mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11111011b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh
		jnz 	skipfail7    ;second left
	    call 	l_p
	    jz		skipsuccess2
	    skipfail7:
	    
	       mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11101111b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh
		jnz 	skipfail8      ;second right
	    call 	r_p
	    jz		skipsuccess2
	    skipfail8:
	    
	    call brk_p
	    call brk_p       ;draws empty 3 lines if no segments lit up
	    call brk_p
	    
	    skipsuccess2:   ;end of second vertical segment
	     
		 ;######THIRD HORIZONTAL SEGMENT
	    
	   mov 	BL,CL  ;reads in value to bl for or comparision
		OR 		BL,11110111b ;compares to stored mask (to light up segments)
		cmp  	BL, 0FFh         ;second horizontal
		jnz 	skipfail9
	    call 	h_p
skipfail9:
	    call	brk_p     ;adds last newline
		ret
pr7seg	endp

clrscr	proc                  ;clears screen
	    mov		AH,0fh     ;gets current screen mode into AH
        int		10h
        mov		AH,0      ;sets mode from AH
        int		10h
        ret
clrscr	endp

advance	proc ;sets AL to next digit binary mask
		inc		pos              ;increments digit counter
		cmp		pos,10d
		jnz		noreset
		mov		pos,0
noreset:
		mov 	BX,seg both
		mov 	DS,BX            ;reads in memory loc of digits
		mov		BX,offset	digits
		mov		AX,pos            ;adds pos counter to mem location of digits to get array element
		add		BX,AX
		mov		AL,[BX]
	    ret
advance endp
start:  
	    push	AX
	    push	BX
	    push	CX
	    push	DX
myloop: 

		call	clrscr ;clears screen		
		call	advance;advances to next digit
		call 	pr7seg ;prints
				
		mov     AH,0
		int		16h     ;waits for key
		cmp		AL,27d	
		jnz		myloop   ;next digit
		call	close    ;ends if esc key pressed
		
code 	ends
		end start