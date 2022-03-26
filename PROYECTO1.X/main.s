; Archivo:	PROYECTO1.s
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
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

BMODO EQU 0
FUNC  EQU 1
UP    EQU 2
DOWN  EQU 3
INIC  EQU 4
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
    segundos:      DS 1	    ; Variable incrementada con el tmr1
    minutos:	   DS 1	    
    horas:	   DS 1
    TIMER:	   DS 2
    var:	   DS 3	    ; Copia para hacer las verificaciones
    bandera:	   DS 6	    ; bandera
    UNIDAD:	   DS 3
    DECENA:	   DS 3
    display:	   DS 6
    subs:	   DS 3
    subsTMR:	   DS 2
    subsFCH:	   DS 3
    funciones:	   DS 3
    indicador:	   DS 2
    nocero:	   DS 1
    SONIDO:	   DS 1
    FECHA:	   DS 3
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
    BTFSC   TMR2IF
    CALL    leds
    BTFSC   RBIF
    CALL    INTB
    
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    



    

PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
;------------- CONFIGURACION ------------

    
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR0
    CALL    CONFIG_TMR1	    ; Configuración de TMR0
    CALL    CONFIG_TMR2
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    call    IOC
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    CLRF var	    ;comience en 0 siempre
    CLRF var+1
    CLRF var+2
    
    BTFSC   funciones, 0
    call    bancoRELOJ
    BTFSC   funciones, 1
    call    bancoTIMER
    BTFSC   funciones, 2
    call    bancoFECHA
    
    call decenas	;separa decenas	
    call decenas2
    call decenas3
    call prepara
    GOTO    LOOP	    
    
;------------- SUBRUTINAS --------------

prepara:
    movf    UNIDAD, w
    call    Tabla
    movwf   display
    movf    DECENA, w
    call    Tabla
    movwf   display+1
    
    movf    UNIDAD+1, w
    call    Tabla
    movwf   display+2
    movf    DECENA+1, w
    call    Tabla
    movwf   display+3
    
    movf    UNIDAD+2, w
    call    Tabla
    movwf   display+4
    movf    DECENA+2, w
    call    Tabla
    movwf   display+5
    
    return
    
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BCF	    OSCCON, 6
    BSF	    OSCCON, 5
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
    MOVLW   254
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
    
    RESET_TMR1 0xC2, 0xF7
    RETURN 
    
CONFIG_TMR2:
    BANKSEL PR2
    MOVLW   244
    MOVWF   PR2	    ; 500ms retardo
    BANKSEL T2CON	    ; cambiamos de banco
    BSF	    T2CKPS1		    ; prescaler a TMR2
    BSF	    T2CKPS0		    ; PS<1:0> -> 1x prescaler 1 : 16
    
    BSF	    TOUTPS3		    ; TMR2 postscaler 
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0		    ; PS<3:0> 1111 postescaler 1:16
    BSF	    TMR2ON		    ; Enciende el TMR2
    
    
    RETURN

    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	        ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISC
    BCF     TRISD, 0
    BCF     TRISD, 1
    BCF     TRISD, 2
    BCF     TRISD, 3
    BCF     TRISD, 4
    BCF     TRISD, 5
    BCF     TRISA, 0
    BCF     TRISA, 1
    BCF     TRISA, 2
    BCF     TRISA, 3
    BCF     TRISA, 4 
    BCF     TRISA, 5
    
    ;	  *** Puertos de entrada ***
    
    BSF TRISB, BMODO
    BSF TRISB, FUNC
    BSF TRISB, UP
    BSF TRISB, DOWN
    BSF TRISB, INIC
    BCF OPTION_REG, 7	;WPUB, PULL-UP
    BSF WPUB, BMODO
    BSF WPUB, FUNC
    BSF WPUB, UP
    BSF WPUB, DOWN
    BSF WPUB, INIC
    
    BANKSEL PORTD
    CLRF    PORTC
    BCF	    PORTD, 0
    BCF	    PORTD, 1
    BCF	    PORTD, 2
    BCF	    PORTD, 3
    BCF	    PORTD, 4
    BCF	    PORTD, 5
    BCF     PORTA, 0
    BSF     PORTA, 1
    BCF     PORTA, 2
    BCF     PORTA, 3
    BCF     PORTA, 4
    BCF     PORTA, 5
    
