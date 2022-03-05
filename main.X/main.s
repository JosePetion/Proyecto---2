; Archivo:	POSTLAB6.s
; Dispositivo:	PIC16F887
; Autor:	Jose Pablo Petion
; Compilador:	pic-as (v2.35), MPLABX V6.00
;                
; Programa:	TMR1 e Incremento de variable segundos
; Hardware:	DISPLAY PORTC		
;
; Creado:	4 mar 2022
; Última modificación: 4 mar 2022
    
PROCESSOR 16F887
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
; -------------- MACROS --------------- 
  ; Macro para reiniciar el valor del TMR0
  ; **Recibe el valor a configurar en TMR_VAR**
  RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM
  RESET_TMR1 MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H
    MOVWF   TMR1H	    ; 50ms retardo
    MOVLW   TMR1_L	    ; limpiamos bandera de interrupción
    MOVWF   TMR1L
    BCF	    TMR1IF
    ENDM
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
PSECT udata_bank0	    ;banco de variables
    segundos:      DS 1
    var:	   DS 1
    bandera:	   DS 1
    UNIDAD:	   DS 1
    DECENA:	   DS 1
    display:	   DS 2
PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN	    ; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   T0IF
    CALL    int_tmr0
    BTFSC   TMR1IF
    CALL    AUMENTO
    
    ;--------------------------------------------------------------------
    ; En caso de tener habilitadas varias interrupciones hay que evaluar
    ;	el estado de todas las banderas de las interrupciones habilitadas
    ;	para identificar que interrupción fue la que se activó.
    
    ;BTFSC   T0IF	    ; Fue interrupción del TMR0? No=0 Si=1
    ;CALL    INT_TMR0	    ; Si -> Subrutina o macro con codigo a ejecutar
			    ;	cuando se active interrupción de TMR0
    
    ;BTFSC   RBIF	    ; Fue interrupción del PORTB? No=0 Si=1
    ;CALL    INT_PORTB	    ; Si -> Subrutina o macro con codigo a ejecutar
			    ;	cuando se active interrupción de PORTB
    ;---------------------------------------------------------------------
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
AUMENTO:
    RESET_TMR1 0x0B, 0xCD
    INCF segundos
    MOVF segundos, W
    MOVWF  PORTB
    MOVLW 61
    SUBWF segundos, w
    btfsc ZERO
    clrf segundos
    RETURN
int_tmr0:
    RESET_TMR0 237
    clrf PORTD
    BTFSC   bandera, 0
    goto dis2
dis1:
    movf    display, w
    movwf   PORTC
    BSF	    PORTD, 0
    goto    next
dis2:
    movf    display+1, w
    movwf   PORTC
    BSF	    PORTD, 1
    goto    next
next:
    movlw 1
    xorwf   bandera, F
    return
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
;------------- CONFIGURACION ------------
Tabla:			    ;TABLA DEL PROGRAM COUNTER
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0f
    ADDWF PCL 
    RETLW 00111111B ;0
    RETLW 00000110B ;1
    RETLW 01011011B ;2
    RETLW 01001111B ;3
    RETLW 01100110B ;4
    RETLW 01101101B ;5
    RETLW 01111101B ;6
    RETLW 00000111B ;7
    RETLW 01111111B ;8
    RETLW 01101111B ;9
    RETLW 00111111B ;0
    
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR0
    CALL    CONFIG_TMR1	    ; Configuración de TMR0
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    MOVF    segundos, w
    MOVWF   var
    call SEPARA
    call prepara
    GOTO    LOOP	    
    
;------------- SUBRUTINAS ---------------
SEPARA:
    CALL decenas
    RETURN

prepara:
    movf    UNIDAD, w
    call    Tabla
    movwf   display
    movf    DECENA, w
    call    Tabla
    movwf   display+1
    return
    
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BSF	    OSCCON, 4	    ; IRCF<2:0> -> 101 2MHz
    RETURN
    
 ;Configuramos el TMR0 para obtener un retardo de 50ms
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   237
    MOVWF   TMR0	    ; 2ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN
    
CONFIG_TMR1:
    BANKSEL T1CON	    ; cambiamos de banco
    BCF	    TMR1GE	    ; TMR1 Siempre cuenta
    BSF	    T1CKPS1		    ; prescaler a TMR1
    BSF	    T1CKPS0		    ; PS<2:0> -> 11 prescaler 1 : 8
    BCF	    T1OSCEN		    ; OSC tmr1 desactivado
    BCF	    TMR1CS
    BSF	    TMR1ON
    
    RESET_TMR1 0x0B, 0xCD
    RETURN 


    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	        ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISB	    ; PORTD como salida
    CLRF    TRISC
    BCF     TRISD, 0
    BCF     TRISD, 1
    BANKSEL PORTD
    CLRF    PORTB	    ; Apagamos PORTB
    CLRF    PORTC
    BCF	    PORTD, 0
    BCF	    PORTD, 1
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1 
    BSF	    TMR1IE
    BANKSEL INTCON
    BSF	    PEIE	    ; Habilitamos interrupciones
    BSF	    GIE		    ; Habilitamos interrupcion TMR0
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    BCF	    TMR1IF
    RETURN

    decenas:
	clrf DECENA	    ;limpuiar la variable donde se guardan las decenas	
	movlw	10	    ;mover 10 a w
	subwf	var, W    ;restar 10 al valor del PORT A
	btfsc	STATUS, 0   ;skip if el carry esta en 0
	incf	DECENA	    ; incrementar el contador de la variable decenas
	btfsc	STATUS, 0   ;skip if el carry esta en 0
	movwf	var	    ; mover el valor de la resta a w
	btfsc	STATUS, 0   ;skip if el carry esta en 0
	goto	$-7	    ; si se puede seguir restando 10 entonces realizar todo el proceso
	call unidades	    ; si ya no se puede restar 10, por que la bandera de carry se encendio entonces ir a unidades
	return
	
    unidades:
	clrf UNIDAD	    ;limpiar la variable donde se guardan las unidades
	movlw	1	    ;mover 1 a w
	subwf	var, F    ; restar 1 al valor del PORT A
	btfsc	STATUS, 0   ;skip if el carry esta en 0
	incf	UNIDAD	    ; incrementar el contador de la variable unidades
	btfss	STATUS, 0   ; si tenemos un carry en el valor entonces realizar otra vez el proceso
	return		    ; si no se puede seguir restando 1 erntonces se regresa al stack 
	goto $-6
end