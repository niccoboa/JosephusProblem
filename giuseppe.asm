TITLE giuseppe.asm: Esame Calcolatori del 07/07/2023

comment *
		Programma assembler 8086 che calcola la lista degli eliminati del gioco di Giuseppe

		data creazione: sabato 08 luglio 2023
		ultime modifiche: domenica 09 luglio 2023
*


;-----------------------------------------------------------------
; Definizione costanti
CR EQU 13                      ; carriage return
LF EQU 10                      ; line feed
DOLLAR EQU '$'
K EQU 6


;-----------------------------------------------------------------
;    M  A  C  R  O
;-----------------------------------------------------------------

display macro xxxx           ; N.B. ogni stringa deve terminare con '$' 
        push dx
	    push ax
	    mov dx,offset xxxx
	    mov ah,9
	    int 21h
	    pop ax
        pop dx
endm

print macro xxxx
	PUSH DX
	PUSH CX
	 MOV DI, offset xxxx
	 MOV CX, N
	  PUSH DI 				; passaggio parametro 1: array
	  PUSH CX				; passaggio parametro 2: dimensione array
	 CALL NEAR PTR print_array
	  POP CX
	  POP DI
	POP CX
	POP DX
endm


;-----------------------------------------------------------------
;
PILA SEGMENT STACK 'STACK'     ; stack
      DB 64 DUP('STACK')  
PILA ENDS                      

;-----------------------------------------------------------------
;
DATI SEGMENT PUBLIC 'DATA'    ; segmento dati

	CRLF  db CR,LF, DOLLAR
	COMMA db ',', DOLLAR
	SPACE db ' ', DOLLAR

	V db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16, '$'
	N equ $-V-1
	;K db 3 						; valore di 'offset' del gioco

	LIST db N dup('*'), '$' 				; lista eliminati (all'inizio a zero)

	CHAR db '??', '$' 				; struttura di appoggio per stampare le cifre

	msg_giocatori db "Lista : ", '$'		; lista giocatori
	msg_eliminati db "Fuori : ", '$'		; lista giocatori eliminati

	MAX db ?

DATI ENDS


CSEG SEGMENT PUBLIC 'CODE'

	MAIN proc far
		init:
		    	ASSUME CS:CSEG,DS:DATI,SS:PILA,ES:NOTHING
			MOV AX,DATI
			MOV DS, AX

		code:
			situazione_iniziale:
				display msg_giocatori
				print V
				display msg_eliminati
				print LIST

			XOR BX, BX
			XOR DL, DL
			XOR AL, AL
			MOV DI, 0
			MOV SI, 0
			MOV BL, K

			MOV CX, N
			algo:
				ADD DI, K

				adjust:
					CMP DI, N
					JLE last_check
					SUB DI, N
				
				last_check:
					CMP V[DI-1], '*'
					JNE elimina
					INC DI
					JMP adjust

				elimina:
					MOV AL, V[DI-1]
					MOV AH, LIST[SI]			
					
					MOV V[DI-1], AH
					MOV LIST[SI], AL

				incr_and_loop:
					INC SI
					LOOP algo

			display CRLF
			display msg_giocatori
			print V
			display msg_eliminati
			print LIST
					
		exit: 
        		MOV AH,4CH                 ; ritorno al DOS
        		INT 21H
	main endp


	print_array proc near
		PUSH AX
		PUSH DX
		PUSH BX
		PUSH DI
		PUSH CX
		PUSH BP

		mov bp,sp
        	add bp,12                      ; rimuove l'effetto dei push soprastanti


		MOV DI, [bp+4]
		MOV CX, [bp+2]
		ciclo:
			XOR AX, AX
			XOR DX, DX

			MOV DX, [DI]

			CMP DL, '*'
			JE put_asterisco

			put_cifre:
				MOV AL, DL 
				MOV BL, 10
				DIV BL ; AL = decina ("quoziente"), AH = unità ("resto")

				ADD AL, '0'
				ADD AH, '0'
				jmp display_cifre

			put_asterisco:
				MOV AL, DL
				MOV AH, DL

			display_cifre:
				MOV CHAR[0], AL
				MOV CHAR[1], AH
				display CHAR
				display SPACE
			
			incr_index_and_loop:
				INC DI
				LOOP ciclo		

		exit_proc:
			display CRLF
			POP BP
			POP CX
			POP DI
			POP BX
			POP DX
			POP AX
			ret


	print_array endp

	prova proc near

		ret

	prova endp

cseg ends

END MAIN                     ; il programma comincia all'indirizzo di MAIN