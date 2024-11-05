.MODEL SMALL
.STACK 100H

;-----------------------------------
; SEGMENTO DE DATOS
;-----------------------------------
.DATA
;-----------------------------------
; VARIABLES GENERALES
;-----------------------------------
    X DW 100                   ; Coordenada inicial X
    Y DW 100                   ; Coordenada inicial Y
    SCREEN_WIDTH EQU 640       ; Tamaño del ancho de la pantalla
    SCREEN_HEIGHT EQU 480      ; Tamaño del largo de la pantalla
    BG_COLOR DB 15             ; Color de fondo (blanco)
    HELLO	DB	'Telesketch$'
    FPIX	DW	0
    CPIX	DW	0
    BLACK DB '0.$'
    BLUE DB '1.$'
    GREEN DB '2.$'
    RED DB '3.$'
    PURPLE DB '4.$'
    BROWN DB '5.$'
    SAVE_FILE DB 's = Save$'
    EXIT DB 'e = Exit$'
    CLEAR DB 'r = Clear$'
    LOAD DB 'c + click = Load File$'
;-----------------------------------
; VARIABLES PARA VIDEO
;-----------------------------------
    CURRENT_COLOR DB 4         ; Color actual del píxel (inicialmente rojo)
    SCREEN_BUFFER DB SCREEN_WIDTH * SCREEN_HEIGHT DUP(0)  ; Búfer para almacenar caracteres ASCII de cada píxel
;-----------------------------------
; VARIABLES PARA GUARDAR EN EL ARCHIVO
;-----------------------------------
    BUFFER DB 20000 DUP(0)                   ; Buffer para almacenar datos
    ERROR_MSG DB 'Error al crear el archivo: $', 0
    WRITE_ERROR_MSG DB 'NO SE PUO ESCRIBIR', 0
    SUCCESS_MSG DB 'SHI SE PUDO', 0
    FILE_NAME DB "salida.TXT", 0  
    MESSAGE_USER_INPUT DB 'Ingrese el nombre del archivo: $'
    ;FILE_NAME DB 20 DUP('$')
;-----------------------------------
; VARIABLES PARA MANEJAR EN EL ARCHIVO
;-----------------------------------
    FILE_HANDLE DW ?              ; Variable para almacenar el manejador del archivo
    TEMP_COLOR DB ?               ; Variable temporal para almacenar el color del píxel
    TEMP_CHAR DB ?              
    TEMP_CHAR_AUX DB ?
;-----------------------------------
; MACRO PARA EL CURSOR
;-----------------------------------
    POS_CURSOR MACRO FIL, COL		;UN TIPO DE "METODO" QUE RECIBE 2 PARAMETROS
        MOV AH, 02H
        MOV BH, 00
        MOV DH, FIL
        MOV DL, COL
        INT 10H						;INTERRUPCION DE VIDEO
    ENDM
;-----------------------------------
; MAIN
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

    POS_CURSOR 0, 20

    LEA	DX, HELLO
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_COLORS

    WAIT_FOR_CLICK:
        CALL WAIT_FOR_MOUSE_CLICK
        ; Almacenar las coordenadas cuando se presiona el botón
        MOV [X], CX    ; Coordenada X del ratón
        MOV [Y], DX    ; Coordenada Y del ratón
        CALL DRAW_PIXEL ; Dibujar el píxel en la posición (X, Y) con color inicial
        CALL MOVE_PIXEL ; Iniciar el bucle para mover el píxel
MAIN ENDP
;-----------------------------------
; FUNCIÓN PARA CAMBIAR A MODO VIDEO
;-----------------------------------
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
;-----------------------------------
; FUNCIÓN PARA DIBUJAR UNA LÍNEA EN ROW
;-----------------------------------
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
;-----------------------------------
; FUNCIÓN PARA DIBUJAR UNA LÍNEA EN COL
;-----------------------------------
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
;-----------------------------------
; INICIALIZA EL MOUSE
;-----------------------------------
INIT_MOUSE PROC
    MOV AX, 1
    INT 33H
    RET
INIT_MOUSE ENDP
;-----------------------------------
; FUNCIÓN PARA ESPERAR UN CLICK
;-----------------------------------
WAIT_FOR_MOUSE_CLICK PROC
    MOV AX, 3      ; Función para obtener estado del ratón
    INT 33H
    TEST BX, 1     ; Verificar si el botón izquierdo está presionado (bit 0)
    JZ WAIT_FOR_MOUSE_CLICK ; Si no está presionado, esperar
    RET
