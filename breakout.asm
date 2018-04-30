; * Carles Vilella, 2017 (ENTI-UB)

; *************************************************************************
; Our data section. Here we declare our strings for our console message
; *************************************************************************

SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

    TRUE  EQU 1
    FALSE EQU 0

; EXTENDED ASCII CODES
    ASCII_SPECIAL_KEY EQU 00
    ASCII_LEFT        EQU 04Bh
    ASCII_RIGHT       EQU 04Dh
    ASCII_UP          EQU 048h
    ASCII_DOWN        EQU 050h
    ASCII_QUIT        EQU 071h ; 'q'
	ASCII_LEFT_A	  EQU 061h 
	ASCII_RIGHT_D	  EQU 064h

; ASCII / ATTR CODES TO DRAW THE SNAKE
    ASCII_PJ     EQU 02Dh
    ATTR_PJ      EQU 070h
	
; ASCII / ATTR CODES TO DRAW THE SNAKE
    ASCII_BALL     EQU 02Ah
    ATTR_BALL      EQU 007h

; ASCII / ATTR CODES TO DRAW THE FIELD
    ASCII_FIELD		EQU 020h ;espacio
    ATTR_FIELD_WALLS	EQU 060h ;naranja
	ATTR_FIELD_TOP		EQU 060h ;naranja
	ATTR_FIELD_DOWN	EQU	060h;020h ;Verde
	ATTR_FIELD_INSIDE  EQU 000h ;negro
	
; ASCII / ATTR CODES TO DRAW THE BLOCKS
    ASCII_BLOCKS    EQU 023h
    ATTR_BLOCKS     EQU 024h
	
    ASCII_NUMBER_ZERO EQU 030h

; CURSOR
    CURSOR_SIZE_HIDE EQU 02607h  ; BIT 5 OF CH = 1 MEANS HIDE CURSOR
    CURSOR_SIZE_SHOW EQU 00607h

; ASCII
    ASCII_YES_UPPERCASE      EQU 059h
    ASCII_YES_LOWERCASE      EQU 079h
    
; COLOR SCREEN DIMENSIONS IN NUMBER OF CHARACTERS
    SCREEN_MAX_ROWS EQU 25
    SCREEN_MAX_COLS EQU 25

; FIELD DIMENSIONS
    FIELD_R1 EQU 1
    FIELD_R2 EQU SCREEN_MAX_ROWS-2
    FIELD_C1 EQU 1
    FIELD_C2 EQU SCREEN_MAX_COLS-2
	
;	BLOCKS DIMENSIONS
	BLOCKS_T1 EQU 2
	BLOCKS_D1 EQU 2
	BLOCKS_D2 EQU SCREEN_MAX_COLS-3
	
	BLOCKS_ROWS EQU 5

;	Initial position of bar
	INITIAL_POS_ROW_PJ EQU SCREEN_MAX_ROWS-4    
    INITIAL_POS_COL_PJ EQU SCREEN_MAX_COLS/2
; *************************************************************************
; Our executable assembly code starts here in the .code section
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
	ORG 100h

MAIN 	PROC 	NEAR

MAIN_GO:

	CALL REGISTER_TIMER_INTERRUPT

	CALL INIT_GAME
	CALL INIT_SCREEN
	CALL HIDE_CURSOR
	CALL DRAW_FIELD
	CALL DRAW_BLOCKS

	MOV DH, INITIAL_POS_ROW_PJ
	MOV DL, INITIAL_POS_COL_PJ

	CALL MOVE_CURSOR

MAIN_LOOP:
	CMP [END_GAME], TRUE
	JZ END_PROG

	; Check if a key is available to read
	MOV AH, 0Bh
	INT 21h
	CMP AL, 0
	JZ MAIN_LOOP

	; A key is available -> read
	CALL READ_CHAR      

	; End game?
	CMP AL, ASCII_QUIT
	JZ END_PROG

	; Is it an special key?
	CMP AL, ASCII_SPECIAL_KEY
	JZ READ_ESPECIAL_CHAR
	JMP INPUT_NORMAL_CHAR

READ_ESPECIAL_CHAR:
	CALL READ_CHAR
	
	; The game is on!
	MOV [START_GAME], TRUE

	CMP AL, ASCII_RIGHT
	JZ RIGHT_KEY
	CMP AL, ASCII_LEFT
	JZ LEFT_KEY
	JMP MAIN_LOOP
	
INPUT_NORMAL_CHAR:
	MOV [START_GAME], TRUE
	
	CMP AL, ASCII_RIGHT_D
	JZ RIGHT_KEY
	CMP AL, ASCII_LEFT_A
	JZ LEFT_KEY
	
	JMP MAIN_LOOP

RIGHT_KEY:
	MOV [INC_COL_PJ], 1
	MOV [INC_ROW_PJ], 0
	JMP END_KEY

LEFT_KEY:
	MOV [INC_COL_PJ], -1
	MOV [INC_ROW_PJ], 0
	JMP END_KEY

END_KEY:
	CALL MOVE_PJ
	JMP MAIN_LOOP

