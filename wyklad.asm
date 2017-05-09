Dane1 segment
Db 10,4
Db 12
Tekst1 db "To jest napis$";dolar oznacza koniec bufora tekstu
Dane1 ends

Code1 segment
Start1: Mov ax, seg top1 ;etykieta
Mov ss, Ax
Mov sp, offset top1

Mov ax, seg tekst1
Mov ds, ax
Mov dx, offset tekst1

Mov ah, 9 ; wypisz na ekran to co jest w ds:dx // przerwania
Int 21h

Mov ah,4ch ; koniec I powrót do dosa
Int 21h
Code1 ends

Stos1 segment stack
Dw 200 dup(8)
Top1 dw ?
Stos1 ends

end
