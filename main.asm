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
    BG_COLOR DB 0             ; Color de fondo (blanco)
    HELLO	DB	'Telesketch$'
    FPIX	DW	0
    CPIX	DW	0
    ;Colors
    BLACK DB '0.$'
    BLUE DB '1.$'
    GREEN DB '2.$'
    RED DB '3.$'
    PURPLE DB '4.$'
    BROWN DB '5.$'
    LIGHT_BLUE DB '6.$'
    LIGHT_GREEN DB '7.$'
    YELLOW DB '8.$'
    CYAN DB '9.$'
    ;Comands
    SAVE_FILE DB 's = Save$'
    EXIT DB 'e = Exit$'
    CLEAR DB 'c = Clear$'
    LOAD DB 'r + click = Load File$'
    TEXT_COLORS DB 'Colors$'
    TEXT_COMMANDS DB 'Commands$'
;-----------------------------------
; VARIABLES PARA VIDEO
;-----------------------------------
    CURRENT_COLOR DB 4        
;-----------------------------------
; VARIABLES PARA GUARDAR EN EL ARCHIVO
;-----------------------------------               
    ERROR_MSG DB 'Error al crear el archivo: $', 0
    WRITE_ERROR_MSG DB 'NO SE PUO ESCRIBIR', 0
    FILE_NAME DB "salida.TXT", 0  
    MESSAGE_USER_INPUT DB 'Ingrese el nombre del archivo: $'
    ;FILE_NAME DB 20 DUP('$')
;-----------------------------------
; VARIABLES PARA MANEJAR EN EL ARCHIVO
;-----------------------------------
    FILE_HANDLE DW ?                     
    TEMP_CHAR DB ?              
    TEMP_CHAR_AUX DB ?
;-----------------------------------
; MACRO PARA EL CURSOR
;-----------------------------------
    POS_CURSOR MACRO FIL, COL		
        MOV AH, 02H
        MOV BH, 00
        MOV DH, FIL
        MOV DL, COL
        INT 10H						
    ENDM
;-----------------------------------
; MAIN
;-----------------------------------
.CODE
MAIN PROC FAR
    ; Configurar segmento de datos
    MOV AX, @DATA
    MOV DS, AX

    CALL MODEVIDEO  
    
    MOV CPIX, 50D
    MOV FPIX, 30D
	CALL DRAWLINE_ROW	

    MOV CPIX, 50D
    MOV FPIX, 30D
	CALL DRAWLINE_COL

    MOV CPIX, 50D
	CALL DRAWLINE_ROW		

    MOV FPIX, 30D
	CALL DRAWLINE_COL

    CALL INIT_MOUSE

    POS_CURSOR 0, 24

    LEA	DX, HELLO
	MOV	AH, 9H		
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
    MOV AX, 0A000H        
    MOV ES, AX            
    MOV DI, 0             

    ;MOV CX, 640 * 480 / 2 
    MOV AX, 0FFFFH        

    FILL_SCREEN:
        STOSW                 
        LOOP FILL_SCREEN      
        RET
MODEVIDEO ENDP
;-----------------------------------
; FUNCIÓN PARA DIBUJAR UNA LÍNEA EN ROW
;-----------------------------------
DRAWLINE_ROW PROC NEAR
    MOV CX, 370
    CICLO_ROW:
        PUSH CX
        MOV AL, 0FH          
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
    MOV CX, 400           ; Longitud de la línea
    CICLO_COL:
        PUSH CX
        MOV AL, 0FH          
        MOV BX, 00           
        MOV DX, FPIX         ; Guardamos la coordenada Y en DX
        MOV CX, CPIX         ; Guardamos la coordenada X en CX
        MOV AH, 0CH
        INT 10H              
        INC FPIX             
        POP CX
        LOOP CICLO_COL           
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
    JZ WAIT_FOR_MOUSE_CLICK 
    RET