END_PROG:
	CALL RESTORE_TIMER_INTERRUPT
	CALL SHOW_CURSOR
	CALL PRINT_SCORE_STRING
	CALL PRINT_SCORE
	CALL PRINT_PLAY_AGAIN_STRING

	CALL READ_CHAR

	CMP AL, ASCII_YES_UPPERCASE
	JZ MAIN_GO
	CMP AL, ASCII_YES_LOWERCASE
	JZ MAIN_GO

	INT 20h		

MAIN	ENDP	

; ****************************************
; Reset internal variables
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   INC_COL_PJ memory variable
;   INC_ROW_PJ memory variable
;   DIV_SPEED memory variable
;   NUM_TILES memory variable
;   START_GAME memory variable
;   END_GAME memory variable
; Calls:
;   -
; ****************************************
                  PUBLIC  INIT_GAME
INIT_GAME         PROC    NEAR

    MOV [INC_ROW_PJ], 0
    MOV [INC_COL_PJ], 0

    MOV [DIV_SPEED], 10

    MOV [NUM_TILES], 0
    
    MOV [START_GAME], FALSE
    MOV [END_GAME], FALSE

    RET
INIT_GAME	ENDP	

; ****************************************
; Reads char from keyboard
; If char is not available, blocks until a key is pressed
; The char is not output to screen
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   
; ****************************************
PUBLIC  READ_CHAR
READ_CHAR PROC NEAR

    MOV AH, 08h
    INT 21h

    RET
      
READ_CHAR ENDP


; ****************************************
; Read character and attribute at cursor position, page 0
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   int 10h, service AH=8
; ****************************************
PUBLIC READ_SCREEN_CHAR                 
READ_SCREEN_CHAR PROC NEAR

    PUSH BX

    MOV AH, 8
    XOR BH, BH
    INT 10h

    POP BX
    RET
      
READ_SCREEN_CHAR  ENDP

; ****************************************
; Draws the rectangular field of the game
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the rectangle: 
;    left - top: (FIELD_R1, FIELD_C1) 
;    right - bottom: (FIELD_R2, FIELD_C2)
;   Character: ASCII_FIELD
;   Attribute: ATTR_FIELD_WALLS
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_FIELD
DRAW_FIELD PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

	MOV AL, ASCII_FIELD; el char es el mismo para todos
	
    MOV DL, FIELD_C2
  UP_DOWN_SCREEN_LIMIT:
    MOV DH, FIELD_R1
    CALL MOVE_CURSOR	
    MOV BL, ATTR_FIELD_TOP
    CALL PRINT_CHAR_ATTR

    MOV DH, FIELD_R2
    CALL MOVE_CURSOR
	MOV BL, ATTR_FIELD_DOWN
    CALL PRINT_CHAR_ATTR

    DEC DL
    CMP DL, FIELD_C1
    JNS UP_DOWN_SCREEN_LIMIT

    MOV DH, FIELD_R2
	MOV BL, ATTR_FIELD_WALLS; las dos paredes naranjas
  LEFT_RIGHT_SCREEN_LIMIT:
    MOV DL, FIELD_C1
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    MOV DL, FIELD_C2
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DH
    CMP DH, FIELD_R1
    JNS LEFT_RIGHT_SCREEN_LIMIT
                 
    POP DX
    POP BX
    POP AX
    RET

DRAW_FIELD       ENDP

; ****************************************
; Draws the blocks of the field of the game
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the blocks: 
;	BLOCKS_T1 
;	BLOCKS_D1 
;	BLOCKS_D2
;    rows of blocks: (BLOCKS_ROWS) 
;   Character: ASCII_BLOCKS
;   Attribute: ATTR_BLOCKS
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_BLOCKS
DRAW_BLOCKS PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
	PUSH CX
	PUSH SI
	
    MOV AL, ASCII_BLOCKS
    MOV BL, ATTR_BLOCKS
	MOV CL, BLOCKS_ROWS
	MOV DH, BLOCKS_T1
	MOV SI,1
  ALL_ROWS:
    MOV DL, BLOCKS_D2
  ONE_ROW:
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DL
    CMP DL, BLOCKS_D1
    JNS ONE_ROW
	
	INC SI
	INC DH
	CMP SI, BLOCKS_ROWS
	JLE ALL_ROWS
	
	POP SI
	POP CX
    POP DX
    POP BX
    POP AX
    RET

DRAW_BLOCKS       ENDP
; ****************************************
; Moves de cursor to the player Pos and moves it to the next pos
; Entry: 
; 
; Returns: DH, DL (row, col) on PJ next pos
;   
; Modifies:
;   
; Uses:  
;	position of pj: POS_ROW_PJ, POS_COL_PJ
; Calls:
;   MOVE_CURSOR
; ****************************************
PUBLIC MOVE_CURSOR_FOR_PJ
MOVE_CURSOR_FOR_PJ PROC NEAR
	CALL MOVE_CURSOR_TO_PJ
    ADD DL, [INC_COL_PJ]
    ADD DH, [INC_ROW_PJ]
	
	CALL MOVE_CURSOR
	RET
	
MOVE_CURSOR_FOR_PJ ENDP