WAIT_FOR_MOUSE_CLICK ENDP
;-----------------------------------
; FUNCIÓN PARA DIBUJAR UN PIXEL
;-----------------------------------
DRAW_PIXEL PROC
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, [CURRENT_COLOR] ; Color actual
    MOV CX, [X]     ; Coordenada X
    MOV DX, [Y]     ; Coordenada Y
    INT 10H         ; Dibujar el píxel
    RET
DRAW_PIXEL ENDP
;-----------------------------------
; FUNCIÓN PARA GUARDAR EN ARCHIVO
;-----------------------------------

WRITE_SCREEN_TO_FILE PROC
    ;CALL SET_TEXT_MODE
    ;CALL ASK_FILE_NAME
    ; Crear archivo
    MOV AH, 3CH               ; Función DOS para crear archivo
    MOV CX, 0                 ; Sin atributos
    LEA DX, FILE_NAME         ; Dirección del nombre del archivo
    INT 21H
    JC FILE_ERROR             ; Salta si hubo error al crear

    MOV BX, AX                ; Guardar el manejador del archivo en BX
    MOV FILE_HANDLE, BX       ; Almacenar el manejador en FILE_HANDLE

    MOV DI, 51
    MOV SI, 31
  
    SAVE_PIXELS:
        ; Leer el color del píxel en (CX, DX)
        MOV AH, 0DH               ; Función para leer el color de un píxel
        ; Coordenadas iniciales
        MOV CX, DI                 ; X inicial
        MOV DX, SI                 ; Y inicial
        INT 10H                   ; Llamada a la BIOS, color en AL

    CALL CHECK_COLORS_IN_AL

    WritePixel:
        ; Escribir el carácter en el archivo
        MOV BX, FILE_HANDLE       ; Manejador del archivo
        MOV AH, 40H               ; Función DOS para escribir en archivo
        LEA DX, TEMP_CHAR         ; Dirección del carácter a escribir
        MOV CX, 1                 ; Longitud de los datos (1 byte)
        INT 21H                   ; Escribir carácter en archivo

        ; Avanzar al siguiente píxel
        INC DI                    ; Incrementar X
        CMP DI, 348
        JE .WriteX
        CMP DI, 348             ; Limitar ancho máximo (640)
        JBE ContinueX           

        MOV DI, 51                 ; Reiniciar X a la posición inicial en nueva fila
        INC SI                    ; Incrementar Y
        CMP SI, 328               ; Limitar altura máxima (480)
        JBE SAVE_PIXELS        

        JMP EndSave              ; Terminar si se excede la altura
    .WriteX:
        MOV TEMP_CHAR, 0AH
        JMP WritePixel
    ContinueX:
        JMP SAVE_PIXELS           ; Leer el siguiente píxel

    EndSave:
        ; Cerrar archivo
        MOV BX, FILE_HANDLE       ; Manejador del archivo
        MOV AH, 3EH               ; Función DOS para cerrar archivo
        INT 21H
        RET

    FILE_ERROR:
        MOV DX, OFFSET ERROR_MSG        ; Mostrar mensaje de error
        MOV AH, 09H
        INT 21H
        LEA DX, FILE_NAME
        MOV AH, 09H
        INT 21H
        RET

WRITE_SCREEN_TO_FILE ENDP


WRITE_SCREEN_TO_FILE_AUX PROC
    CALL WRITE_SCREEN_TO_FILE
    RET
WRITE_SCREEN_TO_FILE_AUX ENDP

