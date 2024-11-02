.MODEL SMALL
.STACK 100H

;-----------------------------------
; SEGMENTO DE DATOS
;-----------------------------------
.DATA
    X DW 100                   ; Coordenada inicial X
    Y DW 100                   ; Coordenada inicial Y
    BG_COLOR DB 15             ; Color de fondo (blanco)
    CURRENT_COLOR DB 4         ; Color actual del píxel (inicialmente rojo)
    SCREEN_WIDTH EQU 640
    SCREEN_HEIGHT EQU 480
    SCREEN_BUFFER DB SCREEN_WIDTH * SCREEN_HEIGHT DUP(0)  ; Búfer para almacenar caracteres ASCII de cada píxel
    FILE_NAME DB "screen.txt", 0  
    ERROR_MSG DB 'Error al crear o escribir en el archivo.$'

    MSG	DB	'HOLA MUNDO$'
    FPIX	DW	0
    CPIX	DW	0


POS_CURSOR MACRO FIL, COL		;UN TIPO DE "METODO" QUE RECIBE 2 PARAMETROS
	MOV AH, 02H
	MOV BH, 00
	MOV DH, FIL
	MOV DL, COL
	INT 10H						;INTERRUPCION DE VIDEO
ENDM
;-----------------------------------
; FINAL SEGMENTO DE DATOS
;-----------------------------------

.CODE
MAIN PROC FAR
    ; Configurar segmento de datos
    MOV AX, @DATA
    MOV DS, AX

    CALL MODEVIDEO  ; Interrupción para cambiar modo de video
    
    MOV CPIX, 50D
    MOV FPIX, 30D
	CALL DRAWLINE_ROW	

    MOV CPIX, 50D
    MOV FPIX, 30D
	CALL DRAWLINE_COL

    MOV CPIX, 50D
	CALL DRAWLINE_ROW		;PINTAR UNA LINEA DE PIXELES EN LA POSICION FPIX Y CPIX

    MOV FPIX, 30D
	CALL DRAWLINE_COL

    CALL INIT_MOUSE

    POS_CURSOR 10, 8

    LEA	DX, MSG
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H

    ; ; Captura de pantalla
    ; CALL EXPORT_SCREEN_12H

WAIT_FOR_CLICK:
    CALL WAIT_FOR_MOUSE_CLICK
    ; Almacenar las coordenadas cuando se presiona el botón
    MOV [X], CX    ; Coordenada X del ratón
    MOV [Y], DX    ; Coordenada Y del ratón
    CALL DRAW_PIXEL ; Dibujar el píxel en la posición (X, Y) con color inicial
    CALL MOVE_PIXEL ; Iniciar el bucle para mover el píxel
MAIN ENDP

MODEVIDEO PROC
    ; Configurar modo de video 12h (640x480, 16 colores)
    MOV AH, 00H
    MOV AL, 12H
    INT 10H

    ; Establecer color de relleno a blanco (color 15)
    MOV AX, 0A000H        ; Dirección base del buffer de video en modo 12h
    MOV ES, AX            ; Guardar dirección base en segmento ES
    MOV DI, 0             ; Empezar desde el primer pixel

    MOV CX, 640 * 480 / 2 ; Número de palabras a escribir (cada palabra son 2 píxeles)
    MOV AX, 0FFFFH        ; 0F0F para que ambos píxeles sean blancos (color 15)

FILL_SCREEN:
    STOSW                 ; Almacenar palabra en la memoria (2 píxeles blancos)
    LOOP FILL_SCREEN      ; Repetir hasta llenar toda la pantalla
    RET
MODEVIDEO ENDP



DRAWLINE_ROW PROC NEAR
    MOV CX, 300
CICLO_ROW:
    PUSH CX
    MOV AL, 00H          ; Color negro (0) en lugar de 0AH
    MOV BX, 00
    MOV CX, CPIX
    MOV DX, FPIX
    MOV AH, 0CH
    INT 10H
    INC CPIX
    POP CX
    LOOP CICLO_ROW
    RET
DRAWLINE_ROW ENDP

DRAWLINE_COL PROC NEAR
    MOV CX, 300           ; Longitud de la línea
CICLO_COL:
    PUSH CX
    MOV AL, 00H          ; Color negro (0)
    MOV BX, 00           ; No se usa aquí, pero se puede dejar para consistencia
    MOV DX, FPIX         ; Guardamos la coordenada Y en DX
    MOV CX, CPIX         ; Guardamos la coordenada X en CX
    MOV AH, 0CH
    INT 10H              ; Dibuja el píxel en la posición (CPIX, FPIX)
    INC FPIX             ; Incrementa FPIX para mover hacia abajo (o decrementar para arriba)
    POP CX
    LOOP CICLO_COL           ; Repite para la longitud deseada
    RET