; ****************************************
; Prints a new tile of the snake, at the current cursos position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_PJ
;   attribute: ATTR_PJ
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC MOVE_CURSOR_TO_PJ
MOVE_CURSOR_TO_PJ PROC NEAR
	MOV DL, [POS_COL_PJ]
	MOV DH, [POS_ROW_PJ]
	CALL MOVE_CURSOR
	RET
	
MOVE_CURSOR_TO_PJ ENDP

; ****************************************
; Prints a new tile of the snake, at the current cursos position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_PJ
;   attribute: ATTR_PJ
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_PJ
PRINT_PJ PROC NEAR

    PUSH AX
    PUSH BX
    MOV AL, ASCII_PJ
    MOV BL, ATTR_PJ
    CALL PRINT_CHAR_ATTR
	
	PUSH DX ; PALA IZQUIERDA
	ADD DL, -1
	CALL MOVE_CURSOR
	POP DX
	CALL PRINT_CHAR_ATTR
	
	PUSH DX ;PALA DERECHA
	ADD DL, 1
	CALL MOVE_CURSOR
	POP DX
	CALL PRINT_CHAR_ATTR
	;BORREMOS LA PALA 
	CMP	INC_COL_PJ, 1 ; SI SE MUEVE HACIA LA DERECHA
	JZ REMOVE_LEFT
	CMP	INC_COL_PJ, -1 ; SI SE MUEVE HACIA LA DERECHA
	JZ REMOVE_RIGHT
	JMP END_PRINT_PJ
	
REMOVE_LEFT:
	; muevo el cursor hacia la barra que quiero borrar
	PUSH DX
	ADD DL, -2
	CALL MOVE_CURSOR
	POP DX
	;QUITO el char de barra y el fondo blanco
	MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD_INSIDE
    CALL PRINT_CHAR_ATTR
	JMP END_PRINT_PJ
REMOVE_RIGHT:
	; muevo el cursor hacia la barra que quiero borrar
	PUSH DX
	ADD DL, 2
	CALL MOVE_CURSOR
	POP DX
	;QUITO el char de barra y el fondo blanco
	MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD_INSIDE
    CALL PRINT_CHAR_ATTR
	JMP END_PRINT_PJ

END_PRINT_PJ:
    POP BX
    POP AX
    RET

PRINT_PJ        ENDP 
; ****************************************
; Does all the player move the cursor, calculate colision with ; walls and prints it
; Entry: 
; 
; Returns:
;   
; Modifies: POS_COL_PJ, POS_ROW_PJ
;   
; Uses: 
;   character: ASCII_BALL
;   attribute: ATTR_BALL
; Calls:
;   MOVE_CURSOR_FOR_PJ, PRINT_PJ
; ****************************************
PUBLIC MOVE_PJ
MOVE_PJ PROC NEAR
	PUSH AX
	
	CALL MOVE_CURSOR_TO_PJ
	CMP	INC_COL_PJ, 1 ; SI SE MUEVE HACIA LA DERECHA
	JZ COLL_RIGHT
	CMP	INC_COL_PJ, -1 ; SI SE MUEVE HACIA LA DERECHA
	JZ COLL_LEFT
	JMP END_PRINT

NO_INC_POS_PJ:
	MOV [INC_COL_PJ], 0
	MOV [INC_ROW_PJ], 0
	JMP END_PRINT

COLL_RIGHT:
	PUSH DX
	ADD DL, 2
	CALL MOVE_CURSOR
	POP DX
	CALL READ_SCREEN_CHAR
	CMP AH, ATTR_FIELD_WALLS
	JZ NO_INC_POS_PJ
	JMP END_PRINT
	
COLL_LEFT:
	PUSH DX
	ADD DL, -2
	CALL MOVE_CURSOR
	POP DX
	CALL READ_SCREEN_CHAR
	CMP AH, ATTR_FIELD_WALLS
	JZ NO_INC_POS_PJ
	
END_PRINT:
	CALL MOVE_CURSOR_FOR_PJ
	CALL PRINT_PJ
	
	MOV [POS_COL_PJ], DL
	MOV [POS_ROW_PJ], DH
	
	POP AX
	RET
MOVE_PJ ENDP


; ****************************************
; Prints the ball, at the current cursos position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_BALL
;   attribute: ATTR_BALL
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_BALL
PRINT_BALL PROC NEAR

    PUSH AX
    PUSH BX
	
    MOV AL, ASCII_BALL
    MOV BL, ATTR_BALL
    CALL PRINT_CHAR_ATTR
      
    POP BX
    POP AX
    RET

PRINT_BALL        ENDP  

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Keeps the cursor position
; Entry: 
;   AL: ASCII to print
;   BL: ATTRIBUTE to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 10h, service AH=9
; Nota:
;   Compatibility problem when debugging
; ****************************************
PUBLIC PRINT_CHAR_ATTR
PRINT_CHAR_ATTR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX

    MOV AH, 9
    MOV BH, 0
    MOV CX, 1
    INT 10h

    POP CX
    POP BX
    POP AX
    RET

