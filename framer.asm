VIDEOSEG    = 0b800h
CMD_ARGS    = 82h
CMD_WIDTH   = 80
X1          = 152
Y1          = 1
X2          = 164
Y2          = 5
MAX_STR_LEN = 256
ITOA_MAX_STR = 4
STYLE_OFFSET = 6

BLUE        = 1
GREEN       = 2
CYAN        = 3
RED         = 4
MAGENTA     = 5
BROWN       = 6

;-----------------------------
; Draws frame with 4 registers
; Entry: DS:[SI] - style
; Destr: ES, DI, SI
; Note:  DF = 0
;-----------------------------
drawFrame   proc

            ; will be printed in reversed order
            push dx cx bx ax            

            mov ax, VIDEOSEG
            mov es, ax

            mov dx, Y2 - Y1
            mov cx, X2 - X1 - 3
            mov di, (CMD_WIDTH * Y1 + X1 - 4) * 2
            mov bx, offset frameName
            call drawFrame_
      
            ; set registers coords
            mov di, (CMD_WIDTH * (Y1 + 1) + X1 - 2) * 2
            mov ah, CYAN
            mov si, offset AxInfo
            mov cx, 4                   ; num of registers

@@printReg:
            pop bx
            call printRegs
            add di, 2 * CMD_WIDTH
            inc si 

            loop @@printReg

            ret
endp

;-----------------------------
; Draws entire frame wo registers
; Entry: DX - number of lines
;        CX - middle line length
;        DI - drawing addr
;        BX - addr of frame name
;        SI - drawing style addr
; Destr: AX, CX, DX, DI, SI, BX
; Note:  ES - videosegment
;        DF = 0
;-----------------------------
drawFrame_  proc
            call drawLine
            add si, 3                   ; points to middle top style
            
            ; print string on the frame
            push si
            push bx
            mov bl, [si]
            pop si
            add cx, 2
            call printString
            sub cx, 2
            pop si

            add di, 2 * CMD_WIDTH
            add si, 3                   ; 3 + 3 = STYLE_OFFSET

@@oneLine:
            call drawLine
            add di, 2 * CMD_WIDTH

            dec dx
            cmp dx, 0
            jne @@oneLine
            
            add si, STYLE_OFFSET
            call drawLine
            
            ret
endp

;-----------------------------
; Prints string near provided place
; Entry: DI - addr of start position of entire line
;        SI - addr of string to print
;        BL - string color attr
;        CX - length of entire place-line
; Destr: AX, SI, BX
;-----------------------------
printString proc

            push di
            push cx
            push bx

            push di
            mov di, si
            call strlen
            pop di

            ; calc di - mov position of string
            mov bx, ax                  ; ax - length of printing string
            shr bx, 1                  
            add di, cx
            sub di, ax                  ; name position on the frame
            sub di, 2
            or di, 1                    ; make videoseg filling correct

            ; mov string on the line
            pop bx
            xor cx, cx                  ; counter
@@printLetter:
            mov bh, [si]
            mov es:[di], bx
            
            add di, 2
            inc si
            inc cx
            cmp cx, ax
            jne @@printLetter

            pop cx
            pop di

            ret
endp

;-----------------------------
; Draws line in the frame
; Entry: CX - middle line length > 0
;        DI - drawing addr
;        SI - char+color addr to draw
; Destr: AX
; Note:  DF = 0
;        ES - videosegment
;-----------------------------
drawLine    proc

            push cx
            push di
            push si

            lodsw               ; AX = *SI, SI += 2
            stosw               ; ES:[DI] = AX, DI += 2
            lodsw
            rep stosw
            lodsw
            stosw

            pop si
            pop di
            pop cx

            ret
endp

;-----------------------------
; Entry: DI - print coord
;        ES - videoseg
;        SI - Reg str
;        AH - color
;        BX - register to print
; Destr: SI
;-----------------------------
printRegs   proc

            push di cx bx

            push di ax
            mov di, si
            call strlen
            mov cx, ax
            pop ax di

@@regEq:
            lodsb
            stosw
            loop @@regEq
            
            push si
            mov si, offset itoaStr
            call itoa16

            mov cx, 4
@@regValue:  
            lodsb
            stosw
            loop @@regValue

            pop si bx cx di

            ret
endp

;-----------------------------
; Converts BX to hex with leading 0 (up to 4)
; Entry: BX - reg to convert
; Ret:   CS:SI - converted str
; Note:  DF = 0
; Destr: None
;-----------------------------
itoa16      proc

            push ax bx cx dx di si

            mov cx, 4
            add si, cx
            dec si

@@convert:
            ; dx - rem
            mov dx, bx
            shr bx, 4
            shl bx, 4
            sub dx, bx
            shr bx, 4

            add dx, offset xlatTable
            mov di, dx
            mov al, cs:[di]
            mov cs:[si], al
            dec si

            loop @@convert

            pop si di dx cx bx ax  

            ret  

endp

;-----------------------------
; Find length of string
; Entry: DI - addr of string
; Ret:   AX - strlen
; Destr: DI, AX
; Note:  DF = 0
;-----------------------------
strlen      proc

            push cx
            push es

            mov ax, ds
            mov es, ax
            mov cx, MAX_STR_LEN

            xor ax, ax
            mov al, '$'

            repne scasb
            mov ax, MAX_STR_LEN
            sub ax, cx
            dec ax

            pop es
            pop cx

            ret
endp

;-----------------------------
; Wait some time...
;-----------------------------
sleep       proc

            push ax
            push cx
            push dx

            xor ax, ax
            mov ah, 86h
            xor cx, cx
            mov dx, 0FFFh
            int 15h

            pop dx
            pop cx
            pop ax

            ret 
endp

.data
AxInfo:       db 'AX=$'
BxInfo:       db 'BX=$'
CxInfo:       db 'CX=$'
DxInfo:       db 'DX=$'

itoaStr:      db ITOA_MAX_STR dup(0), '$'
xlatTable:    db '0123456789ABCDEF'

argErrorMsg:  db 'Unknown arguments$'
frameName:    db 'Viewer$'

doubleStyle:  db 201, BROWN, 205, GREEN, 187, BROWN
              db 186, GREEN, 0,   0,     186, GREEN
              db 200, BROWN, 205, GREEN, 188, BROWN, '$'

singleStyle:  db 3,   BROWN, 196, GREEN, 3,   BROWN
              db 179, GREEN, 0,   0,     179, GREEN
              db 3,   BROWN, 196, GREEN, 3,   BROWN, '$'

cringeStyle:  db '+', CYAN,  196, BROWN, '+', RED
              db 179, GREEN, 0,   0,     179, GREEN
              db '+', BLUE,  196, RED,   '+', MAGENTA, '$'