LOAD_FILE PROC
     ; Abrir archivo
    MOV AH, 3DH               ; Función DOS para abrir archivo
    MOV AL, 00H               ; Modo de acceso: solo lectura
    LEA DX, FILE_NAME         ; Dirección del nombre del archivo
    INT 21H
    JC FILE_ERROR_L            ; Saltar si hubo error al abrir el archivo
    MOV FILE_HANDLE, AX       ; Almacenar el manejador del archivo

    ; Inicializar coordenadas
    MOV DI, 51                ; X inicial
    MOV SI, 31                ; Y inicial

    READ_PIXELS:
        ; Leer un byte del archivo
        MOV AH, 3FH               ; Función DOS para leer de archivo
        MOV BX, FILE_HANDLE       ; Manejador del archivo
        LEA DX, TEMP_CHAR_AUX     ; Dirección para almacenar el byte leído
        MOV CX, 1                 ; Leer un byte
        INT 21H                   ; Leer del archivo

        ; Verificar si se alcanzó el fin del archivo
        OR AX, AX                 ; Si AX es 0, se ha llegado al final del archivo
        JZ END_LOAD               ; Si AX = 0, saltar a END_LOAD para cerrar el archivo

        ; Comprobar el carácter leído
        MOV AL, TEMP_CHAR_AUX     ; Cargar el carácter leído en AL
        CMP AL, 0AH
        JE .NextRow
        CALL CHECK_COLORS_FOR_LOAD_FILE
        JMP .DrawPixel
        JMP .Continue             ; Si no es ni 'F' ni '0', saltar a continuar

    .DrawPixel:
        ; Mostrar el píxel en la pantalla con el color correspondiente en AL
        MOV CX, DI                ; X
        MOV DX, SI                ; Y
        MOV AH, 0CH               ; Función para escribir píxel (en modo gráfico)
        INT 10H                   ; Llamada a BIOS para dibujar el píxel

    .Continue:
        ; Actualizar las coordenadas para el siguiente píxel
        INC DI                    ; Incrementar X        
        JMP READ_PIXELS           ; Continuar leyendo píxeles

    .NextRow:
        MOV DI, 51                ; Reiniciar X a la posición inicial en nueva fila
        INC SI                    ; Incrementar Y
        CMP SI, 328               ; Limitar altura máxima (480)
        JBE READ_PIXELS           ; Si SI <= 480, continuar

    END_LOAD:
        ; Cerrar archivo y terminar el procedimiento
        MOV BX, FILE_HANDLE       ; Manejador del archivo
        MOV AH, 3EH               ; Función DOS para cerrar archivo
        INT 21H
        JMP MOVE_PIXEL
        RET

    FILE_ERROR_L:
        ; Manejo de error al abrir archivo
        MOV AH, 09H
        LEA DX, MESSAGE_USER_INPUT
        INT 21H
        RET
LOAD_FILE ENDP
;-----------------------------------
; FUNCIÓN PARA MOVER UN PIXEL
;-----------------------------------
MOVE_PIXEL PROC
    ; Esperar por una tecla
    MOV AH, 00H
    INT 16H         ; Leer tecla presionada

    CMP AL, 'c'
    JE LOAD_FILE
    CMP AL, 's'
    JE WRITE_SCREEN_TO_FILE_AUX
    ; Revisar las acciones
    CMP AL, 'r'     ; Comprobar si se presionó 'R'
    JE CLEAR_SCREEN
    CMP AL, 'e'
    JE END_PROGRAM

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
;-----------------------------------
; ETIQUETA AUXILIAR PARA CERRAR
;-----------------------------------
END_PROGRAM:
    CALL EXIT_PROGRAM
;-----------------------------------
; FUNCIÓN PARA VERIFICAR EL MOVIMIENTO
;-----------------------------------
MOVEMENTS PROC
    MOVE_UP:
        CMP [Y], 32      ; Verificar si estamos en el límite superior
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [Y]         ; Decrementar la coordenada Y
        CALL REDRAW_PIXEL

    MOVE_DOWN:
        CMP [Y], 328    ; Verificar si estamos en el límite inferior
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [Y]         ; Incrementar la coordenada Y
        CALL REDRAW_PIXEL

    MOVE_LEFT:
        CMP [X], 52      ; Verificar si estamos en el límite izquierdo
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [X]         
        CALL REDRAW_PIXEL

    MOVE_RIGHT:
        CMP [X], 348    ; Verificar si estamos en el límite derecho
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [X]         ; Incrementar la coordenada X
        CALL REDRAW_PIXEL
