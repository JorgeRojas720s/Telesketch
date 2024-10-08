.MODEL SMALL
.STACK 100H
;-----------------------------------
; SEGMENTO DE DATOS
;-----------------------------------

.DATA
    X DW 100      ; Coordenada inicial X
    Y DW 100      ; Coordenada inicial Y
    BG_COLOR DB 15 ; Color de fondo (negro)
    BTN_X DW 10   ; Coordenada X del botón
    BTN_Y DW 10  ; Coordenada Y del botón
    BTN_WIDTH DW 100   ; Ancho del botón
    BTN_HEIGHT DW 30   ;
    BTN_COLOR DB 4 ; Color del botón (rojo)
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

CLEAR_SCREEN:
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, BG_COLOR ; Color de fondo
    INT 10H         ; Dibujar píxel en (CX, DX) con color AL

    INC CX          ; Incrementar la coordenada X
    CMP CX, 350     ; ¿Llegamos al borde de la pantalla? (ancho de 320)
    JNE CONTINUE_CLEAR

    MOV CX, 0       ; Reiniciar X cuando lleguemos al borde
    INC DX          ; Mover a la siguiente fila
    CMP DX, 300     ; ¿Llegamos al fondo de la pantalla? (alto de 200)
    JNE CONTINUE_CLEAR

    JMP DONE_CLEAR   ; Si hemos limpiado la pantalla, salir

CONTINUE_CLEAR:
    JMP CLEAR_SCREEN ; Repetir hasta limpiar la pantalla

DONE_CLEAR:
    ; Esperar el clic izquierdo del ratón
    CALL DRAW_BUTTON
WAIT_FOR_CLICK:
    MOV AX, 3      ; Función para obtener estado del ratón
    INT 33H
    TEST BX, 1     ; Verificar si el botón izquierdo está presionado (bit 0)
    JZ WAIT_FOR_CLICK ; Si no está presionado, esperar

    ; Almacenar las coordenadas cuando se presiona el botón
    MOV [X], CX    ; Coordenada X del ratón
    MOV [Y], DX    ; Coordenada Y del ratón

  ; Dibujar el píxel en la posición (X, Y) con color verde
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, 4       ; Color rojo
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel

    ; Bucle para mover el píxel con las teclas de flecha
MOVE_PIXEL:
    ; Esperar por una tecla
    MOV AH, 00H
    INT 16H         ; Leer tecla presionada

    ; Comparar con las teclas de flecha
    CMP AL, 0       ; Verificar si es una tecla especial
    JNE EXIT_CHECK  ; Si no es tecla especial, salir

    ; Leer el segundo byte del código de tecla especial
    MOV AH, 00H
    INT 16H         ; Leer la segunda parte del código

    ; Revisar las teclas de flechas
    CMP AH, 48H     ; Flecha hacia arriba
    JE MOVE_UP
    CMP AH, 50H     ; Flecha hacia abajo
    JE MOVE_DOWN
    CMP AH, 4BH     ; Flecha hacia la izquierda
    JE MOVE_LEFT
    CMP AH, 4DH     ; Flecha hacia la derecha
    JE MOVE_RIGHT

EXIT_CHECK:
    JMP MOVE_PIXEL  ; Continuar moviendo

MOVE_UP:
    CMP [Y], 0      ; Verificar si estamos en el límite superior
    JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    DEC [Y]         ; Decrementar la coordenada Y
    JMP REDRAW_PIXEL

MOVE_DOWN:
    CMP [Y], 199    ; Verificar si estamos en el límite inferior
    JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    INC [Y]         ; Incrementar la coordenada Y
    JMP REDRAW_PIXEL

MOVE_LEFT:
    CMP [X], 0      ; Verificar si estamos en el límite izquierdo
    JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    DEC [X]         ; Decrementar la coordenada X
    JMP REDRAW_PIXEL

MOVE_RIGHT:
    CMP [X], 319    ; Verificar si estamos en el límite derecho
    JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    INC [X]         ; Incrementar la coordenada X
    JMP REDRAW_PIXEL

REDRAW_PIXEL:
    ; Limpiar el píxel anterior dibujando con el color de fondo
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, BG_COLOR ; Color de fondo
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel en la posición anterior

    ; Dibujar el nuevo píxel en la nueva posición
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, 4       ; Color rojo
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el nuevo píxel

    JMP MOVE_PIXEL   ; Continuar esperando por teclas

    ; Restaurar modo texto (modo 03h) antes de salir






;-----------------------------------
; Rutina para dibujar el botón
;-----------------------------------
; Rutina para dibujar el botón
DRAW_BUTTON PROC
    MOV CX, [BTN_X]         ; Coordenada X inicial del botón
    MOV DX, [BTN_Y]         ; Coordenada Y inicial del botón
    MOV AL, BTN_COLOR       ; Color del botón
    MOV AH, 0CH             ; Función para escribir píxel

DRAW_BUTTON_LOOP_ROW:
    MOV CX, [BTN_X]         ; Reiniciar la coordenada X para cada fila

DRAW_BUTTON_LOOP_COL:
    INT 10H                 ; Dibujar píxel en (CX, DX)
    INC CX                  ; Avanzar a la siguiente columna
    MOV AX, [BTN_X]
    ADD AX, [BTN_WIDTH]     ; Ancho del botón
    CMP CX, AX              ; ¿Llegamos al final de la fila?
    JG NEXT_ROW             ; Pasar a la siguiente fila si es así
    JMP DRAW_BUTTON_LOOP_COL; Si no, continuar en la fila

NEXT_ROW:
    INC DX                  ; Pasar a la siguiente fila
    MOV AX, [BTN_Y]
    ADD AX, [BTN_HEIGHT]    ; Alto del botón
    CMP DX, AX              ; ¿Llegamos al final del botón?
    JL DRAW_BUTTON_LOOP_ROW ; Si no, continuar dibujando
    RET                     ; Si sí, terminar el dibujo
DRAW_BUTTON ENDP




    
EXIT_PROGRAM:
    MOV AX, 0003H   ; Modo 03h = 80x25 texto
    INT 10H         ; Interrupción para cambiar modo de video

    ; Terminar el programa
    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN