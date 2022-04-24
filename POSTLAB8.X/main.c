/* 
 * File:   POSTLAB 8
 * Author: Jose Pablo Petion
 *
 * Created on April 21, 2022, 10:54 PM
 * R2R DAC y Voltimetro
 * Link de video en YouTube: https://youtu.be/vZ5DzHzznss
 */


// PIC16F887 Configuration Bit Settings

// 'C' source line config statements

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


/*
 * Constantes
 */
#define _XTAL_FREQ 4000000
/*
 * Variables
 */
char tabla[10]={0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 
0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111};          
int contador2 = 0;          //VALORES DEL ADRESH CONTADOR2
int unidad=0;
int decena=0;
int centena=0;
int residuo=0;
int bandera=0;
int valor = 0;              //OPERADOR PARA RESOLUCIÓN
/*
 * Funciones
 */

/*
 * Interrupciones
 */

void __interrupt() isr(void){
    if(INTCONbits.TMR0IF){              // MULTIPLEXEO DISPLAYS
        switch (bandera){
            case 0:
                PORTB=1;
                PORTD=tabla[unidad];
                bandera=1;
                break;
            case 1:
                PORTB=2;
                PORTD=tabla[decena];
                bandera=2;
                break;
            case 2:
                PORTB=4;
                PORTD=tabla[centena] | 0b10000000; //El punto decimal re enciende con OR 
                bandera=0;
                break;
        }
    INTCONbits.TMR0IF = 0;
        TMR0 = 248;
    }
    if (PIR1bits.ADIF){                 // CONVERTIDOR ADC CON CANALES
        if (ADCON0bits.CHS==0)
        {PORTC=ADRESH;}
        else if (ADCON0bits.CHS==1)
        {contador2=ADRESH;
        valor=contador2*2;              //Tipo de resolución *2
        if (valor==510){valor=500;}}    //Condición a maximo 5v
        PIR1bits.ADIF=0;
    }
}
/*
 * LOOP
 */
void setup(void);
void main(void) {
    setup();
    ADCON0bits.GO = 1;
    while(1){
         centena = valor/100;           //VALORES EN U,D y C
         residuo = valor%100;
         decena = residuo/10;
         unidad = residuo%10;
         
        if(ADCON0bits.GO == 0)          //Inicio de conversion para canales
        {
            if (ADCON0bits.CHS == 0){ADCON0bits.CHS = 0b0001;}
            else {ADCON0bits.CHS = 0b0000;}
            __delay_us(40);
            ADCON0bits.GO = 1;
        }
    }
    return;
}

/*
 * config
 */
void setup(void){
    ANSEL=0b00000011;     //AN0 ENTRADA ANALOGICA    
    ANSELH=0;
    
    TRISA=0b00000011;
    PORTA=0;
    TRISB=0X00;
    PORTB=0X00;
    TRISC=0X00;
    PORTC=0;
    TRISD=0X00;
    PORTD=0;
    //CLOCK
    OSCCONbits.IRCF = 0b0110;    //4MHz
    OSCCONbits.SCS = 1;
    
    //CONF DEL ADC
    ADCON0bits.ADCS = 0b01;
    ADCON1bits.VCFG1 = 0;   //Vss
    ADCON1bits.VCFG0 = 0;   //Vdd
    
    ADCON0bits.CHS = 0b0000;
    ADCON1bits.ADFM = 0; 
    ADCON0bits.ADON = 1;
    __delay_us(40);
    
    //INTERRUP
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;
    INTCONbits.PEIE = 1; 
    INTCONbits.GIE = 1;
    
    //TMR0 config
    
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.T0SE = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;     //Prescaler 1:256
    OPTION_REGbits.PS1 = 1; 
    OPTION_REGbits.PS0 = 1;
    TMR0 = 248;
    INTCONbits.TMR0IF = 0;
    INTCONbits.TMR0IE = 1;
    return;
}

