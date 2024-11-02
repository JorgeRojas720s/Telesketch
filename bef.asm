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
    SCREEN_WIDTH EQU 640
    SCREEN_HEIGHT EQU 480
    SCREEN_BUFFER DB SCREEN_WIDTH * SCREEN_HEIGHT DUP(0)  ; Búfer para almacenar caracteres ASCII de cada píxel
    FILE_NAME DB "screen.txt", 0  

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

    ; Captura de pantalla
    CALL EXPORT_SCREEN_12H
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
 

 MOVE_PIXEL:
    ; Esperar por una tecla
    MOV AH, 00H
    INT 16H         ; Leer tecla presionada

    ; Revisar las acciones
    CMP AL, 'R'     ; Comprobar si se presionó 'R'
    JE CLEAR_SCREEN

    ; Comparar con las teclas de flecha
    CMP AL, 0H       ; Verificar si es una tecla especial
    CALL CHECK_COLORS  ; Si no es tecla especial, salir

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
    CMP CX, 640     ; ¿Llegamos al borde de la pantalla?
    JNE CLEAR_LOOP

    MOV CX, 0       ; Reiniciar X cuando lleguemos al borde
    INC DX          ; Mover a la siguiente fila
    CMP DX, 480     ; ¿Llegamos al fondo de la pantalla?
    JNE CLEAR_LOOP

    ; Regresar al bucle de selección de nuevo punto
    JMP WAIT_FOR_CLICK 
CLEAR_SCREEN ENDP

EXPORT_SCREEN_12H PROC
    MOV AX, 0A000H            ; Dirección del segmento de video para modo 12h
    MOV ES, AX
    LEA DI, SCREEN_BUFFER     ; DI apunta al búfer de pantalla

    MOV CX, 0                 ; Coordenada inicial X
    MOV DX, 0                 ; Coordenada inicial Y

SAVE_SCREEN_LOOP_12H:
    ; Configurar el registro para el puerto de selección de plano
    MOV DX, 03C4H             ; Puerto de selección de plano (sequencer)
    MOV AL, 2                 ; Selección del plano
    OUT DX, AL
    INC DX

    ; Leer píxel en cada plano y construir color
    MOV AL, 0                 ; Inicializar color del píxel en AL

    ; Leer plano 0
    MOV AL, 1                 ; Seleccionar plano 0
    OUT DX, AL
    MOV AL, ES:[BX]           ; Leer byte de plano
    OR [DI], AL               ; Almacenar en el búfer de pantalla

    ; Repetir para planos 1-3 y combinar en el color del píxel (similar para planos 1 a 3)
    ; Generar ASCII para cada color:
    ; Aquí decides el carácter a almacenar en base al color, por ejemplo, 
    ; MOV [DI], 'A' para el color 1, 'B' para el color 2, etc.

    ADD DI, 1                 ; Siguiente posición en el búfer

    ; Finaliza el bucle si se han recorrido todos los píxeles
    CMP DI, SCREEN_WIDTH * SCREEN_HEIGHT
    JNE SAVE_SCREEN_LOOP_12H

    RET
EXPORT_SCREEN_12H ENDP

WRITE_SCREEN_TO_FILE PROC
    ; Configuración del nombre y parámetros del archivo
    MOV AH, 3CH               ; Función DOS para crear un archivo
    MOV CX, 0                 ; Sin atributos
    LEA DX, FILE_NAME         ; Nombre del archivo
    INT 21H                   ; Crear el archivo
    JC FILE_ERROR             ; Saltar si hay error

    MOV BX, AX                ; Guardar manejador del archivo

    ; Escribir contenido del búfer en el archivo
    MOV CX, SCREEN_WIDTH * SCREEN_HEIGHT ; Número de bytes a escribir
    LEA DX, SCREEN_BUFFER     ; Dirección del búfer
    MOV AH, 40H               ; Función DOS para escribir en archivo
    INT 21H                   ; Llamar a la interrupción

    ; Cerrar el archivo
    MOV AH, 3EH               ; Función DOS para cerrar archivo
    INT 21H
    RET

FILE_ERROR:
    ; Manejo de errores (si es necesario)
    RET
WRITE_SCREEN_TO_FILE ENDP

CHECK_COLORS PROC
    CMP AL, 30H     
    JE CHANGE_COLOR_BLACK
    CMP AL, 31H     
    JE CHANGE_COLOR_BLUE
    CMP AL, 32H     
    JE CHANGE_COLOR_GREEN
    CMP AL, 33H     
    JE CHANGE_COLOR_RED
    CMP AL, 34H     
    JE CHANGE_COLOR_PURPLE
    CMP AL, 35H     
    JE CHANGE_COLOR_BROWN
    RET
CHECK_COLORS ENDP

; Procedimientos para cambio de color específico
CHANGE_COLOR_BLACK PROC
    MOV [CURRENT_COLOR], 0
    RET
CHANGE_COLOR_BLACK ENDP

CHANGE_COLOR_BLUE PROC
    MOV [CURRENT_COLOR], 1
    RET
CHANGE_COLOR_BLUE ENDP

CHANGE_COLOR_GREEN PROC
    MOV [CURRENT_COLOR], 2
    RET
CHANGE_COLOR_GREEN ENDP

CHANGE_COLOR_RED PROC
    MOV [CURRENT_COLOR], 4
    RET
CHANGE_COLOR_RED ENDP

CHANGE_COLOR_PURPLE PROC
    MOV [CURRENT_COLOR], 5
    RET
CHANGE_COLOR_PURPLE ENDP

CHANGE_COLOR_BROWN PROC
    MOV [CURRENT_COLOR], 6
    RET
CHANGE_COLOR_BROWN ENDP



EXIT_PROGRAM PROC
    MOV AX, 0003H   ; Modo 03h = 80x25 texto
    INT 10H         ; Interrupción para cambiar modo de video

    ; Terminar el programa
    MOV AH, 4CH
    INT 21H
EXIT_PROGRAM ENDP


END MAIN