;    CLRF segundos
;    CLRF minutos   
;    CLRF horas
    CLRF TIMER
    BCF TIMER, 1
    BCF TIMER, 0
    CLRF bandera
    CLRF FECHA
    BCF FECHA, 0
    BCF FECHA, 1
    BCF FECHA, 2
    MOVLW 0
    MOVWF  FECHA+0
    MOVLW 0
    MOVWF  FECHA+1
    MOVLW 0
    MOVWF  FECHA+2
    MOVWF  TIMER+0
    MOVWF  TIMER+1
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1 
    BSF	    TMR1IE
    BSF	    TMR2IE
    BANKSEL INTCON
    BSF	    PEIE	    ; Habilitamos interrupciones
    BSF	    GIE		    ; Habilitamos interrupcion TMR0
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    BCF	    TMR1IF
    BCF	    TMR2IF
    
 
    BSF RBIE
    BCF RBIF
    
    RETURN

    IOC:
	banksel TRISA
	BSF IOCB, BMODO
	BSF IOCB, FUNC
	BSF IOCB, UP
	BSF IOCB, DOWN
	BSF IOCB, INIC
;	BANKSEL PORTA
;	MOVF PORTB, W
;	BCF RBIF
	return    
    
    ;   ****** RELOJ FISICO ******
    MINS:
	clrf segundos
	incf minutos
	return
    HORS:
	CLRF minutos
	incf horas
	return

    ;  *******	    EXTRACCIÓN LOGICA	    ***********
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
	goto unidades	    ; si ya no se puede restar 10, por que la bandera de carry se encendio entonces ir a unidades
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
	
    decenas2:
	clrf DECENA+1	    	
	movlw	10	    
	subwf	var+1, W    
	btfsc	STATUS, 0   
	incf	DECENA+1	
	btfsc	STATUS, 0  
	movwf	var+1	    
	btfsc	STATUS, 0   
	goto	$-7	   
	goto unidades2	   
	return
    unidades2:
	clrf UNIDAD+1	    
	movlw	1	    
	subwf	var+1, F    
	btfsc	STATUS, 0   
	incf	UNIDAD+1	    
	btfss	STATUS, 0   
	return		    
	goto $-6

    decenas3:
	clrf DECENA+2	    	
	movlw	10	    
	subwf	var+2, W    
	btfsc	STATUS, 0   
	incf	DECENA+2	
	btfsc	STATUS, 0  
	movwf	var+2	    
	btfsc	STATUS, 0   
	goto	$-7	   
	goto unidades3	   
	return
    unidades3:
	clrf UNIDAD+2	    
	movlw	1	    
	subwf	var+2, F    
	btfsc	STATUS, 0   
	incf	UNIDAD+2	    
	btfss	STATUS, 0   
	return		    
	goto $-6
    ; ********		FIN	    ***********
    
    leds:
	BCF	TMR2IF
	MOVLW   0x01
	XORWF   PORTA
	BTFSC   indicador, 0
	call    cfindic
	return
;----------------------------OVERFLOW DEL RELOJ---------------------------------	
    OVERFLOWS:
	MOVLW 60
	SUBWF segundos, w
	btfsc ZERO
	goto MINS
    RETURN
    OVERFLOWM:
	MOVLW 60
	SUBWF minutos,  w
	btfsc ZERO
	goto HORS
    RETURN
    OVERFLOWH:
	MOVLW 24
	SUBWF horas, w
	BTFSC ZERO
	BCF horas, 0
    RETURN
    UNDERFLOWS:
	MOVLW 59
	MOVWF	segundos
    RETURN
    UNDERFLOWM:
	MOVLW 59
	MOVWF	minutos
    RETURN
    UNDERFLOWH:
	MOVLW 23
	MOVWF	horas
    RETURN
 ;----------------------OVERFLWO Y UNDERFLOW DEL TIMER--------------------------
    OVERFLOWST:
	MOVLW 60
	SUBWF TIMER, w
	btfsc ZERO
	CLRF  TIMER
    RETURN
    UNDERFLOWST:
	MOVLW	59
	MOVWF	TIMER
    RETURN
    OVERFLOWMT:
	MOVLW 100
	SUBWF TIMER+1, w
	btfsc ZERO
	CLRF  TIMER+1
    RETURN
    UNDERFLOWMT:
	MOVLW	99
	MOVWF	TIMER+1
    RETURN