DRAWLINE_COL ENDP

INIT_MOUSE PROC
    MOV AX, 1
    INT 33H
    RET
INIT_MOUSE ENDP

WAIT_FOR_MOUSE_CLICK PROC
    MOV AX, 3      ; Función para obtener estado del ratón
    INT 33H
    TEST BX, 1     ; Verificar si el botón izquierdo está presionado (bit 0)
    JZ WAIT_FOR_MOUSE_CLICK ; Si no está presionado, esperar
    RET
WAIT_FOR_MOUSE_CLICK ENDP

DRAW_PIXEL PROC
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, [CURRENT_COLOR] ; Color actual
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel
    RET
DRAW_PIXEL ENDP

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
    ; Mostrar mensaje de error (opcional)
    MOV DX, OFFSET ERROR_MSG
    MOV AH, 09H
    INT 21H
    RET
WRITE_SCREEN_TO_FILE ENDP

MOVE_PIXEL PROC
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
    RET
MOVE_PIXEL ENDP

MOVEMENTS PROC
    MOVE_UP:
        CMP [Y], 31      ; Verificar si estamos en el límite superior
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [Y]         ; Decrementar la coordenada Y
        CALL REDRAW_PIXEL

    MOVE_DOWN:
        CMP [Y], 329    ; Verificar si estamos en el límite inferior
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [Y]         ; Incrementar la coordenada Y
        CALL REDRAW_PIXEL

    MOVE_LEFT:
        CMP [X], 51      ; Verificar si estamos en el límite izquierdo
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [X]         ; Decrementar la coordenada X
        CALL REDRAW_PIXEL

    MOVE_RIGHT:
        CMP [X], 349    ; Verificar si estamos en el límite derecho
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [X]         ; Incrementar la coordenada X
        CALL REDRAW_PIXEL
MOVEMENTS ENDP


REDRAW_PIXEL PROC
    ; Limpiar el píxel anterior dibujando con el color de fondo
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, BG_COLOR ; Color de fondo
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel en la posición anterior
    CALL DRAW_PIXEL ; Dibujar el nuevo píxel en la nueva posición
    JMP MOVE_PIXEL   ; Continuar esperando por teclas
REDRAW_PIXEL ENDP

CLEAR_SCREEN PROC
   
    MOV DX, 31       ; Reiniciar coordenada Y en 31

CLEAR_LOOP:
    MOV AH, 0CH      ; Función para escribir píxel
    MOV AL, BG_COLOR  ; Color de fondo
    INT 10H          ; Dibujar píxel en (CX, DX) con color AL

    INC CX           ; Incrementar la coordenada X
    CMP CX, 349      ; ¿Llegamos al borde de la pantalla?
    JAE NEXT_ROW     ; Si llegamos al borde, ir a la siguiente fila

    JMP CLEAR_LOOP   ; Volver al bucle para limpiar el píxel actual

NEXT_ROW:
    MOV CX, 51  
    INC DX           ; Mover a la siguiente fila
    CMP DX, 329      ; ¿Llegamos al fondo de la pantalla?
    JL CLEAR_LOOP    ; Si no hemos llegado al fondo, continuar

    ; Regresar al bucle de selección de nuevo punto
    JMP WAIT_FOR_CLICK 
CLEAR_SCREEN ENDP


EXPORT_SCREEN_12H PROC
    MOV AX, 0A000H            ; Dirección del segmento de video para modo 12h
    MOV ES, AX
    LEA DI, SCREEN_BUFFER     ; DI apunta al búfer de pantalla
    MOV CX, SCREEN_WIDTH * SCREEN_HEIGHT ; Número de píxeles en la pantalla

SAVE_SCREEN_LOOP_12H:
    MOV AL, [ES:DI]           ; Cargar el color del píxel actual en AL
    MOV [SCREEN_BUFFER], AL    ; Guardar en el búfer
    INC DI                    ; Siguiente posición en el búfer
    DEC CX                    ; Decrementar el contador
    JNZ SAVE_SCREEN_LOOP_12H  ; Repetir hasta que se haya guardado todo

    RET
EXPORT_SCREEN_12H ENDP

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
    MOV AX, 0003H                 ; Cambiar a texto
    INT 10H
    MOV AH, 4CH                   ; Terminar el programa
    INT 21H
    RET
EXIT_PROGRAM ENDP
; Final del segmento de código
END MAIN
