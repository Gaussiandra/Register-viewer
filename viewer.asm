.186
.model tiny
.code
LOCALS
org 100h

VIDEOSEG    = 0b800h
CMD_WIDTH   = 80
INSERT_CODE = 82

start:
            xor di, di
            mov es, di

            ; int 08h
            cli
            mov di, 08h * 4             
            mov ax, es:[di]
            mov word ptr Old08Off, ax
            mov ax, es:[di + 2]
            mov word ptr Old08Seg, ax

            mov word ptr es:[di], offset wrapInt08
            mov ax, cs
            mov word ptr es:[di + 2], ax 

            ; int 09h
            mov di, 09h * 4
            mov ax, es:[di]
            mov word ptr Old09Off, ax
            mov ax, es:[di + 2]
            mov word ptr Old09Seg, ax

            mov word ptr es:[di], offset wrapInt09
            mov ax, cs
            mov word ptr es:[di + 2], ax 
            sti

            ; TSR
            mov ax, 3100h
            mov dx, offset EOP
            shr dx, 4
            inc dx                      ; control potential reminder

            int 21h

wrapInt08   proc
    
            push bx cx dx di si ds es ax
    
            mov di, offset printFlag
            mov al, cs:[di]
            cmp al, 0
            je @@intExit

            mov ax, cs
            mov ds, ax
            mov si, offset singleStyle
            pop ax
            push ax
            
            call drawFrame

@@intExit:
            pop ax es ds si di dx cx bx 

            db 0EAh                     ; iret
Old08Off:   dw 0
Old08Seg:   dw 0

endp

wrapInt09   proc

            push ax di

            in al, 60h                  ; keyboard port
            cmp al, INSERT_CODE
            jne @@intExit        

            mov di, offset printFlag
            not byte ptr cs:[di]

@@intExit:
            pop di ax

            db 0EAh                     ; iret
old09Off:   dw 0
old09Seg:   dw 0
printFlag:  db 0
endp

include framer.asm

EOP:
end start