;------------------------------UNDERFLOW----------------------------------------
    UNDERFLOWFD:
	MOVLW	31
	MOVWF	FECHA+0
    RETURN
 ;----------------------DEPOSITOS DE VALORES------------------------------------
    bancoRELOJ:
	MOVF    segundos, w
	MOVWF   var
	MOVF    minutos,  w
	MOVWF   var+1
	MOVF    horas,    w
	MOVWF   var+2
    return
    
    bancoTIMER:
	MOVF    TIMER+0, w
	MOVWF   var
	MOVF    TIMER+1,  w
	MOVWF   var+1
    return
    
    bancoFECHA:
	MOVF    FECHA+2, w
	MOVWF   var
	MOVF    FECHA+1,  w
	MOVWF   var+1
	MOVF    FECHA+0,  w
	MOVWF   var+2
    return
    ;-------------------SUBS ADICIONALES----------------------------------------
    cfindic:
	movlw 0x10
	XORWF PORTA
    return
    
    timing_dec:
	DECF	TIMER+0
	MOVF	TIMER+0
	BTFSC	ZERO
	goto	timing_dec0
	MOVLW	255
	SUBWF	TIMER+0, W
	BTFSC	ZERO
	call	Seguridad
    RETURN
    timing_dec0:
	MOVF	TIMER+1
	BTFSC	ZERO
	GOTO	BUZZER
	DECF	TIMER+1
	MOVLW	59
	MOVWF	TIMER+0
    RETURN
;    timing_dec1:
;	MOVF	TIMER+0
;	
;	BTFSC	ZERO
;	goto	BUZZER
;    RETURN
    BUZZER:
	BCF	TIMER, 0
	BCF	TIMER, 1
	BCF	indicador, 1
	BSF	PORTA, 5
    RETURN
    Seguridad:
	MOVLW	59
	MOVWF	TIMER+0
	DECF	TIMER+1
    RETURN
    APAGADO:
	CLRF SONIDO
	BCF PORTA, 5
    RETURN
    ;            //////////         ESTADOS       //////////////
    
