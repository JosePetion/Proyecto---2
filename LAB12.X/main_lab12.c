/* 
 * File:   main_lab12.c
 * Author: Jose Pablo Petion
 *
 * Created on May 16, 2022, 5:29 PM
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
#define _XTAL_FREQ 1000000

/*------------------------------------------------------------------------------
 * VARIABLES 
 ------------------------------------------------------------------------------*/
uint8_t poten = 0;
uint8_t duerme = 0, direccion = 0;

/*------------------------------------------------------------------------------
 * PROTOTIPO DE FUNCIONES 
 ------------------------------------------------------------------------------*/
void setup(void);
uint8_t read_EEPROM(uint8_t direccion);
void write_EEPROM(uint8_t direccion, uint8_t data);

/*------------------------------------------------------------------------------
 * INTERRUPCIONES 
 ------------------------------------------------------------------------------*/
void __interrupt() isr (void){
    if(PIR1bits.ADIF){                   //  ADC?
        poten = ADRESH;              
        PORTD = poten;                    //Mostrarlo en el puerto D
        PIR1bits.ADIF = 0;              // Limpiamos bandera
    }
    else if(INTCONbits.RBIF){           
        if(!PORTBbits.RB0){                   
            if(duerme==1){  
                duerme = 0;
            }
            else{               
                write_EEPROM(direccion, poten);
                duerme = 1;
            }
        }
        INTCONbits.RBIF = 0;        
    }
    return;
}

/*------------------------------------------------------------------------------
 * LOOP PRINCIPAL
 ------------------------------------------------------------------------------*/
void main(void) {
    setup();
    while(1){ 
        if(ADCON0bits.GO == 0){         //ADC
            ADCON0bits.GO = 1;       
        }
        if(duerme == 1){           
            PIE1bits.ADIE = 0;
            SLEEP();                   //sleep
        }
        else if(duerme == 0){            
            PIE1bits.ADIE = 1;
        }
        PORTC = read_EEPROM(direccion);
        
        __delay_ms(500);
        if (PORTAbits.RA1 == 0)
            PORTAbits.RA1 = 1;
        else
            PORTAbits.RA1 = 0;
    }
    return;
}

/*------------------------------------------------------------------------------
 * CONFIGURACION 
 ------------------------------------------------------------------------------*/
void setup(void){
    ANSEL = 0b00000001;
    ANSELH = 0;
    
    TRISB = 0b00000001;;
    PORTB = 0;
    
    TRISA = 0b00000001;
    TRISC = 0;
    TRISD = 0;
    
    PORTC = 0;
    PORTD = 0;
    PORTA = 0;
    
    // Configuracion ADC
    ADCON0bits.ADCS = 0b00;     // Fosc/2
    ADCON1bits.VCFG0 = 0;       // VDD
    ADCON1bits.VCFG1 = 0;       // VSS
    ADCON0bits.CHS = 0;    
    ADCON1bits.ADFM = 0;        //  izquierda
    ADCON0bits.ADON = 1;        // Habilitamos ADC
    __delay_us(40);             

    
    PIR1bits.ADIF = 0;  
    PIE1bits.ADIE = 1;
    INTCONbits.PEIE = 1;  
    INTCONbits.GIE = 1;     
    OPTION_REGbits.nRBPU = 0; 
    WPUB = 0x01;
    INTCONbits.RBIE = 1;   
    IOCB = 0x01;         
    INTCONbits.RBIF = 0;
}


uint8_t read_EEPROM(uint8_t direccion){
    EEADR = direccion;
    EECON1bits.EEPGD = 0;
    EECON1bits.RD = 1;
    return EEDAT; 
}

void write_EEPROM(uint8_t direccion, uint8_t data){
    EEADR = direccion;
    EEDAT = data;
    EECON1bits.EEPGD = 0; 
    EECON1bits.WREN = 1;
    
    INTCONbits.GIE = 0;
    EECON2 = 0x55;      
    EECON2 = 0xAA;
    
    EECON1bits.WR = 1;
    
    EECON1bits.WREN = 0;
    INTCONbits.RBIF = 0;
    INTCONbits.GIE = 1;
}