WAIT_FOR_MOUSE_CLICK ENDP
;-----------------------------------
; FUNCIÓN PARA DIBUJAR UN PIXEL
;-----------------------------------
DRAW_PIXEL PROC
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, [CURRENT_COLOR] 
    MOV CX, [X]     
    MOV DX, [Y]     
    INT 10H         
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
    MOV CX, 0                 
    LEA DX, FILE_NAME         
    INT 21H
    JC FILE_ERROR             

    MOV BX, AX                ; Guardar el manejador del archivo en BX
    MOV FILE_HANDLE, BX       

    MOV DI, 51
    MOV SI, 31
  
    SAVE_PIXELS:
        ; Leer el color del píxel en (CX, DX)
        MOV AH, 0DH               ; Función para leer el color de un píxel
        ; Coordenadas iniciales
        MOV CX, DI                 ; X inicial
        MOV DX, SI                 ; Y inicial
        INT 10H                   

    CALL CHECK_COLORS_IN_AL

    WritePixel:
        ; Escribir el carácter en el archivo
        MOV BX, FILE_HANDLE       
        MOV AH, 40H               ; Función DOS para escribir en archivo
        LEA DX, TEMP_CHAR         ; Dirección del carácter a escribir
        MOV CX, 1                 
        INT 21H                   

        ; Avanzar al siguiente píxel
        INC DI                    
        CMP DI, 419
        JE .WriteX
        CMP DI, 419            
        JBE ContinueX           

        MOV DI, 51                 
        INC SI                    
        CMP SI, 429               
        JBE SAVE_PIXELS        

        JMP EndSave              
    .WriteX:
        MOV TEMP_CHAR, 0AH
        JMP WritePixel
    ContinueX:
        JMP SAVE_PIXELS           

    EndSave:
        ; Cerrar archivo
        MOV BX, FILE_HANDLE       
        MOV AH, 3EH               ; Función DOS para cerrar archivo
        INT 21H
        RET

    FILE_ERROR:
        MOV DX, OFFSET ERROR_MSG        
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

;-----------------------------------
; FUNCIÓN PARA CARGAR EL ARCHIVO
;-----------------------------------

LOAD_FILE PROC
     ; Abrir archivo
    MOV AH, 3DH               ; Función DOS para abrir archivo
    MOV AL, 00H               ; Modo de acceso: solo lectura
    LEA DX, FILE_NAME         
    INT 21H
    JC FILE_ERROR_L            
    MOV FILE_HANDLE, AX       

    ; Inicializar coordenadas
    MOV DI, 51                
    MOV SI, 31                

    READ_PIXELS:
        ; Leer un byte del archivo
        MOV AH, 3FH               
        MOV BX, FILE_HANDLE       
        LEA DX, TEMP_CHAR_AUX     
        MOV CX, 1                 
        INT 21H                   

        ; Verificar si se alcanzó el fin del archivo
        OR AX, AX                 
        JZ END_LOAD               

        ; Comprobar el carácter leído
        MOV AL, TEMP_CHAR_AUX     
        CMP AL, 0AH
        JE .NextRow
        CALL CHECK_COLORS_FOR_LOAD_FILE
        JMP .DrawPixel
        JMP .Continue             

    .DrawPixel:
        ; Mostrar el píxel en la pantalla con el color correspondiente en AL
        MOV CX, DI                
        MOV DX, SI                
        MOV AH, 0CH               ; Función para escribir píxel (en modo gráfico)
        INT 10H                   

    .Continue:
        ; Actualizar las coordenadas para el siguiente píxel
        INC DI                    
        JMP READ_PIXELS           

    .NextRow:
        MOV DI, 51                
        INC SI                    
        CMP SI, 429               
        JBE READ_PIXELS           

    END_LOAD:
        ; Cerrar archivo y terminar el procedimiento
        MOV BX, FILE_HANDLE       
        MOV AH, 3EH               
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
    INT 16H         

    CMP AL, 'r'
    JE LOAD_FILE
    CMP AL, 's'
    JE WRITE_SCREEN_TO_FILE_AUX
    CMP AL, 'c'     
    JE CLEAR_SCREEN
    CMP AL, 'e'
    JE END_PROGRAM

    
    CMP AL, 0H       ; Verificar si es una tecla especial
    CALL CHECK_COLORS  

    ; Revisar las teclas de flechas
    CMP AH, 48H     
    JE MOVE_UP
    CMP AH, 50H     
    JE MOVE_DOWN
    CMP AH, 4BH     
    JE MOVE_LEFT
    CMP AH, 4DH     
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
        DEC [Y]         
        CALL REDRAW_PIXEL

    MOVE_DOWN:
        CMP [Y], 428    ; Verificar si estamos en el límite inferior
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [Y]         
        CALL REDRAW_PIXEL

    MOVE_LEFT:
        CMP [X], 52      ; Verificar si estamos en el límite izquierdo
        JLE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        DEC [X]         
        CALL REDRAW_PIXEL

    MOVE_RIGHT:
        CMP [X], 417    ; Verificar si estamos en el límite derecho
        JGE MOVE_PIXEL  ; Si ya estamos en el límite, no mover
        INC [X]         
        CALL REDRAW_PIXEL