INTB:				
    BTFSC PORTA, 2
    GOTO ESTADO1
    BTFSC PORTA, 3
    GOTO ESTADO2
    BTFSC subs,	 0
    GOTO confSEGS
    BTFSC subs,	 1
    GOTO confMINS
    BTFSC subs,	 2
    GOTO confHORS
    BTFSC subsTMR, 0
    GOTO segTMR
    BTFSC subsTMR, 1
    GOTO minTMR
    BTFSC subsFCH, 0
    GOTO monFCH
    BTFSC subsFCH, 1
    GOTO dayFHC
    BTFSC subsFCH, 2
    GOTO yearFCH
    
    ESTADO0:	
	BCF	funciones, 2
	BSF	funciones, 0;ESTADO0: RELOJ
	BCF	PORTA, 4
	BCF	indicador, 0
	BSF	PORTA, 1
	BTFSS	PORTB, BMODO
	call	flag0
		;FUNCIONES
	;	*****	    CONF  *********
	BTFSS	PORTB, FUNC
	call	sflags
	BCF	RBIF
	RETURN
	
    ESTADO1:			;ESTADO1: TIMER
	BCF	PORTA, 4
	BCF	indicador, 0
    
	BTFSS	PORTB, BMODO
	call	flag1
	BCF	PORTA, 1
	BCF	funciones, 0	;FUNCIONES
	BSF	funciones, 1
	
	BTFSS	PORTB, INIC
	call	APAGADO
	BTFSS	PORTB, FUNC
	call	tsflag
	BCF	RBIF
    RETURN
    
    ESTADO2:			;ESTADO1: FECHA
	BCF	PORTA, 4
	BCF	indicador, 0
	
	BTFSS	PORTB, BMODO
	CALL	flag2
	BCF	funciones, 1
	BSF	funciones, 2
	
	BTFSS	PORTB, FUNC
	call	mond_flag
	BCF	RBIF
    RETURN
    ;		*******		SUB CONF RELOJ	    ******
    confSEGS:
	BTFSS	PORTB, FUNC
	call	mflags
	BTFSS	PORTB, INIC
	BCF	subs, 0
	BTFSS	PORTB, UP
	INCF	segundos
	    call    OVERFLOWS 
	BTFSS	PORTB, DOWN
	DECF	segundos
	    MOVLW   255
	    SUBWF   segundos, W
	    BTFSC   ZERO
	    CALL    UNDERFLOWS
	 BSF	indicador, 0   
	 BCF	RBIF
    RETURN
    confMINS:
	BTFSS	PORTB, FUNC
	call	hflags
	BTFSS	PORTB, INIC
	BCF	subs, 1
	BTFSS	PORTB, UP
	INCF	minutos
	    call    OVERFLOWM 
	BTFSS	PORTB, DOWN
	DECF	minutos
	    MOVLW   255
	    SUBWF   minutos, W
	    BTFSC   ZERO
	    CALL    UNDERFLOWM
	    BCF	RBIF
    RETURN
    confHORS:
	BTFSS	PORTB, FUNC
	call	rflags
	BTFSS	PORTB, INIC
	BCF	subs, 2
	BTFSS	PORTB, UP
	INCF	horas
	    MOVLW 24
	    subwf   horas, w
	    BTFSC ZERO
	    CLRF horas
	BTFSS	PORTB, DOWN
	DECF	horas
	    MOVLW   255
	    SUBWF   horas, w
	    BTFSC   ZERO
	    call    UNDERFLOWH
	 BCF	RBIF
    RETURN
    ;		*****	    SUBS CONF TIMER	    *****
    segTMR:
	BTFSS	PORTB, FUNC
	call	tmflag
	BTFSS	PORTB, INIC
	call	tcflag
	
	BTFSS	PORTB, UP
	INCF	TIMER
	    call    OVERFLOWST
	BTFSS	PORTB, DOWN
	DECF	TIMER
	    MOVLW   255
	    SUBWF   TIMER, W
	    BTFSC   ZERO
	    call    UNDERFLOWST
	BSF	indicador, 0
	BCF	RBIF
    RETURN
    minTMR:
	BTFSS	PORTB, FUNC
	call	tbflag
	BTFSS	PORTB, INIC
	call	tcflag
	
	BTFSS	PORTB, UP
	INCF	TIMER+1
	    call    OVERFLOWMT 
	BTFSS	PORTB, DOWN
	DECF	TIMER+1
	    MOVLW   255
	    SUBWF   TIMER+1, W
	    BTFSC   ZERO
	    call    UNDERFLOWMT
	BCF	RBIF
    RETURN
    
    ;		******		SUBS CONF FECHA	    *******
    monFCH:
	BTFSS	PORTB, FUNC
	call	day_flag
	BTFSS	PORTB, INIC
	call	saved_flag
	
	BTFSS	PORTB, UP
	INCF	FECHA+1
	    MOVLW 13
	    subwf   FECHA+1, w
	    BTFSC ZERO
	    CLRF FECHA+1
	BTFSS	PORTB, DOWN
	DECF	FECHA+1
	BSF	indicador, 0
	BCF	RBIF
    RETURN
    
    dayFHC:
	BTFSS	PORTB, FUNC
	call	year_flag
	BTFSS	PORTB, INIC
	call	saved_flag
	
	BTFSS	PORTB, UP
	INCF	FECHA+0
	BTFSS	PORTB, DOWN
	DECF	FECHA+0
	BCF	RBIF
	    MOVLW 32
	    subwf   FECHA+0, w
	    BTFSC ZERO
	    CLRF FECHA+0
    RETURN
    
    yearFCH:
	BTFSS	PORTB, FUNC
	call	return_flag
	BTFSS	PORTB, INIC
	call	saved_flag
	
	BTFSS	PORTB, UP
	INCF	FECHA+2
	    MOVLW 100
	    subwf   FECHA+2, w
	    BTFSC ZERO
	    CLRF FECHA+2
	BTFSS	PORTB, DOWN
	DECF	FECHA+2
	BCF	RBIF
    RETURN
    
    