PRINT_CHAR_ATTR        ENDP     

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Cursor moves one position right
; Entry: 
;    AL: ASCII code to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 21h, service AH=2
; ****************************************
PUBLIC PRINT_CHAR
PRINT_CHAR PROC NEAR

    PUSH AX
    PUSH DX

    MOV AH, 2
    MOV DL, AL
    INT 21h

    POP DX
    POP AX
    RET

PRINT_CHAR        ENDP     

; ****************************************
; Set screen to mode 3 (80x25, color) and 
; clears the screen
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   Screen size: SCREEN_MAX_ROWS, SCREEN_MAX_COLS
; Calls:
;   int 10h, service AH=0
;   int 10h, service AH=6
; ****************************************
PUBLIC INIT_SCREEN
INIT_SCREEN	PROC NEAR

      PUSH AX
      PUSH BX
      PUSH CX
      PUSH DX

      ; Set screen mode
      MOV AL,3
      MOV AH,0
      INT 10h

      ; Clear screen
      XOR AL, AL
      XOR CX, CX
      MOV DH, SCREEN_MAX_ROWS
      MOV DL, SCREEN_MAX_COLS
      MOV BH, 7
      MOV AH, 6
      INT 10h
      
      POP DX      
      POP CX      
      POP BX      
      POP AX      
	RET

INIT_SCREEN		ENDP

; ****************************************
; Hides the cursor 
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC  HIDE_CURSOR
HIDE_CURSOR PROC NEAR

      PUSH AX
      PUSH CX
      
      MOV AH, 1
      MOV CX, CURSOR_SIZE_HIDE
      INT 10h

      POP CX
      POP AX
      RET

HIDE_CURSOR       ENDP

; ****************************************
; Shows the cursor (standard size)
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC SHOW_CURSOR
SHOW_CURSOR PROC NEAR

    PUSH AX
    PUSH CX
      
    MOV AH, 1
    MOV CX, CURSOR_SIZE_SHOW
    INT 10h

    POP CX
    POP AX
    RET

SHOW_CURSOR       ENDP

; ****************************************
; Get cursor properties: coordinates and size (page 0)
; Entry: 
;   -
; Returns:
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=3
; ****************************************
PUBLIC GET_CURSOR_PROP
GET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 3
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
GET_CURSOR_PROP       ENDP

; ****************************************
; Set cursor properties: coordinates and size (page 0)
; Entry: 
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=2
; ****************************************
PUBLIC SET_CURSOR_PROP
SET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 2
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
SET_CURSOR_PROP       ENDP

; ****************************************
; Move cursor to coordinate
; Cursor size if kept
; Entry: 
;   (DH, DL): coordinates -> (row, col)
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
; ****************************************
PUBLIC MOVE_CURSOR
MOVE_CURSOR PROC NEAR

      PUSH DX
      CALL GET_CURSOR_PROP  ; Get cursor size
      POP DX
      CALL SET_CURSOR_PROP
      RET

MOVE_CURSOR       ENDP

; ****************************************
; Moves cursor one position to the right
; If the column limit is reached, the cursor does not move
; Cursor size if kept
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCREEN_MAX_COLS
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
; ****************************************
PUBLIC  MOVE_CURSOR_RIGHT
MOVE_CURSOR_RIGHT PROC NEAR

    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP
    ADD DL, 1
    CMP DL, SCREEN_MAX_COLS
    JZ MOVE_CURSOR_RIGHT_END
    
    CALL SET_CURSOR_PROP

  MOVE_CURSOR_RIGHT_END:
    POP DX
    POP CX
    RET

MOVE_CURSOR_RIGHT       ENDP

; ****************************************
; Print string to screen
; The string end character is '$'
; Entry: 
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCREEN_MAX_COLS
; Calls:
;   INT 21h, service AH=9
; ****************************************
PUBLIC PRINT_STRING
PRINT_STRING PROC NEAR

    PUSH DX
      
    MOV AH,9
    INT 21h

    POP DX
    RET

PRINT_STRING       ENDP

; ****************************************
; Print the score string, starting in the cursor
; (FIELD_C1, FIELD_R2) coordinate
; Entry: 
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCORE_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_SCORE_STRING
PRINT_SCORE_STRING PROC NEAR

    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, FIELD_R2+1
    MOV DL, FIELD_C1
    CALL SET_CURSOR_PROP

    LEA DX, SCORE_STR
    CALL PRINT_STRING

    POP CX
    POP DX
    RET

PRINT_SCORE_STRING       ENDP

; ****************************************
; Print the score string, starting in the
; current cursor coordinate
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   PLAY_AGAIN_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_PLAY_AGAIN_STRING
PRINT_PLAY_AGAIN_STRING PROC NEAR

    PUSH DX

    LEA DX, PLAY_AGAIN_STR
    CALL PRINT_STRING

    POP DX
    RET

PRINT_PLAY_AGAIN_STRING       ENDP

