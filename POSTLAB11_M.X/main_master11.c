/* 
 * File:   main_master11.c
 * Author: Jose Pablo Petion
 * 
 * Created on May 13, 2022, 4:17 PM
 */


// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT    // Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF               // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF              // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF              // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF                 // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF                // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF              // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF               // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF              // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF                // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V           // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF                // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h>

/*------------------------------------------------------------------------------
 * CONSTANTES 
 ------------------------------------------------------------------------------*/

#define _XTAL_FREQ 1000000    // Frec. 1 MHz
#define FLAG_SPI 0xFF         // Bandera de lectura

/*------------------------------------------------------------------------------
 * VARIABLES 
 ------------------------------------------------------------------------------*/
uint8_t poten;            // Valor de lectura del potenciómetro (Maestro)

/*------------------------------------------------------------------------------
 * PROTOTIPO DE FUNCIONES 
 ------------------------------------------------------------------------------*/
void setup(void);

/*------------------------------------------------------------------------------
 * INTERRUPCIONES 
 ------------------------------------------------------------------------------*/
void __interrupt() isr (void){
    
    if(PIR1bits.ADIF){                          // ADC
        if(ADCON0bits.CHS == 0){                // CANAL: AN0
            poten = ADRESH;}
            PIR1bits.ADIF = 0;} 
    return;
}

/*------------------------------------------------------------------------------
 * CICLO PRINCIPAL
 ------------------------------------------------------------------------------*/

void main(void) {
    
    setup();
    while(1){
        
        
        if(ADCON0bits.GO == 0){              // Conversión ADC
            __delay_us(50);
            ADCON0bits.GO = 1;
        }
        
        // ENVIO-ESCLAVO1
        PORTAbits.RA7 = 1;           
        SSPBUF = poten;                     //Carga de buffer
        while(!SSPSTATbits.BF){}     
        PORTAbits.RA7 = 0;
        
        //Selector (ss)
        PORTAbits.RA6 = 1;
        PORTAbits.RA7 = 1;
        __delay_ms(15);
        PORTAbits.RA7 = 0;
        SSPBUF = FLAG_SPI;                  //Inicio del master
        while(!SSPSTATbits.BF){}
        PORTD = SSPBUF;                     //PORTD=RECIBIDO
        PORTAbits.RA6 = 0;
        
    }
    return;
    
}

/*------------------------------------------------------------------------------
 * SETUP 
 ------------------------------------------------------------------------------*/
void setup(void){       
    
    ANSEL = 0b001;
    ANSELH = 0x00;      
    TRISA = 0b00000001;
    TRISC = 0b00010000;
    PORTCbits.RC4 = 0;
    TRISD = 0;
    PORTA = 0;
    PORTC = 0;
    PORTD = 0;
    
    OSCCONbits.IRCF = 0b100;                      // 1MHz
    OSCCONbits.SCS = 1;
    
    // INTERRUPCIONES
    PIR1bits.ADIF = 0; 
    PIE1bits.ADIE = 1;
    INTCONbits.PEIE = 1;    
    INTCONbits.GIE = 1; 
    
    //ADC
    ADCON0bits.ADCS = 0b01;                     // Fosc/8
    ADCON1bits.VCFG0 = 0;                       // VDD
    ADCON1bits.VCFG1 = 0;                       // VSS
    ADCON0bits.CHS = 0b0000;                    // canal AN0
    ADCON1bits.ADFM = 0;                        // justificado a la izquierda
    ADCON0bits.ADON = 1;                        // HabilitacióN ADC
    __delay_us(50);                             
        
    // SPI MAESTRO    SSPCON<5:0>
    SSPCONbits.SSPM = 0b0000;   // SPI Maestro, Reloj -> Fosc/4 (250kbits/s)
    SSPCONbits.CKP = 0;         // Reloj-0
    SSPCONbits.SSPEN = 1;
    
    // SSPSTAT<7:6>
    SSPSTATbits.CKE = 1;
    SSPSTATbits.SMP = 1;        
    SSPBUF = poten;
}