RETURN
    
        ;       ******* banderas de estado *******
    flag0:
	BCF PORTA, 1
	BSF PORTA, 2
    return
    flag1:
	BCF PORTA, 2
	BSF PORTA, 3
    return
    flag2:
	BCF PORTA, 3
    return
    ;	    ****	BANDERAS DE CONF RELOJ	*****
    sflags:
	BCF PORTA, 1
	BSF subs, 0
    return
    mflags:
	BCF subs, 0
	BSF subs, 1
    return
    hflags:
	BCF subs, 1
	BSF subs, 2
    return
    rflags:
	BCF subs, 2
	BSF subs, 0
    return
    ;	    *****	banderas de TIMER	*****
    tsflag:
	BCF PORTA, 2
	BSF subsTMR, 0
    return
    tmflag:
	BCF subsTMR, 0
	BSF subsTMR, 1
    return
    tbflag:
	BCF subsTMR, 1
	BSF subsTMR, 0
    return
    tcflag:
	BCF nocero, 0
	BCF subsTMR, 0
	BCF subsTMR, 1
	BSF PORTA,   2
	MOVF	TIMER+1, w
	BTFSC ZERO  
	CALL SEGURIDAD2
	BTFSS nocero, 0
	BSF indicador, 1
    return
    SEGURIDAD2:
	MOVF TIMER+0, w
	BTFSC ZERO
	BSF nocero, 0
    RETURN
    ;	    *****	banderas de fecha	******
    mond_flag:
	BCF PORTA,	3
	BSF subsFCH,	0
    RETURN
    
    day_flag:
	BCF subsFCH,	0
	BSF subsFCH,	1
    RETURN
    
    year_flag:
	BCF subsFCH,	1
	BSF subsFCH,	2
    RETURN
    
    return_flag:
	BCF subsFCH,	2
	BSF subsFCH,	0
    RETURN
    
    
    saved_flag:
	BCF subsFCH,	2
	BCF subsFCH,	1
	BCF subsFCH,	0
	BSF PORTA,	3
    RETURN
    
    UNDERFLOWRELOJ:
	movlw 255
	subwf horas, w
	BTFSC ZERO
	call UNDERFLOWH
    return
    
    ;	    ******	    MUESTRA Y AUMNENTA
    
    AUMENTO:
    RESET_TMR1 0xC2, 0xF7
    INCF segundos
    ;reinicio
    CALL OVERFLOWS
    CALL OVERFLOWM
    MOVLW 24
    subwf   horas, w
    BTFSC ZERO
    CLRF horas
    
    BTFSC indicador, 1
    goto  timing_dec
    
    BTFSC PORTA, 5
    INCF  SONIDO
    
    call UNDERFLOWRELOJ
    
    MOVLW 60
    SUBWF SONIDO, W
    BTFSC ZERO
    GOTO  APAGADO
    RETURN
    
int_tmr0:
    RESET_TMR0 254
    clrf PORTD
    BTFSC   bandera, 0
    goto    dis2
    BTFSC   bandera, 1
    goto    dis3
    BTFSC   bandera, 2
    goto    dis4
    BTFSC   bandera, 3
    goto    dis5
    BTFSC   bandera, 4
    goto    dis6
    
dis1:
    movf    display, w
    movwf   PORTC
    BSF	    PORTD, 0
    BCF	    bandera, 3
    BSF	    bandera, 0
    return
dis2:
    movf    display+1, w
    movwf   PORTC
    BSF	    PORTD, 1
    BCF	    bandera, 0
    BSF	    bandera, 1
    return
dis3:
    movf    display+2, w
    movwf   PORTC
    BSF	    PORTD, 2
    BCF	    bandera, 1
    BSF	    bandera, 2
    return
dis4:
    movf   display+3, w
    movwf   PORTC
    BSF	    PORTD, 3
    BCF	    bandera, 2
    BSF	    bandera, 3
    return
dis5:
    movf    display+4, w
    movwf   PORTC
    BSF	    PORTD, 4
    BCF	    bandera, 3
    BSF	    bandera, 4
    return
dis6:
    movf   display+5, w
    movwf   PORTC
    BSF	    PORTD, 5
    BCF	    bandera, 4
    BSF	    bandera, 5
    return
;------------------------------------------------------------------------------
ORG 200h    
Tabla:			    ;TABLA DEL PROGRAM COUNTER
    CLRF PCLATH
    BSF PCLATH, 1
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
    