MOVEMENTS ENDP
;-----------------------------------
; FUNCIÓN PARA REDIBUJAR UN PIXEL
;-----------------------------------
REDRAW_PIXEL PROC
    ; Limpiar el píxel anterior dibujando con el color de fondo
    MOV AH, 0CH     ; Función para escribir píxel
    MOV AL, BG_COLOR 
    MOV CX, [X]     
    MOV DX, [Y]     
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
        MOV AH, 0CH      
        MOV AL, BG_COLOR  
        INT 10H          ; Dibujar píxel en (CX, DX) con color AL

        INC CX           
        CMP CX, 419      
        JAE NEXT_ROW     

        JMP CLEAR_LOOP   

    NEXT_ROW:
        MOV CX, 51  
        INC DX           
        CMP DX, 429      
        JL CLEAR_LOOP    

        ; Regresar al bucle de selección de nuevo punto
        JMP WAIT_FOR_CLICK 
CLEAR_SCREEN ENDP
;-----------------------------------
; FUNCIÓN PARA VERIFICAR LOS COLORES
;-----------------------------------
CHECK_COLORS PROC
    CMP AL, 30H     
    JE CHANGE_COLOR_WHITE
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


    CMP AL, 36H
    JE CHANGE_COLOR_LIGTH_BLUE
    CMP AL, 37H
    JE CHANGE_COLOR_LIGTH_GREEN
    CMP AL, 38H
    JE CHANGE_COLOR_YELLOW
    CMP AL, 39H
    JE CHANGE_COLOR_CYAN
    RET
CHECK_COLORS ENDP
;-----------------------------------
; FUNCIONES PARA CAMBIAR LOS COLORES
;-----------------------------------
CHANGE_COLOR_WHITE PROC
    MOV [CURRENT_COLOR], 0FH
    RET
CHANGE_COLOR_WHITE ENDP

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

CHANGE_COLOR_LIGTH_BLUE PROC
    MOV [CURRENT_COLOR], 9
    RET
CHANGE_COLOR_LIGTH_BLUE ENDP

CHANGE_COLOR_LIGTH_GREEN PROC
    MOV [CURRENT_COLOR], 0AH
    RET
CHANGE_COLOR_LIGTH_GREEN ENDP

CHANGE_COLOR_YELLOW PROC
    MOV [CURRENT_COLOR], 0EH
    RET
CHANGE_COLOR_YELLOW ENDP

CHANGE_COLOR_CYAN PROC
    MOV [CURRENT_COLOR], 3
    RET
CHANGE_COLOR_CYAN ENDP

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
    CMP AL, 9                ; Azul claro
    JE WriteLightBlue
    CMP AL, 0AH               ; Verde claro
    JE WriteLightGreen
    CMP AL, 0EH               ; Amarillo
    JE WriteYellow
    CMP AL, 3                ; Cyan
    JE WriteCyan
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

    WriteLightBlue:
        MOV TEMP_CHAR, '9'       ; Representación para color azul claro
        RET
    
    WriteLightGreen:
        MOV TEMP_CHAR, 'A'       ; Representación para color verde claro
        RET

    WriteYellow:
        MOV TEMP_CHAR, 'E'       ; Representación para color amarillo
        RET

    WriteCyan:
        MOV TEMP_CHAR, '3'       ; Representación para color cian
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

    MOV SI, CX               
    MOV BYTE PTR FILE_NAME[SI], 0   ; Agrega el carácter nulo al final del nombre
    RET