; ****************************************
; Prints the score of the player in decimal, on the screen, 
; starting in the cursor position
; NUM_TILES range: [0, 9999]
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   NUM_TILES memory variable
; Calls:
;   PRINT_CHAR
; ****************************************
PUBLIC PRINT_SCORE
PRINT_SCORE PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; 1000'
    MOV AX, [NUM_TILES]
    XOR DX, DX
    MOV BX, 1000
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 100'
    MOV AX, DX        ; Remainder
    XOR DX, DX
    MOV BX, 100
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 10'
    MOV AX, DX          ; Remainder
    XOR DX, DX
    MOV BX, 10
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 1'
    MOV AX, DX
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    POP DX
    POP CX
    POP BX
    POP AX
    RET   
         
PRINT_SCORE        ENDP

; ****************************************
; Move, print and clean the ball of the screen
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   POS_COL_BALL
;	POS_ROW_BALL
;	ASCII_FIELD
;	ATTR_FIELD_INSIDE
;	INC_COL_BALL
;	INC_ROW_BALL
;	POS_COL_BALL
;	POS_ROW_BALL
; Calls:
;   MOVE_CURSOR
;	PRINT_CHAR_ATTR
;	PRINT_BALL
; ****************************************
PUBLIC MOVE_BALL
MOVE_BALL PROC NEAR
	PUSH DX
	PUSH AX
	PUSH BX
	
; Load BALL coordinates
	MOV DL, [POS_COL_BALL]
    MOV DH, [POS_ROW_BALL]
	CALL MOVE_CURSOR
	MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD_INSIDE
	CALL PRINT_CHAR_ATTR
;Comprobamos las colisiones
;Paredes
	CALL BALL_COLISION	
; Añadimos el incremento de posicion
	ADD DL,[INC_COL_BALL]
	ADD DH,[INC_ROW_BALL]
;Actualizamos las variables posición a la nueva
	MOV POS_COL_BALL,DL
	MOV POS_ROW_BALL,DH
	
; Move BALL on the screen
    CALL MOVE_CURSOR
; Dibujamos la pelota
	CALL PRINT_BALL
	
	POP BX
	POP AX
	POP DX
    RET

MOVE_BALL       ENDP
; ****************************************
; Check and take action on colision with blocks and field limits
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   POS_COL_BALL
;	POS_ROW_BALL
;	ASCII_FIELD
;	ATTR_FIELD_INSIDE
;	INC_COL_BALL
;	INC_ROW_BALL
;	POS_COL_BALL
;	POS_ROW_BALL
; Calls:
;   MOVE_CURSOR

; ****************************************
PUBLIC BALL_COLISION
BALL_COLISION PROC NEAR
	PUSH AX
	
START:
	CALL CALCULATE_TOP_LADO
	;CÁLCULO DEL BOOLEANO TOP
	MOV AH, [BALL_TOP_X]
	MOV AL, [BALL_TOP_Y]
	CALL CHECK_COLLISION
	MOV AL, [BALL_CHECK_COLISION]
	MOV [BALL_TOP], AL
	;CÁLCULO DEL BOOLEANO LADO
	MOV AH, [BALL_LADO_X]
	MOV AL, [BALL_LADO_Y]
	CALL CHECK_COLLISION
	MOV AL, [BALL_CHECK_COLISION]
	MOV [BALL_LADO], AL
	;CÁLCULO DEL BOOLEANO NEXT
	MOV AH, [BALL_NEXT_X]
	MOV AL, [BALL_NEXT_Y]
	CALL CHECK_COLLISION
	MOV AL, [BALL_CHECK_COLISION]
	MOV [BALL_NEXT], AL
	;MIRAMOS SI HAY BLOQUE EN LA POSICIÓN SUPERIOR DE LA PELOTA
	CMP [BALL_TOP],TRUE
	JNZ TOP_FALSE
	
TOP_TRUE:
	PUSH AX
	;INVIERTE VELOCIDAD EN Y
	MOV AL,-1
	MUL [INC_ROW_BALL]
	MOV [INC_ROW_BALL],AL
	POP AX
	;IF IS_BLOCK 
	PUSH AX
	MOV AH, [BALL_TOP_X]
	MOV AL, [BALL_TOP_Y]
	CALL CHECK_COLLISION_BLOCK
	POP AX
	CMP [BALL_COLISION_BLOCK],TRUE
	JNZ TOP_TRUE_JUMP
TOP_TRUE_DESTROY:
	;DESTROY_BLOCK
	PUSH AX
	MOV AH,[BALL_TOP_X]
	MOV AL,[BALL_TOP_Y]
	CALL DESTROY_BLOCK
	POP AX
TOP_TRUE_JUMP:
	JMP START
		
TOP_FALSE: 
	;MIRAMOS SI HAY BLOQUE AL LADO DE LA PELOTA	
	CMP [BALL_LADO],TRUE
	JNZ LADO_FALSE
	
LADO_TRUE:
	PUSH AX
	;INVIERTE LA VELOCIDAD EN X
	MOV AL,-1
	MUL [INC_COL_BALL]
	MOV [INC_COL_BALL],AL
	POP AX
	;IF IS_BLOCK
	PUSH AX
	MOV AH, [BALL_LADO_X]
	MOV AL, [BALL_LADO_Y]
	CALL CHECK_COLLISION_BLOCK
	POP AX
	CMP [BALL_COLISION_BLOCK],1
	JNZ LADO_TRUE_JUMP