MOVEMENTS ENDP
;-----------------------------------
; FUNCIÓN PARA REDIBUJAR UN PIXEL
;-----------------------------------
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
;-----------------------------------
; FUNCIÓN PARA LIMPIAR EL ÁRE DE 
; TRABAJO
;-----------------------------------
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
;-----------------------------------
; FUNCIÓN PARA VERIFICAR LOS COLORES
;-----------------------------------
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
;-----------------------------------
; FUNCIONES PARA CAMBIAR LOS COLORES
;-----------------------------------
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
;-----------------------------------
; FUNCIÓN PARA VERIFICAR EL COLOR EN 
; AL
;-----------------------------------
CHECK_COLORS_IN_AL PROC
    CMP AL, 0                ; Negro
    JE WriteBlack
    CMP AL, 1                ; Azul
    JE WriteBlue
    CMP AL, 2                ; Verde
    JE WriteGreen
    CMP AL, 4                ; Rojo
    JE WriteRed
    CMP AL, 5                ; Púrpura
    JE WritePurple
    CMP AL, 6                ; Marrón
    JE WriteBrown
    CMP AL, 15               ; Blanco
    JE WriteWhite
    JMP BACKTOCONTINUEX            ; Si no coincide, continúa

    WriteBlack:
        MOV TEMP_CHAR, '0'       ; Representación para color negro
        RET

    WriteBlue:
        MOV TEMP_CHAR, '1'       ; Representación para color azul
        RET

    WriteGreen:
        MOV TEMP_CHAR, '2'       ; Representación para color verde
        RET

    WriteRed:
        MOV TEMP_CHAR, '4'       ; Representación para color rojo
        RET

    WritePurple:
        MOV TEMP_CHAR, '5'       ; Representación para color púrpura
        RET

    WriteBrown:
        MOV TEMP_CHAR, '6'       ; Representación para color marrón
        RET

    WriteWhite:
        MOV TEMP_CHAR, 'F'       ; Representación para color blanco
        RET
    BACKTOCONTINUEX:
        RET
CHECK_COLORS_IN_AL ENDP
;-----------------------------------
; FUNCIÓN PARA CAMBIAR A MODO TEXTO
;-----------------------------------
SET_TEXT_MODE PROC
    MOV AX, 0003H    ; Modo 03h: modo de texto de 80x25 caracteres
    INT 10H          ; Llamada a la interrupción de BIOS para cambiar el modo de video
    RET
SET_TEXT_MODE ENDP
;-----------------------------------
; FUNCIÓN PARA SOLICITAR EL NOMBRE
; DEL ARCHIVO (NO UTILIZADA)
;-----------------------------------
ASK_FILE_NAME PROC
    MOV AH, 09H
    LEA DX, MESSAGE_USER_INPUT
    INT 21H

    LEA DX, FILE_NAME
    MOV AH, 0AH
    INT 21H

    MOV SI, CX               ; Copia el tamaño de la cadena a SI
    MOV BYTE PTR FILE_NAME[SI], 0   ; Agrega el carácter nulo al final del nombre
    RET
ASK_FILE_NAME ENDP
;-----------------------------------
; FUNCIÓN PARA DIBUJAR LOS COLORES AL
; LADO DEL ÁREA DE TRABAJP
;-----------------------------------
DRAW_COLORS PROC

    POS_CURSOR 3, 60
    LEA	DX, BLACK
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_BLACK_SQUARE
    
    POS_CURSOR 6, 60
    LEA	DX, BLUE
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_BLUE_SQUARE

    POS_CURSOR 9, 60
    LEA	DX, GREEN
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_GREEN_SQUARE

    POS_CURSOR 12, 60
    LEA	DX, RED
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_RED_SQUARE

    POS_CURSOR 15, 60
    LEA	DX, PURPLE
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_PURPLE_SQUARE

    POS_CURSOR 18, 60
    LEA	DX, BROWN
	MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTERES
	INT	21H
    CALL DRAW_BROWN_SQUARE

    POS_CURSOR 22, 10
    LEA	DX, SAVE_FILE
    MOV	AH, 9H		;VISUALIZACION CADENA DE CARACTER
    INT	21H

    POS_CURSOR 22, 25
    LEA DX, EXIT
    MOV AH, 9H		;VISUALIZACION CADENA DE CARACTER
    INT 21H

    POS_CURSOR 25, 10
    LEA DX, CLEAR
    MOV AH, 9H
    INT 21H

    POS_CURSOR 25, 25
    LEA DX, LOAD
    MOV AH, 9H
    INT 21H
    
    RET
