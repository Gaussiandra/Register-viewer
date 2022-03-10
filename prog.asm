.186
.model tiny
.code
LOCALS
org 100h



start:

    mov ax, 1111h
    mov bx, 2222h
    mov cx, 3333h
    mov dx, 4444h

@@enter:

    in al, 60h            
    cmp al, 2
    jne @@enter       

    mov ax, 4ch
    int 21h

end start