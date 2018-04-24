SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

; DEFINE YOUR CONSTANTS HERE
    CONSTANT_1     EQU 04Bh


; *************************************************************************
; The code starts here
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
		ORG 100h

; ****************************************
; The main function, as stated by the directive: END MAIN
; ****************************************
MAIN 	PROC 	NEAR

      ; INSERT YOUR CODE HERE
      CALL FUNCTION_1

	int 20h; terminate program
MAIN	ENDP	

; ****************************************
; An example of a function definition
; Returns:
;   ; values returned by the function
;   ; Ex: AH: number of hits
; Modifies:
;   ; registers modified by the function and not restored
; Uses: 
;   ; constants used by the function
;   ; Ex: CONSTANT_1 
; Calls:
;   ; functions calls
; ****************************************
            PUBLIC  FUNCTION_1
FUNCTION_1 	PROC    NEAR

      ; INSERT YOUR CODE HERE

	RET

FUNCTION_1	ENDP

CODE_SEG 	ENDS

; *************************************************************************
; The data starts here
; *************************************************************************
DATA_SEG	SEGMENT	PUBLIC
    ; DEFINE YOUR MEMORY HERE
	DATA		DB 20 DUP (0)
DATA_SEG	ENDS

	END MAIN