LADO_TRUE_DESTROY:
	;DESTROY_BLOCK
	PUSH AX
	MOV AH,[BALL_LADO_X]
	MOV AL,[BALL_LADO_Y]
	CALL DESTROY_BLOCK
	POP AX
LADO_TRUE_JUMP:
		JMP START
		
LADO_FALSE:
	
	CMP [BALL_NEXT],TRUE
	JNZ NEXT_FALSE
	
NEXT_TRUE:
	PUSH AX
	;INVIERTE VELOCIDAD EN X E Y
	MOV AL,-1
	MUL [INC_COL_BALL]
	MOV [INC_COL_BALL],AL
	MOV AL,-1
	MUL [INC_ROW_BALL]
	MOV [INC_ROW_BALL],AL
	POP AX
	;IF IS_BLOCK 
	PUSH AX
	MOV AH, [BALL_NEXT_X]
	MOV AL, [BALL_NEXT_Y]
	CALL CHECK_COLLISION_BLOCK
	POP AX
	CMP [BALL_COLISION_BLOCK],TRUE
	JNZ NEXT_TRUE_JUMP
NEXT_TRUE_DESTROY:
	;DESTROY_BLOCK
	PUSH AX
	MOV AH,[BALL_NEXT_X]
	MOV AL,[BALL_NEXT_Y]
	CALL DESTROY_BLOCK
	POP AX
NEXT_TRUE_JUMP:
	JMP START
	
NEXT_FALSE:

	POP AX
	RET
BALL_COLISION ENDP
; ****************************************
; Check if wheter the given position is a limit or block
; Entry: 
;   AH: X coord of the position
;	AL: Y coord of the position
; Returns:
;   BALL_CHECK_COLISION boolean
; Modifies:
;   -
; Uses: 
;	ASCII_FIELD
;	ATTR_FIELD_INSIDE
; Calls:
;   MOVE_CURSOR
;	READ_SCREEN_CHAR
; ****************************************
PUBLIC 	CHECK_COLLISION
CHECK_COLLISION PROC NEAR
	PUSH AX
	PUSH DX
	
	MOV DL,AH
	MOV DH,AL
    CALL MOVE_CURSOR		; Muevo el cursor a la posicion dada
	
    CALL READ_SCREEN_CHAR	; Leo el char y atributo que hay en la posicion
    CMP AH, ATTR_FIELD_WALLS
    JZ RETURN_TRUE_COLISION
	
SECOND_CONDITION:
	CMP AH, ATTR_BLOCKS
    JZ RETURN_TRUE_COLISION
	JMP RETURN_FALSE_COLISION	
	
RETURN_TRUE_COLISION:
	MOV [BALL_CHECK_COLISION],TRUE
	JMP END_FUNCTION
RETURN_FALSE_COLISION:
	MOV [BALL_CHECK_COLISION],FALSE
	
END_FUNCTION:
	POP DX
	POP AX

	RET
CHECK_COLLISION ENDP
; ****************************************
; Check if wheter the given position is a block
; Entry: 
;   AH: X coord of the position
;	AL: Y coord of the position
; Returns:
;   BALL_COLISION_BLOCK boolean
; Modifies:
;   -
; Uses: 
;	BALL_COLISION_BLOCK
;   READ_SCREEN_CHAR
; Calls:
;   MOVE_CURSOR

; ****************************************
PUBLIC 	CHECK_COLLISION_BLOCK
CHECK_COLLISION_BLOCK PROC NEAR
	PUSH AX
	PUSH DX
	
	MOV DL,AH
	MOV DH,AL
    CALL MOVE_CURSOR		; Muevo el cursor a la posicion dada
    CALL READ_SCREEN_CHAR	; Leo el char y atributo que hay en la posicion
    CMP AH, ATTR_BLOCKS
    JNZ RETURN_FALSE_BLOCK
	
RETURN_TRUE_BLOCK:
	MOV [BALL_COLISION_BLOCK],TRUE
	JMP END_FUNCTION
RETURN_FALSE_BLOCK:
	MOV [BALL_COLISION_BLOCK],FALSE
	
END_FUNCTION:
	POP DX
	POP AX
	CALL MOVE_CURSOR
	RET
CHECK_COLLISION_BLOCK ENDP
; ****************************************
; Write the 'space' char on the given coordinates
; Entry: 
;   AH: X coord of the position
;	AL: Y coord of the position
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;	ASCII_FIELD
;   ATTR_FIELD_INSIDE
; Calls:
;   MOVE_CURSOR

; ****************************************
PUBLIC 	DESTROY_BLOCK
DESTROY_BLOCK PROC NEAR
	PUSH AX
	PUSH DX
	PUSH BX
	
	MOV DL,AH
	MOV DH,AL
    CALL MOVE_CURSOR		; Muevo el cursor a la posicion dada
    MOV AL, ASCII_FIELD
	MOV BL, ATTR_FIELD_INSIDE
	CALL PRINT_CHAR_ATTR

	POP BX
	POP DX
	POP AX
	
	CALL MOVE_CURSOR ; DEVUELVO EL CURSOR A SU POSICION INICIAL
	RET
