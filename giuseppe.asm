TITLE giuseppe.asm: Esame Calcolatori del 07/07/2023

comment *
		Programma assembler 8086 che calcola la lista degli eliminati del gioco di Giuseppe (Josephus Problem)

		data creazione: domenica  09 luglio 2023
		ultime modifiche: martedi 11 luglio 2023 (aggiunti commenti)


		Niccolò Boanini (https://github.com/niccoboa/JosephusProblem)
*


;-----------------------------------------------------------------
;    C  O  S  T  A  N  T  I
;-----------------------------------------------------------------
CR EQU 13                      ; carriage return
LF EQU 10                      ; line feed
DOLLAR EQU '$'

;-----------------------------------------------------------------
;    M  A  C  R  O
;-----------------------------------------------------------------

display macro string         
	PUSH DX
	PUSH AX
	  MOV DX, offset string
	  MOV AH, 9
	  INT 21h
	POP AX
      POP DX
endm

print macro array
	PUSH DX
	PUSH CX
	  MOV DI, offset array
	  MOV CX, N
	    PUSH DI 				; passaggio parametro 1: array
	    PUSH CX				      ; passaggio parametro 2: dimensione array
	      CALL NEAR PTR ASCIIfy_array
	    POP CX
	    POP DI
	POP CX
	POP DX
endm


;-----------------------------------------------------------------
;    S  T  A  C  K
;-----------------------------------------------------------------
PILA SEGMENT STACK 'STACK'
      DB 64 DUP('STACK')  
PILA ENDS                      


;-----------------------------------------------------------------
;    D  A  T  A    S  E  G  M  E  N  T
;-----------------------------------------------------------------
DATI SEGMENT PUBLIC 'DATA'

	CRLF  DB CR,LF, DOLLAR
	SPACE DB ' '  , DOLLAR

	V db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41, '$'
	N equ $-V-1
	K EQU 3   				            ; valore di 'offset' del gioco

	LIST db N dup('0'), '$' 		   	; lista eliminati (all'inizio a zero)

	CHAR db 'D', 'U', '$' 				; struttura di appoggio per stampare le cifre di numeri <=99
								; cella 'D' memorizza la decina del numero (es. 42 -> CHAR[0]=4)
								; cella 'U' memorizza la unità  del numero (es. 42 -> CHAR[1]=2)

	msg_giocatori db "Lista: ", '$'		; lista giocatori ancora in campo
	msg_eliminati db "Fuori: ", '$'		; lista giocatori eliminati

DATI ENDS


CSEG SEGMENT PUBLIC 'CODE'

	MAIN proc far
		inizio:
		    	ASSUME CS:CSEG,DS:DATI,SS:PILA,ES:NOTHING
			MOV AX, DATI
			MOV DS, AX

		codice:						
			display msg_giocatori		; stampa situazione iniziale (array con tutti i giocatori)
			print V  				; ancora non è stato eliminato nessuno

			;XOR [BX, DL, AL]			; XOR preliminari (non indispensabili)
			MOV DI, 0 				; indice vettore giocatori in campo  (V)
			MOV SI, 0 				; indice vettore giocaotri eliminati (LIST)

			MOV CH, N 				; numero di iterazioni: dato che length(LIST) == length(V) == N, dobbiamo fare
								; N iterazioni per popolare tutta la lista degli eliminati (LIST)
			
			algo:					; due parti: 1) calcola indice giocatore da eliminare 2) elimina tale giocatore
				
				calcola_indice:		; calcola indice (DI) relativo al giocatore da eliminare
								; N.B. non basta fare ADD DI, K: infatti, se nello scorrimento di V si trova un giocatore
								;      già eliminato (V[DI]=='0'), bisogna "skipparlo" e andare all'indice successivo
								;      nel fare lo skip, si incrementa sì l'indice DI ma non si altera il contatore
								;	 (il contatore conta fino a K giocatori non eliminati - il K-esimo è quello da eliminare)
										
					CMP CH, N 				; controllo preliminare: nel primo conteggio di K si conta anche il giocatore stesso
					JNE volte_successive		; quindi è come se si contassero i "K-1" giocatori successivi al primo. In tutti gli 
										; altri casi ("volte_successive", CH < N) invece si contano i "K" giocatori successivi
										; (cioè non si include nel conteggio il giocatore stesso)

						prima_volta:		; caso semplice: non ci sono eliminati con certezza
							ADD DI, K 		; Posso quindi saltare direttamente di K giocatori in avanti (si presume K < N)
							DEC DI 		; essendo il primo caso, per i motivi suddetti, si salta in realtà di K-1 posizioni
							JMP elimina 	; elimina giocatore in posizione V[DI] (che è uguale a V[K] in questo caso)

						volte_successive: 	; caso più complicato: si deve tener conto degli skip e degli out of bound
							MOV CL, K         ; questo è certo: si devono saltare K giocatori ancora in campo
							cicla:
								CMP CL, 0   ; abbiamo saltato i K giocatori in campo: eliminiamo il giocatore
								JE elimina
								
								INC DI      		; ancora non abbiamo saltato K giocatori: proviamo a incrementare l'indice
								check:            	; controlliamo che non siamo andati out of bound
									CMP DI, N
									JGE adjust  	; siamo andati oltre: aggiustiamo l'indice (mod n)

									CMP V[DI], '0'	; non out of bound, però troviamo un giocatore già eliminato: "skippiamolo"
									JE skip

									DEC CL 		; ok incontriamo un giocatore in campo: contiamolo (alteriamo CL)
									JMP cicla   	; mi sarebbe piaciuto fare LOOP cicla ma stiamo usando CL, non CX

								adjust:
									MOV DI, 0 		; ripartiamo da capo dell'array
									JMP check

								skip:
									INC DI 	 	; passiamo oltre (skip) e rieseguiamo i controlli (label check)
									JMP check	


				elimina:					; eliminiamo il giocatore in posizione DI
					MOV AL, V[DI]  			; l'idea è quella di scambiare LIST[SI] con [DI], tanto:			
					MOV AH, LIST[SI]			; su LIST[SI] c'è '0' e su V[DI] c'è un giocatore, In questo modo:
					MOV V[DI], AH			; aggiorniamo la lista degli eliminati e "notifichiamo" per le iterazioni successive
					MOV LIST[SI], AL			; che tale giocatore (V[DI]) è stato eliminato, ponendoci '0'
					

				aggiorna_e_salta:				; aggiorniamo l'indice di LIST e il contatore delle iterazioni.
					INC SI
					DEC CH
					JNZ algo				; ripartiamo se ci sono ancora iterazioni da fare


			fine:							; abbiamo finito: stampiamo la lista degli eliminati
				display msg_eliminati			
				print LIST
					
		exit: 
        		MOV AH,4CH                ; ritorno al DOS
        		INT 21H
	main endp


	ASCIIfy_array proc near			; converte numero a due cifre (<99) in ASCII
		PUSH AX
		PUSH DX
		PUSH BX
		PUSH DI
		PUSH CX
		PUSH BP

		mov bp,sp
        	add bp,12                     ; rimuove l'effetto dei push soprastanti


		MOV DI, [bp+4]			; recupero parametro 1: array
		MOV CX, [bp+2]			; recupero parametro 2: dimensione array
		ciclo:
			XOR AX, AX
			XOR DX, DX

			MOV DX, [DI]		
			CMP DL, '0'		
			JE put_zero			; se abbiamo a che fare con un eliminato, dobbiamo stampare "00"
							; altrimenti se troviamo tipo 21, dobbiamo stampare "21" (cfr. put_cifre)

			put_cifre:			; estraiamo la decina e la unità del numero del giocatore da stampare
				MOV AL, DL 
				MOV BL, 10
				DIV BL            ; AL = decina ("quoziente"), AH = unità ("resto")

				ADD AL, '0'		; convertiamo la decina in ASCII
				ADD AH, '0'		; convertiamo la unità  in ASCII
				jmp display_cifre

			put_zero:
				MOV AL, DL
				MOV AH, DL

			display_cifre:		; stampiamo le cifre
				MOV CHAR[0], AL
				MOV CHAR[1], AH
				display CHAR
				display SPACE
			
			incr_index_and_loop:	; passiamo alla cella successiva da convertire
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


	ASCIIfy_array endp

cseg ends

END MAIN               