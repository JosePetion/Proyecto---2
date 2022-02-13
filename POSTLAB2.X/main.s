; Archivo: POST-LABORATORIO3.s
; Dispositivo: PIC16F887
; Autor: Jose Pablo Petion - 201151
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: Contador de boton y Contador doble
; Hardware: Indicador
;
; Creado: 9 feb, 2022
; Última modificación: 12 feb, 2022
    
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

;--------------------Vector de Reseteo-----------------------------------
PSECT resVect, class=code, abs, delta=2
  ORG 00h				    ; posición del vector de reseteo
  resVect:
    GOTO main
    
  PSECT code, delta=2, abs
  ORG 100H
;----------------------Tabla-----------------------------------------------
  TABLA:
    clrf PCLATH
    BSF PCLATH, 0
    ANDLW 0x0f
    ADDWF PCL
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;b
    retlw 00111001B ;C
    retlw 01011110B ;d
    retlw 01111001B ;e
    retlw 01110001B ;F
    
    return
;----------------------Configuración---------------------------------------
main:			    ;Programa principal
    call CONF		    ;Llama a mis rutinas
    CALL RELOJ		    
    call TMR0_CONF
    BANKSEL PORTA	    ;Cambia banco
    
CHECK:
    BTFSC PORTA, 0	    ;Verifica boton 1
    call INCB		    
    BTFSC PORTA, 1	    ;Verifica boton 2
    call DECB
    CALL cuatrobits	    ;Mantiene 4bits
    
    BTFSS T0IF		    ;Contador sin botones
    goto $-1
    CALL REINICIO
    incf PORTB		
    CALL cuatrobitsB	    ;Mantiene 4Bits
    
    call ALARMA		    ;Verifica si la alarma debe encenderse
    goto CHECK
;-------------------------SUBRUTINAS---------------------------------------
CONF:		    ;SUBR. de configuración
    banksel ANSEL   ;Salidas de la suma
    CLRF ANSEL
    CLRF ANSELH
    banksel TRISC
    BSF TRISA, 0    ;Incremento
    BSF TRISA, 1    ;Decremento
    BCF TRISA, 2
    CLRF TRISB
    CLRF TRISC
    CLRF TRISD
    banksel PORTC
    CLRF TRISB
    CLRF TRISC
    CLRF TRISD
    CLRF TRISA
    RETURN

 INCB:			    ;ANTIREBOTE INCREMENTO
    BTFSC PORTA, 0	    ;verifica si hay un cambio
    goto $-1		    ;si existe sale del loop, si no regresa a la linea anterior
    INCF PORTC
    MOVF PORTC, W	    ;Si existe un cambio incrementa
    Call TABLA
    MOVWF PORTD
    return
  DECB:
    BTFSC PORTA, 1	    ;ANTIREBOTE DECREMENTO
    goto $-1
    DECF PORTC		    ;DECREMENTA si hay un cambio
    MOVF PORTC, W
    Call TABLA
    MOVWF PORTD		    ;Mueve el valor al puerto D
    return
   RELOJ:
    BANKSEL OSCCON
    BSF OSCCON, 0 ;RELOJ INTERNO
    BCF OSCCON, 4
    BSF OSCCON, 5
    BCF OSCCON, 6 ;500kHz
    return
   cuatrobits:	    ;Limita a 4 bits Puerto B
    movLW 16
    SUBwf PORTC, W
    BTFSC ZERO	    ;Si la resta es 0 reinicia el puerto
    CLRF PORTC
    RETURN
    
    cuatrobitsB:	    ;Limita a 4 bits puerto B
    movLW 16
    SUBwf PORTB, W
    BTFSC ZERO
    CLRF PORTB
    RETURN
    
TMR0_CONF:	    ; Configuracion del timer0
    banksel TRISA
    BCF T0CS
    BCF PSA
    BSF PS2
    BSF PS1
    BSF PS0	    ;PRESCALER 1:256
    banksel PORTA
    CALL REINICIO
    Return
    
 REINICIO:
    banksel TMR0    
    MOVLW 10	    ;100ms
    MOVWF TMR0	    ;Valor inicial
    BCF T0IF	    ;Limpia bandera
    ReturN
    
ALARMA:		    ;subr. de alarma
    MOVF PORTC, 0
    SUBWF PORTB, W  ;resta los valores
    BTFSC ZERO	    ;verifica si es 0
    call INDICADOR
    return
INDICADOR:	    ;subr. Indicador
    CLRF PORTB	    ;Reinicia el contador
    MOVLW 0x04	    ;se posiciona en el pueroA, 2
    XORWF PORTA	    ;ALTERNA EL VALOR DE LA SALIDA
    RETURN
END
    