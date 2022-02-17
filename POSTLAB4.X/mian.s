; Archivo: POSTALB4.s
; Dispositivo: PIC16F887
; Autor: Jose Pablo Petion - 201151
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: CONTADOR CON TIMER0
; Hardware: 2 displays
;
; Creado: 16 feb, 2022
; Última modificación: 16 feb, 2022

PROCESSOR 16F887
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

;-------------------------------------------------------------------------------
 
REINICIO MACRO	    ;MACRO - EJECUTA SIMULTANEAMENTE
    BANKSEL PORTA   ;Es el reinicio del TMR0
    MOVLW   61
    MOVWF   TMR0
    BCF	    T0IF    ;LIMPIA LA BANDERA TMR0
    ENDM
 
PSECT udata_bank0   ;BANCO DE VARIABLES
 cont:	    DS	2   ;CONTADOR DE TMR0
 CONT2:     DS  2   ;CONTADOR DEL DISPLAY 2 (DECENAS)
PSECT udata_shr
 WTEMP:	    DS	1
 STSTEMP:   DS	1

PSECT resVect, class=code, abs, delta=2
;-----------------------------VECTOR DE RESETE----------------------------------
ORG 00h
  resVect:
    PAGESEL main
    GOTO main  
  PSECT code, delta=2, abs
;-----------------------VECTOR DE INTERRUPCIÓN----------------------------------
ORG 04h

PUSH:
    movwf WTEMP
    swapf STATUS, W
    movwf STSTEMP

isr:		    ;VERIFICACION DE BANDERA PARA INTERRUPCION
    BTFSC T0IF
    call INTERR2
    
POP:
    SWAPF STSTEMP, W
    MOVWF STATUS
    SWAPF WTEMP, F
    SWAPF WTEMP, W
    RETFIE
INTERR2:	    ;RUTINA DE INTERRUPCIÓN
    REINICIO
    INCF cont
    MOVF cont, w
    sublw 10
    btfss STATUS, 2 ;ANTIREBOTE PARA El TMR0
    goto RTRN
    CLRF cont
    incf PORTC	    ;INCREMENTA EL CONTADOR
    btfsc PORTC, 4  ;VERIFICA QUE SEA DE 4bits
    CLRF PORTC	    ;DE LO CONTRARIO REINCIA
    MOVF PORTC, W   ;MUEVE EL REGISTRO PARA LLEVARLO AL PGC
    Call Tabla	    ;LLEVA A LA TABLA DEL PGC
    MOVWF PORTD
    MOVLW 10
    SUBWF PORTC, W  
    BTFSC ZERO	    ;VERIFICA SI EL CONTADOR LLEGO A 10
    Call INCD2	    ;LLAMA UNA RUTINA DE REINICIO
    RETURN
    RTRN:	    ;RUTINA DE ANTIREBOTE
    return
INCD2:		    ;INCREMENTO DEL DISPLAY 2 (DECENAS)
    CLRF PORTC
    INCF CONT2
    MOVF CONT2, W
    Call Tabla
    MOVWF PORTA
    MOVLW 6
    SUBWF CONT2, W
    BTFSC ZERO	    ;VERIFICA QUE LLEGUEN A SU VALOR MAXIMO
    call LIMITE	    ;LLAMA AL REINCIO DE LOS CONTADORES
    RETURN
LIMITE:		    ;RUTINA DE REINCIO
    CLRF PORTA
    CLRF CONT2
    RETURN
PSECT code, delta=2, abs
 ORG 100h
;--------------------------MICRO CONTROLADOR------------------------------------
PSECT code, delta=2, abs
ORG 0100h
 
Tabla:			    ;TABLA DEL PROGRAM COUNTER
    CLRF PCLATH
    BSF PCLATH, 0
    ADDWF PCL, 1
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
    
 return
;-----------------------------------main----------------------------------------
main:			    ;CONF PRINCIPAL
    call CONF		    ;LLAMADO DE RUTINAS
    call RELOJ
    call TIMER0
    call INTER2
    
    banksel PORTA
loop:
    goto loop
;--------------------------------SUBRUTINAS-------------------------------------
 CONF:			    ;RUTINA DE CONFIGURACIÓN
    bsf	STATUS, 5
    bsf	STATUS, 6
    CLRF ANSEL
    CLRF ANSELH
    bsf	STATUS, 5
    bCf	STATUS, 6
    CLRF TRISA		    ;SALIDA DE PUERTOS
    CLRF TRISD
    CLRF TRISC
    bCf	STATUS, 5
    bCf	STATUS, 6
    CLRF PORTD		    ;SALIDA FISICA DE PUERTOS
    CLRF PORTC
    CLRF PORTA
    return
    
RELOJ:			    ;RELOJ INTERNO OSCILADOR
    banksel OSCCON
    BSF IRCF2
    BSF IRCF1
    BCF IRCF0
    BSF SCS
    return
    
TIMER0:			    ;SETEO DEL TIMER0 Y PRESCALER
    banksel TRISA
    BCF T0CS
    BCF PSA
    BSF PS2
    BSF PS1
    BSF PS0
    REINICIO 
    return
INTER2:			    ;SETEO DE BANDERAS DE INTERRUPCION DEL TIMER0
    BSF GIE
    BSF T0IE
    BCF T0IF
    RETURN