ASK_FILE_NAME ENDP
;-----------------------------------
; FUNCIÓN PARA DIBUJAR LOS COLORES AL
; LADO DEL ÁREA DE TRABAJP
;-----------------------------------
DRAW_COLORS PROC
    POS_CURSOR 1, 65
    LEA DX, TEXT_COLORS
    MOV AH, 9H
    INT 21H

    POS_CURSOR 3, 60
    LEA	DX, BLACK
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_WHITE_SQUARE
    
    POS_CURSOR 3, 70
    LEA	DX, BLUE
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_BLUE_SQUARE

    POS_CURSOR 5, 60
    LEA	DX, GREEN
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_GREEN_SQUARE

    POS_CURSOR 5, 70
    LEA	DX, RED
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_RED_SQUARE

    POS_CURSOR 7, 60
    LEA	DX, PURPLE
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_PURPLE_SQUARE

    POS_CURSOR 7, 70
    LEA	DX, BROWN
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_BROWN_SQUARE

    POS_CURSOR 9, 60
    LEA	DX, LIGHT_BLUE
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_LIGHT_BLUE_SQUARE

    POS_CURSOR 9, 70
    LEA	DX, LIGHT_GREEN
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_LIGHT_GREEN_SQUARE

    POS_CURSOR 11, 60
    LEA	DX, YELLOW
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_YELLOW_SQUARE

    POS_CURSOR 11, 70
    LEA	DX, CYAN
	MOV	AH, 9H		
	INT	21H
    CALL DRAW_CYAN_SQUARE

    POS_CURSOR 18, 62
    LEA DX, TEXT_COMMANDS
    MOV AH, 9H
    INT 21H

    POS_CURSOR 20, 62
    LEA	DX, SAVE_FILE
    MOV	AH, 9H		
    INT	21H

    POS_CURSOR 22, 62
    LEA DX, EXIT
    MOV AH, 9H		
    INT 21H

    POS_CURSOR 24, 62
    LEA DX, CLEAR
    MOV AH, 9H
    INT 21H

    POS_CURSOR 26, 57
    LEA DX, LOAD
    MOV AH, 9H
    INT 21H
    
    RET
DRAW_COLORS ENDP
;-----------------------------------
; FUNCIONES PARA DIBUJAR LOS CUADRITOS
; DE COLORES
;-----------------------------------
DRAW_WHITE_SQUARE PROC
        
        MOV CX, 500         
        MOV DX, 48         

        MOV DI, 16          
        BLACK_ROW_LOOP:
            MOV BX, 16        
            BLACK_COLUMN_LOOP:
                MOV AL, 0FH 
                MOV AH, 0Ch  
                INT 10h       

                INC CX        
                DEC BX       
                JNZ BLACK_COLUMN_LOOP 

            INC DX           
            MOV CX, 500    
            DEC DI            
            JNZ BLACK_ROW_LOOP    
            RET
DRAW_WHITE_SQUARE ENDP
DRAW_BLUE_SQUARE PROC
        ; Dibuja un cuadrado de 10x10 píxeles
        MOV CX, 580          ; Establece la posición X
        MOV DX, 48          ; Establece la posición Y

        ; Dibuja 10 filas de 10 píxeles
        MOV DI, 16            ; Número de filas
        BLUE_ROW_LOOP:
            MOV BX, 16        ; Número de píxeles en la fila
            BLUE_COLUMN_LOOP:
                MOV AL, 1 ; Establece el color
                MOV AH, 0Ch   ; Función para escribir un píxel
                INT 10h       ; Dibuja el píxel en (CX, DX)

                INC CX        
                DEC BX        
                JNZ BLUE_COLUMN_LOOP ; Si no ha dibujado 10 píxeles, continúa

            INC DX            ; Incrementa la posición Y para la siguiente fila
            MOV CX, 580      ; Reinicia X a la posición inicial
            DEC DI            ; Decrementa el contador de filas
            JNZ BLUE_ROW_LOOP     ; Si no ha dibujado 10 filas, continúa
            RET
DRAW_BLUE_SQUARE ENDP
DRAW_GREEN_SQUARE PROC
        
        MOV CX, 500          
        MOV DX, 80          

        
        MOV DI, 16            
        GREEN_ROW_LOOP:
            MOV BX, 16        
            GREEN_COLUMN_LOOP:
                MOV AL, 2 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ GREEN_COLUMN_LOOP 

            INC DX            
            MOV CX, 500      
            DEC DI            
            JNZ GREEN_ROW_LOOP     
            RET
DRAW_GREEN_SQUARE ENDP
DRAW_RED_SQUARE PROC
        
        MOV CX, 580          
        MOV DX, 80          

        
        MOV DI, 16            
        RED_ROW_LOOP:
            MOV BX, 16        
            RED_COLUMN_LOOP:
                MOV AL, 4 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ RED_COLUMN_LOOP 

            INC DX            
            MOV CX, 580      
            DEC DI            
            JNZ RED_ROW_LOOP     
            RET
