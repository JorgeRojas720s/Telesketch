.MODEL SMALL
.STACK 100H
;-----------------------------------
; SEGMENTO DE DATOS
;-----------------------------------

.DATA
    X DW 100      ; Coordenada inicial X
    Y DW 100      ; Coordenada inicial Y

;-----------------------------------
; FINAL SEGMENTO DE DATOS
;-----------------------------------

.CODE
MAIN PROC FAR
    ; Configurar segmento de datos
    MOV AX, @DATA
    MOV DS, AX

    ; Establecer modo gráfico (modo 13h)
    MOV AX, 0013H   ; Modo 13h = 320x200 con 256 colores
    INT 10H         ; Interrupción para cambiar modo de video

    ; Llenar la pantalla con el color blanco (color 15)
    MOV CX, 0       ; Iniciar coordenada X en 0
    MOV DX, 0       ; Iniciar coordenada Y en 0
    MOV AL, 0Fh     ; Color blanco

FILL_SCREEN:
    MOV AH, 0CH     ; Función para escribir píxel
    INT 10H         ; Dibujar píxel en (CX, DX) con color AL

    INC CX          ; Incrementar la coordenada X
    CMP CX, 320     ; ¿Llegamos al borde de la pantalla? (ancho de 320)
    JNE CONTINUE_FILL

    MOV CX, 0       ; Reiniciar X cuando lleguemos al borde
    INC DX          ; Mover a la siguiente fila
    CMP DX, 200     ; ¿Llegamos al fondo de la pantalla? (alto de 200)
    JE DONE_FILL    ; Si es así, terminar el llenado

CONTINUE_FILL:
    JMP FILL_SCREEN ; Repetir el proceso hasta llenar la pantalla

DONE_FILL:

MOVE_PIXEL:
    ; Dibujar el píxel en la posición actual (X, Y) con color rojo
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, 4       ; Color rojo
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel

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
    JMP MOVE_PIXEL

MOVE_DOWN:
    CMP [Y], 199    ; Verificar si estamos en el límite inferior
    JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    INC [Y]         ; Incrementar la coordenada Y
    JMP MOVE_PIXEL

MOVE_LEFT:
    CMP [X], 0      ; Verificar si estamos en el límite izquierdo
    JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    DEC [X]         ; Decrementar la coordenada X
    JMP MOVE_PIXEL

MOVE_RIGHT:
    CMP [X], 319    ; Verificar si estamos en el límite derecho
    JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
    INC [X]         ; Incrementar la coordenada X
    JMP MOVE_PIXEL

    ; Restaurar modo texto (modo 03h) antes de salir
EXIT_PROGRAM:
    MOV AX, 0003H   ; Modo 03h = 80x25 texto
    INT 10H         ; Interrupción para cambiar modo de video

    ; Terminar el programa
    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN

;-----------------------------------
; SEGMENTO DE CODIGO
;-----------------------------------
