/* 
 * File:   POSTALB7
 * Author: Jose Pablo Petion Rivas
 * VIDEO EN YOUTUBE: https://youtu.be/usYaVQUmGqw
 * REPOSITORIO EN GITHUB: https://github.com/JosePetion/POSTLAB7.git
 * Created on April 5, 2022, 3:50 PM
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

#include <xc.h>
#include <stdint.h>


#define UP PORTBbits.RB0
#define DOWN PORTBbits.RB1

int unidad=0;
int decena=0;
int centena=0;
int residuo=0;
int bandera=0;
char tabla[10]={0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 
0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111};




void __interrupt() isr(void){
        
    if(INTCONbits.TMR0IF){
        switch (bandera){
            case 0:
                PORTD=1;
                PORTC=tabla[unidad];
                bandera=1;
                break;
            case 1:
                PORTD=2;
                PORTC=tabla[decena];
                bandera=2;
                break;
            case 2:
                PORTD=4;
                PORTC=tabla[centena];
                bandera=0;
                break;
        }
    INTCONbits.TMR0IF = 0;
        TMR0 = 252;
    }
    
    if(INTCONbits.RBIF){
        if(!UP){PORTA++;}
        if(!DOWN){PORTA--;}    
            INTCONbits.RBIF = 0;
    }}

void setup(void);

void main(void){
    setup();
    while(1){
        valores();
    }
}
void setup(void){
    ANSEL = 0;
    ANSELH = 0;
    
    TRISA = 0;     
    PORTA = 0;      
    TRISC = 0;      
    PORTC = 0;
    TRISD = 0;
    PORTD = 0;
    
    OSCCONbits.IRCF = 0b0101;
    OSCCONbits.SCS = 1;        
   
    TRISB = 0b00000011;      
    PORTB = 0;      
    
    
    TRISBbits.TRISB0 = 1;   
    TRISBbits.TRISB1 = 1;   
    OPTION_REGbits.nRBPU = 0; 
    WPUBbits.WPUB0 = 1;
    WPUBbits.WPUB1 = 1;
    INTCONbits.GIE = 1;
    INTCONbits.RBIE = 1;
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    INTCONbits.RBIF = 0;
     
    
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.T0SE = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;

    TMR0 = 252;
    INTCONbits.TMR0IF = 0;
    INTCONbits.TMR0IE = 1;
    
return;
}

int valores(){
    centena = PORTA/100;
    residuo = PORTA%100;
    decena = residuo/10;
    unidad = residuo%10;
}