DESTROY_BLOCK ENDP
; ****************************************
; Calculate the coordinates of the actual top and next position of the ball, it depens of the velocity(INC_COL_BALL,INC_ROW_BALL)
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;	BALL_TOP_X
;	BALL_TOP_Y
;   BALL_LADO_X
;	BALL_LADO_Y
; Uses: 
;	INC_ROW_BALL
;	INC_COL_BALL
;	AX
; Calls:
;   -
; ****************************************
PUBLIC 	CALCULATE_TOP_LADO
CALCULATE_TOP_LADO PROC NEAR
	PUSH AX
	;CÁLCULO DE LA NEXT POSITION DE LA BALL
	MOV AL, [POS_COL_BALL]
	MOV AH, [POS_ROW_BALL]
	ADD AL, [INC_COL_BALL]
	ADD AH, [INC_ROW_BALL]
	MOV [BALL_NEXT_X], AL
	MOV [BALL_NEXT_Y], AH
	;CÁLCULO DE TOP Y NEXT POSITION
	CMP[INC_ROW_BALL],0	; Comparo si la velocidad en Y en positiva o negativa
	JNS VEL_Y_POS
	JMP VEL_Y_NEG
	
VEL_Y_POS:
	CMP [INC_COL_BALL],0 ; Comparo si la velocidad en X en positiva o negativa
	JS VEL_X_NEG
	
	VEL_X_POS:	;La velocidad es +1/+1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL	;TopX = BallX
		
		MOV AL,[POS_ROW_BALL]
		PUSH AX
		INC AL
		MOV [BALL_TOP_Y],AL	;TopY = BallY + 1
		POP AX
		
		MOV AL,[POS_COL_BALL]
		PUSH AX
		INC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX + 1
		POP AX
		
		MOV AL, [POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
	VEL_X_NEG:	;La velocidad es -1/+1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL	;TopX = BallX
		
		MOV AL,[POS_ROW_BALL]
		PUSH AX
		INC AL
		MOV [BALL_TOP_Y],AL	;TopY = BallY + 1
		POP AX
		
		MOV AL,[POS_COL_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX - 1
		POP AX
		
		MOV AL,[POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
VEL_Y_NEG:
	CMP [INC_COL_BALL],0
	JS VEL_X_NEG_Y_NEG
	
	VEL_X_POS_Y_NEG:	;La velocidad es +1/-1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL	;TopX = BallX
		
		MOV AL,[POS_ROW_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_TOP_Y],AL ;TopY = BallY - 1
		POP AX
		
		MOV AL,[POS_COL_BALL]
		PUSH AX
		INC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX + 1
		POP AX
		
		MOV AL,[POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
	VEL_X_NEG_Y_NEG:	;La velocidad es -1/-1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL ;TopX = BallX
		
		MOV AL, [POS_ROW_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_TOP_Y],AL ;TopY = BallY - 1
		POP AX
		
		MOV AL, [POS_COL_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX - 1
		POP AX
		
		MOV AL,[POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
	
FUNCTION_END:
	POP AX
	RET
	
CALCULATE_TOP_LADO ENDP
; ****************************************
; Game timer interrupt service routine
; Called 18.2 times per second by the operating system
; Calls previous ISR
; Manages the movement of the snake: 
;   position, direction, speed, length, display, collisions
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   START_GAME memory variable
;   END_GAME memory variable
;   INT_COUNT memory variable
;   DIV_SPEED memory variable
;   INC_COL_PJ memory variable
;   INC_ROW_PJ memory variable
;   ATTR_PJ constant
;   NUM_TILES memory variable
;   NUM_TILES_INC_SPEED
; Calls:
;   MOVE_CURSOR
;   READ_SCREEN_CHAR
;   PRINT_PJ
; ****************************************

PUBLIC NEW_TIMER_INTERRUPT
NEW_TIMER_INTERRUPT PROC NEAR
;
    ; Call previous interrupt
    PUSHF
    CALL DWORD PTR [OLD_INTERRUPT_BASE]

    PUSH AX

    ; Do nothing if game is stopped
    CMP [START_GAME], TRUE
    JNZ END_ISR

    ; Increment INC_COUNT and check if worm position must be updated (INT_COUNT == DIV_COUNT)
    INC [INT_COUNT]
    MOV AL, [INT_COUNT]
    CMP [DIV_SPEED], AL
    JNZ END_ISR
    MOV [INT_COUNT], 0

	CALL MOVE_BALL
	
    ; Check if it is time to increase the speed of the snake
    CMP [DIV_SPEED], 1
    JZ END_ISR
    MOV AX, [NUM_TILES]
    DIV [NUM_TILES_INC_SPEED]
    CMP AH, 0                 ; REMAINDER
    JNZ END_ISR
    ; DEC [DIV_SPEED]
	
    JMP END_ISR
      
END_SNAKES:
      MOV [END_GAME], TRUE
      MOV [POS_COL_PJ],INITIAL_POS_COL_PJ
	  MOV [POS_ROW_PJ],INITIAL_POS_ROW_PJ
END_ISR:

      POP AX
      IRET

NEW_TIMER_INTERRUPT ENDP
                 
; ****************************************
; Replaces current timer ISR with the game timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   NEW_TIMER_INTERRUPT memory variable
; Calls:
;   int 21h, service AH=35 (system interrupt 08)
; ****************************************
PUBLIC REGISTER_TIMER_INTERRUPT
REGISTER_TIMER_INTERRUPT PROC NEAR

        PUSH AX
        PUSH BX
        PUSH DS
        PUSH ES 

        CLI                                 ;Disable Ints
        
        ;Get current 01CH ISR segment:offset
        MOV  AX, 3508h                      ;Select MS-DOS service 35h, interrupt 08h
        INT  21h                            ;Get the existing ISR entry for 08h
        MOV  WORD PTR OLD_INTERRUPT_BASE+02h, ES  ;Store Segment 
        MOV  WORD PTR OLD_INTERRUPT_BASE, BX  ;Store Offset

        ;Set new 01Ch ISR segment:offset
        MOV  AX, 2508h                      ;MS-DOS serivce 25h, IVT entry 01Ch
        MOV  DX, offset NEW_TIMER_INTERRUPT ;Set the offset where the new IVT entry should point to
        INT  21h                            ;Define the new vector

        STI                                 ;Re-enable interrupts

        POP  ES                             ;Restore interrupts
        POP  DS
        POP  BX
        POP  AX
        RET      

REGISTER_TIMER_INTERRUPT ENDP

; ****************************************
; Restore timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
; Calls:
;   int 21h, service AH=25 (system interrupt 08)
; ****************************************
PUBLIC RESTORE_TIMER_INTERRUPT
RESTORE_TIMER_INTERRUPT PROC NEAR

      PUSH AX                             
      PUSH DS
      PUSH DX 

      CLI                                 ;Disable Ints
        
      ;Restore 08h ISR
      MOV  AX, 2508h                      ;MS-DOS service 25h, ISR 08h
      MOV  DX, WORD PTR OLD_INTERRUPT_BASE
      MOV  DS, WORD PTR OLD_INTERRUPT_BASE+02h
      INT  21h                            ;Define the new vector

      STI                                 ;Re-enable interrupts

      POP  DX                             
      POP  DS
      POP  AX
      RET    
      
RESTORE_TIMER_INTERRUPT ENDP

CODE_SEG 	ENDS

DATA_SEG	SEGMENT	PUBLIC
			
    OLD_INTERRUPT_BASE    DW  0, 0  ; Stores the current (system) timer ISR address
	
	; Position of the PJ initialized to the intial position
    POS_ROW_PJ DB INITIAL_POS_ROW_PJ    
    POS_COL_PJ DB INITIAL_POS_COL_PJ
	
	; Position of the ball initialized to the initial position
    POS_ROW_BALL DB SCREEN_MAX_ROWS-5    
    POS_COL_BALL DB SCREEN_MAX_COLS/2
	
    ; (INC_COL_PJ. INC_COL_PJ) may be (-1, 0, 1), and determine the direction of movement of the snake
    INC_ROW_PJ DB 0    
    INC_COL_PJ DB 0

	; (INC_ROW_BALL. INC_COL_BALL) may be (-1, 0, 1), and determine the direction of movement of the ball
    INC_ROW_BALL DB -1    
    INC_COL_BALL DB -1
	
    NUM_TILES DW 0              ; SNAKE LENGTH
    NUM_TILES_INC_SPEED DB 20   ; THE SPEED IS INCREASED EVERY 'NUM_TILES_INC_SPEED'
    
    DIV_SPEED DB 10             ; THE SNAKE SPEED IS THE (INTERRUPT FREQUENCY) / DIV_SPEED
    INT_COUNT DB 0              ; 'INT_COUNT' IS INCREASED EVERY INTERRUPT CALL, AND RESET WHEN IT ACHIEVES 'DIV_SPEED'

    START_GAME DB 0             ; 'MAIN' sets START_GAME to '1' when a key is pressed
    END_GAME DB 0               ; 'NEW_TIMER_INTERRUPT' sets END_GAME to '1' when a condition to end the game happens

    SCORE_STR           DB "Your score is $"
    PLAY_AGAIN_STR      DB ". Do you want to play again? (Y/N)$"
	
	BALL_CHECK_COLISION DB 0			;	Wheter the given position colision or not 	
    BALL_COLISION_BLOCK DB 0	;	Wheter the given position colision is a block or not	
	
	BALL_TOP DB 0				;	Wheter the ball top position colision or not 
	BALL_TOP_X DB 0				;	Ball top position, coordinate x
	BALL_TOP_Y DB 0				;	Ball top position, coordinate y
	BALL_LADO DB 0				;	Wheter the ball next position colision or not 
	BALL_LADO_X DB 0			;	Ball lado position, coordinate x
	BALL_LADO_Y DB 0			;	Ball lado position, coordinate y	
	BALL_NEXT DB 0				;	Wheter the ball next movement position colision or not 	
	BALL_NEXT_X DB 0			;	Ball NEXT position, coordinate x
	BALL_NEXT_Y DB 0			;	Ball NEXT position, coordinate y	
	
DATA_SEG	ENDS

		END MAIN