assume ds:data, ss:stack, cs:code

data segment

zero1 db "  ###  $"
zero2 db " #   # $"
zero3 db "#     #$"

one1  db "   #   $"
one2  db "  ##   $"
one3  db " # #   $"
one4  db " ##### $"

string db "data error$"
string2 db "i chuj/huj$"
liczba1 dw 0
dlugosc dw 0

posx  db 0;coordynaty wypisywanej liczby
posy  db 0

starty db 0

data ends

code segment

program:
    mov ax,data ;ladowanie danych do ds
    mov ds,ax
    mov ax,stack ;ladowanie stosu do ss
    mov ss,ax

    mov dx,offset string2
    mov ah,9
    int 21h

    xor ax,ax
    xor bx,bx ; zerowanie rejestrow
    xor cx,cx
        xor dx,dx
    ;read
read_loop:

    mov ah,1        ;wczytaj liczbe z klawiatury
    int 21h

    xor ah,ah
    mov bx,'0'
    cmp ax,bx
    jl read_loop

    mov bx,'9'
    cmp ax,bx
    jl data_1

    mov bx,'A'
    cmp ax,bx
    jl read_loop

    mov bx,'F'
    cmp ax,bx
    jl data_2

    mov bx,'a'
    cmp ax,bx
    jl read_loop

    mov bx, 'f'
    cmp ax,bx
    jl data_3

    cmp ax,bx
    jg read_loop

data_1:
    sub al,'0'
    xor ah,ah
    jmp data_end
data_2:
    sub al,'A'
    add al,10
    xor ah,ah
    jmp data_end
data_3:
    sub al,'a'
    add al,10
    xor ah,ah
data_end:

    mov liczba1,ax
    mov cx,4
    mov bx,2

loop_bin:
    div bx
    push dx
    xor dx,dx
    loop loop_bin
    ; napisz odczytywanie poczatkowej pozycji wskaznika

    mov ah,3
    int 10h

    add dh,2
    mov posx,dl
    mov starty,dh
    mov posy,dh

    mov cx,4
loop_print:
    pop ax
    ;if
    cmp ax,1
    jnz jump_to_0;ponizej wypisywanie 1
    call print1
    jmp end0

jump_to_0:;ponizej wypisywanie 0
    call print0
    end0:
    ;koniec if

    loop loop_print

    mov    ah,4ch  ; koniec i powrot do DOS
    int    21h

    ;wypisywanie zera
print0 proc
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero1
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero2
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero3
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero3
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero3
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero2
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset zero1
    mov ah,9
    int 21h

    mov ah,posy
    mov ah,starty
    mov posy,ah
    mov ah,posx
    add ah,7
    mov posx,ah
    xor ax,ax
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    ret

print0 endp


    ;wypisywanie jedynki
print1 proc
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one1
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one2
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one3
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one1
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one1
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one1
    mov ah,9
    int 21h

    mov ah,posy
    inc ah
    mov posy,ah
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    mov dx,offset one4
    mov ah,9
    int 21h

    mov ah,posy
    mov ah,starty
    mov posy,ah
    mov ah,posx
    add ah,7
    mov posx,ah
    xor ax,ax
    mov ah,2
    mov dh,posy
    mov dl,posx
    int 10h

    ret

print1 endp

code ends

stack segment stack

db 512 dup(0)

stack ends

end