DRAW_COLORS ENDP
;-----------------------------------
; FUNCIONES PARA DIBUJAR LOS CUADRITOS
; DE COLORES
;-----------------------------------
DRAW_BLACK_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 500          ; Establece la posición X
        MOV DX, 48          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        BLACK_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            BLACK_COLUMN_LOOP:
                MOV AL, 0 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        ; Incrementa la posición X
                DEC BX        ; Decrementa el contador de píxeles
                JNZ BLACK_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 500      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ BLACK_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_BLACK_SQUARE ENDP
DRAW_BLUE_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 500          ; Establece la posición X
        MOV DX, 96          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        BLUE_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            BLUE_COLUMN_LOOP:
                MOV AL, 1 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        ; Incrementa la posición X
                DEC BX        ; Decrementa el contador de píxeles
                JNZ BLUE_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 500      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ BLUE_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_BLUE_SQUARE ENDP
DRAW_GREEN_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 500          ; Establece la posición X
        MOV DX, 144          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        GREEN_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            GREEN_COLUMN_LOOP:
                MOV AL, 2 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        ; Incrementa la posición X
                DEC BX        ; Decrementa el contador de píxeles
                JNZ GREEN_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 500      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ GREEN_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_GREEN_SQUARE ENDP
DRAW_RED_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 500          ; Establece la posición X
        MOV DX, 192          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        RED_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            RED_COLUMN_LOOP:
                MOV AL, 4 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        ; Incrementa la posición X
                DEC BX        ; Decrementa el contador de píxeles
                JNZ RED_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 500      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ RED_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_RED_SQUARE ENDP
DRAW_PURPLE_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 500          ; Establece la posición X
        MOV DX, 240          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        PURPLE_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            PURPLE_COLUMN_LOOP:
                MOV AL, 5 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        ; Incrementa la posición X
                DEC BX        ; Decrementa el contador de píxeles
                JNZ PURPLE_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 500      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ PURPLE_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_PURPLE_SQUARE ENDP
DRAW_BROWN_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 500          ; Establece la posición X
        MOV DX, 288          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        BROWN_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            BROWN_COLUMN_LOOP:
                MOV AL, 6 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        ; Incrementa la posición X
                DEC BX        ; Decrementa el contador de píxeles
                JNZ BROWN_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 500      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ BROWN_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_BROWN_SQUARE ENDP
;-----------------------------------
; FUNCIÓN PARA VERIFICAR EL COLOR
; EN AL Y GRAFICAR
;-----------------------------------
CHECK_COLORS_FOR_LOAD_FILE PROC
    CMP AL, '0'               ; ¿Es '0'?
    JE .SetColorBlack         ; Si es '0', pintar en negro
    CMP AL, '1'               ; ¿Es '1'?
    JE .SetColorBlue
    CMP AL, '2'               ; ¿Es '2'?
    JE .SetColorGreen
    CMP AL, '4'               ; ¿Es '3'?
    JE .SetColorRed
    CMP AL, '5'               ; ¿Es '4'?
    JE .SetColorPurple
    CMP AL, '6'               ; ¿Es '5'?
    JE .SetColorBrown
    CMP AL, 'F'               ; ¿Es 'F'?
    JE .SetColorWhite         ; Si es 'F', pintar en blanco
    RET
    .SetColorBlack:
        MOV AL, 0                 ; Color negro (0 en modo gráfico)
        RET
    .SetColorBlue:
        MOV AL, 1                 ; Color azul (1 (1 en modo gráfico)
        RET
    .SetColorGreen:
        MOV AL, 2                 ; Color verde (2 en modo gráfico)
        RET
    .SetColorRed:
        MOV AL, 4                 ; Color rojo (4 en modo gráfico)
        RET
    .SetColorPurple:
        MOV AL, 5                 ; Color morado (5 en modo gráfico)
        RET
    .SetColorBrown:
        MOV AL, 6                 ; Color marrón (6 en modo gráfico)
        RET
    .SetColorWhite:
        MOV AL, 15                ; Color blanco (15 en modo gráfico)
        RET
    
CHECK_COLORS_FOR_LOAD_FILE ENDP
;-----------------------------------
; FUNCIÓN PARA CERRAR EL PROGRAMA
;-----------------------------------
EXIT_PROGRAM PROC
    MOV AX, 0003H                
    INT 10H
    MOV AH, 4CH                 
    INT 21H
    RET
EXIT_PROGRAM ENDP
END MAIN