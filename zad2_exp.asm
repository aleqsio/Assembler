; ---- segment danych ----
dane segment
help		db	"Sposob wywolania: konkatenuj [-h] {-i plik_wejsciowy} [-o plik_wyjsciowy] [-t znak_separacji]",10,13,"$"
no_i_err	db	"Brak pliku wejsciowego",10,13,"$"
bad_syntax	db	"Bledna skladnia wywolania",10,13,"$"
file_err	db	"Blad odczytu/zapisu pliku",10,13,"$"
err			db 	"Blad!",10,13,"$"
cmdline		db	257	dup('$') ; zmienna przechowujaca zawartosc linii komend
cmdlength	dw	? ; dlugosc linii komend
bool_out	db	0 ; flaga mowiaca, czy podano plik wyjsciowy
bool_eof	db	255 dup(0) ; flaga mowiaca, czy dany plik sie skonczyl
pointerdx 	dw	100 dup(0)	;	tutaj b�d� cz�ci m�odsze adres�w koncow wierszy w plikach, do ktorych na razie doszlismy
pointercx 	dw	100	dup(0)	;	a tutaj starsze
separator	db	" $" ; domyslny separator - spacja
newline		db	10,13,"$"	; nowa linia
tmp			dw	?	; bufor na nazwy plikow wejsciowych/wyjsciowego
bufor		db	3 dup('$') ; bufor do wczytywania linii
in_count	db	0 ; ilosc plikow wejsciowych
in_handle	dw	? ; uchwyt pliku wejsciowego
in_files	db	255 dup('$') ; nazwy plikow wejsciowych
in_ended	db	? ; zmienna pokazujaca, ile plikow wejsciowych juz sie zakonczylo
in_copied	dw	? ; zmienna pokazujaca, z ilu plikow pobrano juz wiersze
out_handle 	dw	?	; uchwyt pliku wyjsciowego
out_file	db	255 dup('$') ; nazwa pliku wyjsciowego

dane ends
 
myStack   segment STACK
			dw	200 dup(?) 
myStack   ends

; ---- makra ----

	prints macro xx  ; makro wypisuje ciag znakow z wybranego miejsca w pamieci
		mov dx,xx
		mov ah,9
		int 21h
	endm
	
	fopen macro xx ; makro otwierajace plik o podanej nazwie
		mov ah,03DH
		mov al,0
		mov dx,xx
		int 21h
		jc file_exc
		mov in_handle,ax  ; zapisuje uchwyt do pliku w zmiennej
	endm
		
	fread macro  ; odczytanie do bufora danej w cx liczby bajtow
		mov ah, 03FH
		mov cx,1
		mov bx,in_handle  ; pokazuje, ktory kanal ma byc odczytany
		mov dx,offset ds:[bufor] ; wskazuje bufor, do ktorego wczytujemy bajty
		int 21h
		jc file_exc
	endm
		
	fclose macro xx ; zamkniecie danego przez uchwyt pliku
		mov ah,03EH
		mov bx,xx ; wskazanie, ktory plik zamykamy
		int 21h
		jc file_exc
	endm
		
	fwrite macro xx ; zajmuje sie zapisywaniem do pliku wyjsciowego danych
		mov ah,040H
		mov bx,out_handle ; to jest plik wyjsciowy
		mov dx,offset xx ; to wpisujemy
		mov cx,di ; ile bajtow wpisujemy
		int 21h
		jc file_exc
	endm
	
	fcreate macro xx ; makro tworzace plik o danej nazwie
		mov ah,03CH
		mov dx,offset ds:[xx]
		int 21h
		jc file_exc
		mov out_handle,ax ; zapisujemy uchwyt do pliku wyjsciowego
	endm
		
	fpoint macro xx ; makro ustawiajace pointer w odpowiednim miejscu
			push di
			xor	cx,cx								
			xor	dx,dx
			mov	di,xx
			shl	di,1
			mov	dx,word ptr ds:[pointerdx+di]
			mov	cx,word ptr ds:[pointercx+di]
			mov	ah,042H
			mov	bx,in_handle
			mov	al,00H	;	miejsce w pliku liczone od pocz�tku
			int 21h
			pop di
			jc file_exc
	endm			


code segment
	assume cs:code,ds:dane,ss:myStack
	
