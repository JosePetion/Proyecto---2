/* 
 * File:   main_Postlab.c
 * Author: Jose Pablo Petion
 *
 * Created on April 30, 2022, 9:31 AM
 *
 *
 * Video Youtube: https://youtu.be/3Np2DQ3Vyog
 * Created on April 25, 2022, 2:42 PM
 */

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h>

/*------------------------------------------------------------------------------
 * CONSTANTES 
 ------------------------------------------------------------------------------*/
#define _XTAL_FREQ 4000000
#define IN_MIN 0                // Valor minimo de entrada del potenciometro
#define IN_MAX 255              // Valor máximo de entrada del potenciometro
#define OUT_MIN 0               // Valor minimo de ancho de pulso de señal PWM
#define OUT_MAX 804             // Valor máximo de ancho de pulso de señal PWM


/*------------------------------------------------------------------------------
 * VARIABLES 
 ------------------------------------------------------------------------------*/
unsigned short CCPR = 0;        // Variable para almacenar ancho de pulso al hacer la interpolación lineal
unsigned short CCPR_2 = 0;
uint8_t ADDRESS;
uint8_t escala;
/*------------------------------------------------------------------------------
 * PROTOTIPO DE FUNCIONES 
 ------------------------------------------------------------------------------*/
void setup(void);
unsigned short map(uint8_t val, uint8_t in_min, uint8_t in_max, 
            unsigned short out_min, unsigned short out_max);
/*------------------------------------------------------------------------------
 * INTERRUPCIONES 
 ------------------------------------------------------------------------------*/
void __interrupt() isr (void){
    if(PIR1bits.ADIF){                      // Fue interrupción del ADC?
        if(ADCON0bits.CHS == 0){            // Verificamos sea AN0 el canal seleccionado
            CCPR = map(ADRESH, IN_MIN, IN_MAX, OUT_MIN, OUT_MAX); // Valor de ancho de pulso
            CCPR1L = (uint8_t)(CCPR>>2);    // Guardamos los 8 bits mas significativos en CPR1L
            CCP1CONbits.DC1B = CCPR & 0b11; // Guardamos los 2 bits menos significativos en DC1B
        }
        else if (ADCON0bits.CHS==1){
            PORTD = ADRESH;
            CCPR_2 = map(ADRESH, IN_MIN, IN_MAX, OUT_MIN, OUT_MAX);
            CCPR2L = (uint8_t)(CCPR_2>>2);
            CCP2CONbits.DC2B0 = CCPR_2 & 0b1;
            CCP2CONbits.DC2B1 = CCPR_2 & 0b10;
        }
        else if(ADCON0bits.CHS==2){ADDRESS = ADRESH;
        PIR1bits.ADIF = 0;}
        
        PIR1bits.ADIF = 0;                  // Limpiamos bandera de interrupción
    }
    //Cambio de pulso de TIMER 0
    if (INTCONbits.T0IF){
        INTCONbits.T0IF = 0; 
        TMR0 = 248;
        escala++;
        if(escala < ADDRESS) {PORTCbits.RC3 = 1;}  
        else {PORTCbits.RC3 = 0;} 
        INTCONbits.T0IF = 0;    // Reinicio del conteo del timer
    }
    return;
}

/*------------------------------------------------------------------------------
 * CICLO PRINCIPAL
 ------------------------------------------------------------------------------*/
void main(void) {
    setup();
    while(1){
        if(ADCON0bits.GO == 0)
        {
            if (ADCON0bits.CHS == 0){ADCON0bits.CHS = 0b0001;}
            else if (ADCON0bits.CHS == 1){ADCON0bits.CHS = 0b0010;}
            else {ADCON0bits.CHS = 0b0000;}
            __delay_us(40);
            ADCON0bits.GO = 1;
        }
    }
    return;
}

/*------------------------------------------------------------------------------
 * CONFIGURACION 
 ------------------------------------------------------------------------------*/
void setup(void){
    ANSEL = 0b111;                // AN0 como entrada analógica
    ANSELH = 0;                 // I/O digitales
    TRISA = 0b111;                // AN0 como entrada
    PORTA = 0;
    TRISD=0X00;
    PORTD=0X00;
    //CONF TIMER 0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.T0SE = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 0;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 0;
    TMR0 = 248;
    
    // Configuración reloj interno
    OSCCONbits.IRCF = 0b110;    // 4MHz
    OSCCONbits.SCS = 1;         // Oscilador interno
    
    // Configuración ADC
    ADCON0bits.ADCS = 0b01;     // Fosc/8
    ADCON1bits.VCFG0 = 0;       // VDD
    ADCON1bits.VCFG1 = 0;       // VSS
    ADCON0bits.CHS = 0b0000;    // Seleccionamos el AN0
    ADCON1bits.ADFM = 0;        // Justificado a la izquierda
    ADCON0bits.ADON = 1;        // Habilitamos modulo ADC
    __delay_us(60);             // Sample time
    
    // Configuración PWM
    TRISCbits.TRISC1 = 1;
    TRISCbits.TRISC2 = 1;       // Deshabilitamos salida de CCP1
    PR2 = 200;                  // periodo de 2ms
    
    // Configuración CCP
    CCP1CON = 0;                // Apagamos CCP1
    CCP2CON = 0;                // Apagar   CCP2
    CCP1CONbits.P1M = 0;        // Modo single output
    CCP1CONbits.CCP1M = 0b1100; // PWM
    CCP2CONbits.CCP2M = 0b1100;
    
    CCPR1L = 125>>2;
    CCPR2L = 125>>2;
    CCP1CONbits.DC1B = 0;    // 0.5ms ancho de pulso / 25% ciclo de trabajo
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    PIR1bits.TMR2IF = 0;        // Limpiamos bandera de interrupcion del TMR2
    T2CONbits.T2CKPS = 0b11;    // prescaler 1:16
    T2CONbits.TMR2ON = 1;       // Encendemos TMR2
    while(!PIR1bits.TMR2IF);    // Esperar un cliclo del TMR2
    PIR1bits.TMR2IF = 0;        // Limpiamos bandera de interrupcion del TMR2 nuevamente
    
    TRISCbits.TRISC1 = 0;       // Habilitamos salida de PWM
    TRISCbits.TRISC2 = 0;
    TRISCbits.TRISC3 = 0;

    // Configuracion interrupciones
    PIR1bits.ADIF = 0;          // Limpiamos bandera de ADC
    PIE1bits.ADIE = 1;          
    INTCONbits.PEIE = 1;        
    INTCONbits.GIE = 1;         
    
}

/*interpolación
*  y = y0 + [(y1 - y0)/(x1-x0)]*(x-x0)
*  -------------------------------------------------------------------
*  | x0 -> valor mínimo de ADC | y0 -> valor mínimo de ancho de pulso|
*  | x  -> valor actual de ADC | y  -> resultado de la interpolación | 
*  | x1 -> valor máximo de ADC | y1 -> valor máximo de ancho de puslo|
*  ------------------------------------------------------------------- 
*/
unsigned short map(uint8_t x, uint8_t x0, uint8_t x1, 
            unsigned short y0, unsigned short y1){
    return (unsigned short)(y0+((float)(y1-y0)/(x1-x0))*(x-x0));
}   