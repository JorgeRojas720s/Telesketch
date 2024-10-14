.MODEL SMALL
.STACK 100H
;-----------------------------------
; SEGMENTO DE DATOS
;-----------------------------------

.DATA
    X DW 100      ; Coordenada inicial X
    Y DW 100      ; Coordenada inicial Y
    BG_COLOR DB 15 ; Color de fondo (blanco)
    CURRENT_COLOR DB 4 ; Color actual del píxel (inicialmente rojo)

;-----------------------------------
; FINAL SEGMENTO DE DATOS
;-----------------------------------

.CODE
MAIN PROC FAR
    ; Configurar segmento de datos
    MOV AX, @DATA
    MOV DS, AX

    ; Establecer modo gráfico (modo 13h)
    MOV AX, 0012H   ; Modo 13h = 320x200 con 256 colores
    INT 10H         ; Interrupción para cambiar modo de video

    ; Inicializar el ratón
    MOV AX, 1
    INT 33H
    
    ; Limpiar la pantalla y establecer color de fondo
    MOV AX, 0       ; Color de fondo (negro)
    MOV CX, 0       ; Reiniciar coordenada X
    MOV DX, 0       ; Reiniciar coordenada Y
    CALL CLEAR_SCREEN

WAIT_FOR_CLICK:
    MOV AX, 3      ; Función para obtener estado del ratón
    INT 33H
    TEST BX, 1     ; Verificar si el botón izquierdo está presionado (bit 0)
    JZ WAIT_FOR_CLICK ; Si no está presionado, esperar

    ; Almacenar las coordenadas cuando se presiona el botón
    MOV [X], CX    ; Coordenada X del ratón
    MOV [Y], DX    ; Coordenada Y del ratón

    ; Dibujar el píxel en la posición (X, Y) con color inicial
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, [CURRENT_COLOR] ; Color actual
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel

    ; Bucle para mover el píxel con las teclas de flecha
 
CHECK_COLORS:
    ; Revisar los colores
    CMP AL, 30H     ; Número 0
    JE CHANGE_COLOR_BLACK
    CMP AL, 31H     ; Número 1
    JE CHANGE_COLOR_BLUE
    CMP AL, 32H     ; Número 2
    JE CHANGE_COLOR_GREEN
    CMP AL, 33H     ; Número 3
    JE CHANGE_COLOR_RED
    CMP AL, 34H     ; Número 4
    JE CHANGE_COLOR_PURPLE
    CMP AL, 35H     ; Número 5
    JE CHANGE_COLOR_BROWN
 
 ;--------Cambio de color-----------

CHANGE_COLOR_BLACK:
    MOV [CURRENT_COLOR], 0 ; Negro
    JMP MOVE_PIXEL

CHANGE_COLOR_BLUE:
    MOV [CURRENT_COLOR], 1 ; Azul
    JMP MOVE_PIXEL

CHANGE_COLOR_GREEN:
    MOV [CURRENT_COLOR], 2 ; Verde
    JMP MOVE_PIXEL

CHANGE_COLOR_RED:
    MOV [CURRENT_COLOR], 4 ; Rojo
    JMP MOVE_PIXEL

CHANGE_COLOR_PURPLE:
    MOV [CURRENT_COLOR], 5 ; Púrpura
    JMP MOVE_PIXEL

CHANGE_COLOR_BROWN:
    MOV [CURRENT_COLOR], 6 ; Marrón
    JMP MOVE_PIXEL

 MOVE_PIXEL:
    ; Esperar por una tecla
    MOV AH, 00H
    INT 16H         ; Leer tecla presionada

    ; Revisar las acciones
    CMP AL, 'R'     ; Comprobar si se presionó 'R'
    JE CLEAR_SCREEN

    ; Comparar con las teclas de flecha
    CMP AL, 0H       ; Verificar si es una tecla especial
    JNE CHECK_COLORS  ; Si no es tecla especial, salir

    ; Revisar las teclas de flechas
    CMP AH, 48H     ; Flecha hacia arriba
    JE MOVE_UP
    CMP AH, 50H     ; Flecha hacia abajo
    JE MOVE_DOWN
    CMP AH, 4BH     ; Flecha hacia la izquierda
    JE MOVE_LEFT
    CMP AH, 4DH     ; Flecha hacia la derecha
    JE MOVE_RIGHT
   
    CALL MOVEMENTS
    CALL REDRAW_PIXEL
    CALL EXIT_PROGRAM
MAIN ENDP

REDRAW_PIXEL PROC
    ; Limpiar el píxel anterior dibujando con el color de fondo
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, BG_COLOR ; Color de fondo
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel en la posición anterior

    ; Dibujar el nuevo píxel en la nueva posición
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, [CURRENT_COLOR] ; Color actual
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el nuevo píxel

    JMP MOVE_PIXEL   ; Continuar esperando por teclas
REDRAW_PIXEL ENDP
MOVEMENTS PROC
    MOVE_UP:
        CMP [Y], 0      ; Verificar si estamos en el límite superior
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [Y]         ; Decrementar la coordenada Y
        CALL REDRAW_PIXEL

    MOVE_DOWN:
        CMP [Y], 199    ; Verificar si estamos en el límite inferior
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [Y]         ; Incrementar la coordenada Y
        CALL REDRAW_PIXEL

    MOVE_LEFT:
        CMP [X], 0      ; Verificar si estamos en el límite izquierdo
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [X]         ; Decrementar la coordenada X
        CALL REDRAW_PIXEL

    MOVE_RIGHT:
        CMP [X], 319    ; Verificar si estamos en el límite derecho
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [X]         ; Incrementar la coordenada X
        CALL REDRAW_PIXEL
MOVEMENTS ENDP
CLEAR_SCREEN PROC
    ; Limpiar toda la pantalla
    MOV CX, 0       ; Reiniciar coordenada X
    MOV DX, 0       ; Reiniciar coordenada Y

CLEAR_LOOP:
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, BG_COLOR ; Color de fondo
    INT 10H         ; Dibujar píxel en (CX, DX) con color AL

    INC CX          ; Incrementar la coordenada X
    CMP CX, 320     ; ¿Llegamos al borde de la pantalla?
    JNE CLEAR_LOOP

    MOV CX, 0       ; Reiniciar X cuando lleguemos al borde
    INC DX          ; Mover a la siguiente fila
    CMP DX, 200     ; ¿Llegamos al fondo de la pantalla?
    JNE CLEAR_LOOP

    ; Regresar al bucle de selección de nuevo punto
    JMP WAIT_FOR_CLICK 
CLEAR_SCREEN ENDP


EXIT_PROGRAM PROC
    MOV AX, 0003H   ; Modo 03h = 80x25 texto
    INT 10H         ; Interrupción para cambiar modo de video

    ; Terminar el programa
    MOV AH, 4CH
    INT 21H
EXIT_PROGRAM ENDP


END MAIN