; ---- procedury ----

	; procedura konczaca program, gdy pojawi sie blad skladni (pusta linia komend, bledne opcje, zla kolejnosc itp)
	bad_syntax_exc:
		prints offset bad_syntax
		jmp exit
		
	; procedura wypisujaca pomoc
	display_help:
		prints offset help
		jmp exit
	
	; procedura konczaca program, gdy nie podano pliku wejsciowego
	no_input:
		prints offset no_i_err
		jmp exit
	
	; procedura konczaca program, gdy nastapi blad przy otwieraniu pliku
	file_exc:
		prints offset file_err
		jmp exit
		
	; inny blad
	other_error:
		prints offset err
		jmp exit
	
	; procedura omijajaca spacje w linie komend	
	skip:
		skipping:
		inc si
		cmp si,cmdlength ; sprawdzam, czy nie doszlismy do konca linii komend, jesli tak - podano pusta opcje
		ja bad_syntax_exc
		mov ah,byte ptr ds:[cmdline+si]
		cmp ah,' ' ; nie moge sprawdzac bezposrednio rejestru segmentowego
		je skipping
		ret
		
	; procedura zmieniajaca domyslny separator linii na podany przy wywolaniu
	change_separator:
		call skip
		mov ah,byte ptr ds:[cmdline+si]
		mov byte ptr ds:[separator],ah
		inc si
		ret
	
	; procedura wczytuj�ca nazwy plik�w wej�ciowych
	input_files:
		call skip
		get_name:
			xor ah,ah ; zeruje rejestr ah
			mov ah,byte ptr ds:[cmdline+si]
			mov byte ptr ds:[in_files+di],ah ; zapisujemy nazwe do zmiennej in_files
			inc di
			inc si
			cmp si,cmdlength ; sprawdzamy, czy to koniec linii komend
			je end_name ; jesli tak, wracamy 
			mov ah,byte ptr ds:[cmdline+si]
			cmp ah,' ' ; sprawdzamy, czy to koniec nazwy pliku
			je end_name
			jmp get_name
		end_name:
			mov ah,0
			mov byte ptr ds:[in_files+di],ah ; wstawiamy 0 na koniec nazwy pliku, zeby korzystac z przerwan 3dh
			inc di
		ret
		
	; procedura wczytujaca nazwe pliku wyjsciowego
	output_file:
		call skip
		xor bx,bx ; zeruje bx, gdyz bede go uzywac do poruszania sie po zmiennej
		mov ah,byte ptr ds:[cmdline+si]
		get_output:
			mov byte ptr ds:[out_file+bx],ah ; zapisujemy nazwe do zmiennej in_files
			inc bx
			inc si
			mov	ah,byte ptr ds:[cmdline+si]
			cmp si,cmdlength ; sprawdzamy, czy to koniec linii komend
			je end_output ; jesli tak, wracamy 
			mov ah,byte ptr ds:[cmdline+si]
			cmp ah,' ' ; sprawdzamy, czy to koniec nazwy pliku
			jne get_output
		end_output:
			mov ah,0
			mov byte ptr ds:[out_file+bx],ah
		ret
			
	; procedura kopiujaca odpowiednie linie z plikow wejsciowych i zapisujaca w pliku wyjsciowym
	copy_line:
	fcreate out_file
		rows:
			mov in_copied,0 ; na poczatku kazdego wiersza ta zmienna wynosi 0
			xor si,si ; zerujemy, posluzy do przechodzenia po nazwach plikow
			copy: ; kopiowanie danego wiersza
				mov tmp,offset ds:[in_files] ; offset do nazwy pliku wejsciowego
				add tmp,si
				fopen tmp
				fpoint in_copied
				mov bx,in_copied
				mov ah,byte ptr ds:[bool_eof+bx]
				cmp ah,1 ; sprawdzamy, czy plik nie jest zakonczony
				je fended
				
				write_line:
					fread
					mov bx,in_copied
					cmp ax,0 ; sprawdzamy, czy plik zwrocil zero bajtow, jesli tak - koniec pliku
					jne not_ended
					add in_ended,1 ; jesli zakonczony, dodajemy 1 do liczby zakonczonych plikow
					mov byte ptr ds:[bool_eof+bx],1 ; zmieniamy flage oznaczajaca, ze plik sie zakonczyl
					jmp fended
					
					not_ended:
						mov bx,in_copied
						shl bx,1
						add word ptr ds:[pointerdx+bx],1 ; licznik pokazujacy, gdzie zaczynamy kolejnym razem
						jnc nthappened
						mov	ds:[pointerdx+bx],0				;	jesli nastapilo przeniesienie na CF to wyzeruj mniej znaczace 16 bit�w
						add	word ptr ds:[pointercx+bx],1		;	i zinkrementuj bardziej znaczace 16 bit�w
						
						nthappened:
						mov ah,byte ptr ds:[bufor] ; dla sprawdzenia, czy nie kolejna linia
						cmp ah,10
						je write_end
						cmp ah,13
						je write_end
						mov di,1
						fwrite bufor
						jmp write_line
				write_end:
					mov bx,in_copied
					shl bx,1
					add	word ptr ds:[pointerdx+bx],1
					jnc fended
					mov	ds:[pointerdx+bx],0				;	jesli nastapilo przeniesienie na CF to wyzeruj mniej znaczace 16 bit�w
					add	 word ptr ds:[pointercx+bx],1	;	i zinkrementuj bardziej znaczace 16 bit�w	
				fended:
					fclose in_handle
					add in_copied,1
					mov ax,in_copied
					cmp al,in_count
					jae stop_copying ; jesli skopiowano wiersze ze wszystkich plikow, skoncz kopiowanie
					mov di,1
					fwrite separator
				next_file:
					mov ah,byte ptr ds:[in_files+si] ; szukanie kolejnej nazwy pliku wejsciowego
					inc si
					cmp ah,0
					jne next_file
				jmp copy
			stop_copying:
				mov ds:[bufor],13
				fwrite bufor
				mov ds:[bufor],10
				fwrite bufor
			mov ah,in_ended
			cmp ah,in_count ; sprawdzamy, czy pliki zosta�y przerobione do ko�ca
			jne rows
			fclose out_handle
		ret
		
	; procedura kopiujaca odpowiednie linie z plikow wejsciowych i zapisujaca w pliku wyjsciowym
		copy_line_cons:
			rowsc:
				mov in_copied,0 ; na poczatku kazdego wiersza ta zmienna wynosi 0
				xor si,si ; zerujemy, posluzy do przechodzenia po nazwach plikow
				copyc: ; kopiowanie danego wiersza
					mov tmp,offset ds:[in_files] ; offset do nazwy pliku wejsciowego
					add tmp,si
					fopen tmp
					fpoint in_copied
					mov bx,in_copied
					mov ah,byte ptr ds:[bool_eof+bx]
					cmp ah,1 ; sprawdzamy, czy plik nie jest zakonczony
					je fendedc
					
					write_linec:
						fread
						mov bx,in_copied
						cmp ax,0 ; sprawdzamy, czy plik zwrocil zero bajtow, jesli tak - koniec pliku
						jne not_endedc
						add in_ended,1 ; jesli zakonczony, dodajemy 1 do liczby zakonczonych plikow
						mov byte ptr ds:[bool_eof+bx],1 ; zmieniamy flage oznaczajaca, ze plik sie zakonczyl
						jmp fendedc
						
						not_endedc:
							mov bx,in_copied
							shl bx,1
							add word ptr ds:[pointerdx+bx],1 ; licznik pokazujacy, gdzie zaczynamy kolejnym razem
							jnc nthappenedc
							mov	ds:[pointerdx+bx],0				;	jesli nastapilo przeniesienie na CF to wyzeruj mniej znaczace 16 bit�w
							add	word ptr ds:[pointercx+bx],1		;	i zinkrementuj bardziej znaczace 16 bit�w
							
							nthappenedc:
							mov ah,byte ptr ds:[bufor] ; dla sprawdzenia, czy nie kolejna linia
							cmp ah,10
							je write_endc
							cmp ah,13
							je write_endc
							mov di,1
							prints offset bufor
							jmp write_linec
					write_endc:
						mov bx,in_copied
						shl bx,1
						add	word ptr ds:[pointerdx+bx],1
						jnc fendedc
						mov	ds:[pointerdx+bx],0				;	jesli nastapilo przeniesienie na CF to wyzeruj mniej znaczace 16 bit�w
						add	 word ptr ds:[pointercx+bx],1	;	i zinkrementuj bardziej znaczace 16 bit�w	
					fendedc:
						fclose in_handle
						add in_copied,1
						mov ax,in_copied
						cmp al,in_count
						jae stop_copyingc ; jesli skopiowano wiersze ze wszystkich plikow, skoncz kopiowanie
						mov di,1
						prints offset separator
					next_filec:
						mov ah,byte ptr ds:[in_files+si] ; szukanie kolejnej nazwy pliku wejsciowego
						inc si
						cmp ah,0
						jne next_filec
					jmp copy
				stop_copyingc:
					prints offset newline
				mov ah,in_ended
				cmp ah,in_count ; sprawdzamy, czy pliki zosta�y przerobione do ko�ca
				jne rows
			ret
			
		
	; procedura konczaca program		
	exit:
		mov ax,04c00h ; zakonczenie programu
		int 21h
	