DRAW_RED_SQUARE ENDP
DRAW_PURPLE_SQUARE PROC
        
        MOV CX, 500          
        MOV DX, 112          

        
        MOV DI, 16            
        PURPLE_ROW_LOOP:
            MOV BX, 16        
            PURPLE_COLUMN_LOOP:
                MOV AL, 5 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ PURPLE_COLUMN_LOOP 

            INC DX            
            MOV CX, 500      
            DEC DI            
            JNZ PURPLE_ROW_LOOP     
            RET
DRAW_PURPLE_SQUARE ENDP
DRAW_BROWN_SQUARE PROC
        
        MOV CX, 580          
        MOV DX, 112          

        
        MOV DI, 16            
        BROWN_ROW_LOOP:
            MOV BX, 16        
            BROWN_COLUMN_LOOP:
                MOV AL, 6 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ BROWN_COLUMN_LOOP 

            INC DX            
            MOV CX, 580      
            DEC DI            
            JNZ BROWN_ROW_LOOP     
            RET
DRAW_BROWN_SQUARE ENDP

DRAW_LIGHT_BLUE_SQUARE PROC
        
        MOV CX, 500          
        MOV DX, 144          

        
        MOV DI, 16            
        L_BLUE_ROW_LOOP:
            MOV BX, 16        
            L_BLUE_COLUMN_LOOP:
                MOV AL, 9 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ L_BLUE_COLUMN_LOOP 

            INC DX            
            MOV CX, 500      
            DEC DI            
            JNZ L_BLUE_ROW_LOOP     
            RET
DRAW_LIGHT_BLUE_SQUARE ENDP

DRAW_LIGHT_GREEN_SQUARE PROC
        
        MOV CX, 580          
        MOV DX, 144          

        
        MOV DI, 16            
        L_GREEN_ROW_LOOP:
            MOV BX, 16        
            L_GREEN_COLUMN_LOOP:
                MOV AL, 0AH 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ L_GREEN_COLUMN_LOOP 

            INC DX            
            MOV CX, 580      
            DEC DI            
            JNZ L_GREEN_ROW_LOOP     
            RET
DRAW_LIGHT_GREEN_SQUARE ENDP

DRAW_YELLOW_SQUARE PROC
        
        MOV CX, 500          
        MOV DX, 176          

        
        MOV DI, 16            
        YELLOW_ROW_LOOP:
            MOV BX, 16        
            YELLOW_COLUMN_LOOP:
                MOV AL, 0EH 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ YELLOW_COLUMN_LOOP 

            INC DX            
            MOV CX, 500      
            DEC DI            
            JNZ YELLOW_ROW_LOOP     
            RET
DRAW_YELLOW_SQUARE ENDP
DRAW_CYAN_SQUARE PROC
        
        MOV CX, 580          
        MOV DX, 176          

        
        MOV DI, 16            
        CYAN_ROW_LOOP:
            MOV BX, 16        
            CYAN_COLUMN_LOOP:
                MOV AL, 3 
                MOV AH, 0Ch   
                INT 10h       

                INC CX        
                DEC BX        
                JNZ CYAN_COLUMN_LOOP 

            INC DX            
            MOV CX, 580      
            DEC DI            
            JNZ CYAN_ROW_LOOP     
            RET
DRAW_CYAN_SQUARE ENDP

;-----------------------------------
; FUNCIÓN PARA VERIFICAR EL COLOR
; EN AL Y GRAFICAR
;-----------------------------------
CHECK_COLORS_FOR_LOAD_FILE PROC
    CMP AL, '0'               
    JE .SetColorBlack         
    CMP AL, '1'               
    JE .SetColorBlue
    CMP AL, '2'               
    JE .SetColorGreen
    CMP AL, '4'               
    JE .SetColorRed
    CMP AL, '5'               
    JE .SetColorPurple
    CMP AL, '6'               
    JE .SetColorBrown
    CMP AL, 'F'               
    JE .SetColorWhite         
    CMP AL, '9'               
    JE .SetColorLigthBlue
    CMP AL, 'A'              
    JE .SetColorLigthGreen
    CMP AL, 'E'              
    JE .SetColorLigthYellow
    CMP AL, '3'            
    JE .SetColorCyan
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
    .SetColorLigthBlue:
        MOV AL, 9                ; Color azul claro (12 en modo gráfico)
        RET
    .SetColorLigthGreen:
        MOV AL, 10                 ; Color verde claro (2 en modo gráfico)
        RET
    .SetColorLigthYellow:
        MOV AL, 14                ; Color amarillo claro (14 en modo gráfico)
        RET
    .SetColorCyan:
        MOV AL, 3                 ; Color cian (3 en modo gráfico)
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