; ---- glowny program ----
start:
			mov ax,seg myStack ; inicjowanie stosu
			mov ss,ax
			mov ax,seg dane ; ustawienie segmentu danych
			mov ds,ax
			
			xor cx,cx ; zerowanie rejestru licznikowego
			
			;linia komend znajduje sie w es, jej dlugosc w es:[80h]
			mov cl,es:[80h] ; umieszczam dlugosc linii komend w rejestrze licznikowym
			cmp cl,0	; sprawdzam, czy linia komend nie jest pusta
			je bad_syntax_exc ; jesli jest, wyswietl komunikat bledu i zakoncz
			
			mov cmdlength,cx ; zachowuje dlugosc linii komend w zmiennej
			xor si,si ; zeruje rejestry si i ah
			xor ah,ah
			
		copy_cmd:  ; przepisz linie komend do zmiennej cmdline
			mov ah,es:[81h+si]
			mov byte ptr ds:[cmdline+si],ah
			inc si
			loop copy_cmd
			
			xor di,di ; ten rejestr posluzy do przemieszczania sie po zmiennej wejscia
			xor si,si ; ten rejestr posluzy do przemieszczania sie po zmiennej cmdline
			
		commandline: ; petla poruszajaca sie po cmdline
			xor al,al
			mov al,byte ptr ds:[cmdline+si] ; przenoszenie do akumulatora kolejnych znakow linii komend
			cmp al,'-' ; sprawdzam, czy zaczyna sie opcja
			je options ; skaczemy do obslugi opcji
			cmp al, ' ' ; porownuje ze spacja
			je next
			jmp bad_syntax_exc
				; obsluga opcji
			options:
				inc si ; przechodzimy na kolejny znak linii komend
				cmp si,cmdlength
				ja bad_syntax_exc ; jesli podano "-" na koncu linii komend, wyswietl blad skladni
				
				mov al, byte ptr ds:[cmdline+si] ; jaka opcja?
				cmp al,'h' ; -h wyswietla pomoc
				je display_help
			
				cmp al,'i' ; -i oznacza, ze podano po tym plik wejsciowy
				je parse_in
				
				cmp al,'o' ; -o oznacza, ze podano po tym plik wyjsciowy
				je parse_out
				
				cmp al,'t' ; -t oznacza, ze podany po tym znak to separator
				je parse_separator
				jmp bad_syntax_exc ; jesli podano cos innego, mamy bledne wywolanie
				
				parse_in:
				add in_count,1
				call input_files ; procedura zajmujaca sie zapisywaniem nazwy pliku do zmiennej wejscia
				jmp next
				
				parse_out:
				cmp bool_out,1 ; sprawdzam, czy podano juz wczesniej plik wyjsciowy
				je bad_syntax_exc ; pokaz blad skladni (wielokrotna opcja -o)
				mov bool_out,1 ; ustaw flage wyjscia na 1
				call output_file ; procedura zajmujaca sie wczytywaniem nazwy pliku wyjsciowego
				jmp next
				
				parse_separator:
				cmp separator,' '
				jne bad_syntax_exc ; blad, jesli chcemy zmienic separator drugi raz
				call change_separator
				jmp next
			; -- koniec obslugi opcji --
			
			next:
				inc si
				cmp si, cmdlength ; jesli nie doszlismy do konca linii komend, wracamy na poczatek procedury
				jbe commandline
				
			cmp in_count,0
			je no_input ; jesli nie podano plikow wejsciowych - wyswietl blad
			
			cmp bool_out,0
			je no_output
			call copy_line ; jesli podano plik wyjsciowy - wywolaj wersje zapisujaca do pliku
			jmp exit
			
			no_output:
			call copy_line_cons ; jesli nie podano pliku wyjsciowego - pokaz wynik w konsoli
			jmp exit
			

			
code ends
end start
			