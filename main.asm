;******************************************************************************
; Universidad del Valle de Guatemala
; Programación de Microcrontroladores
; Proyecto: Lab3
; Archivo: main.asm
; Hardware: ATMEGA328p
; Created: 13/02/2024 18:35:16
; Author : Luis Furlán
;******************************************************************************
; Encabezado
;******************************************************************************

.include "M328PDEF.inc"
.cseg //Indica inicio del código
.org 0x00 //Indica el RESET
	JMP Main
.org 0x0008 // Vector de ISR : PCINT1
	JMP ISR_PCINT1
.org 0x0020 // Vector de ISR : TIMER0_OVF
	JMP ISR_TIMER_OVF0
	
Main:
;******************************************************************************
; Stack
;******************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16 
LDI R17, HIGH(RAMEND)
OUT SPH, R17
;******************************************************************************
; Configuración
;******************************************************************************
Setup:
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 ;HABILITAMOS EL PRESCALER
	LDI R16, 0b0000_0001
	STS CLKPR, R16 ; DEFINIMOS UNA FRECUENCIA DE 4MGHz

	LDI R16, 0x30 ; CONFIGURAMOS LOS PULLUPS en PORTC
	OUT PORTC, R16	; HABILITAMOS EL PULLUPS
	LDI R16, 0b0000_0011
	OUT DDRC, R16	;Puertos C (entradas y salidas)

	LDI R16, 0xFF
	OUT DDRD, R16	;Puertos D (entradas y salidas)

	LDI R16, 0x2F
	OUT DDRB, R16	;Puertos B (entradas y salidas)

	CLR R16
	LDI R16, (1 << PCIE1)
	STS PCICR, R16 //Configurar PCIE1

	CLR R16
	LDI R16, (1 << PCINT12) | (1 << PCINT13)
	STS PCMSK1, R16 //Habilitar la interrupción para los pines correspondientes

	CLR R16
	LDI R16, (1 << TOIE0)
	STS TIMSK0, R16 //Habilitar interrupción de overflow para timer0

	CLR R16
	OUT TCCR0A, R16 ; modo normal

	CLR R16
	LDI R16, (1 << CS02)
	OUT TCCR0B, R16 ; prescaler 256

	LDI R16, 178 ; valor calculado donde inicia a contar
	OUT TCNT0, R16

	SEI // Habilitar interruciones globales GIE



// Representaciones de los números hexadecimales para el display
	tabla: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71 
	
	LDI ZH, HIGH(tabla << 1)
	LDI ZL, LOW(tabla << 1)
	MOV R25, ZL
	MOV R26, ZL
	LPM R19, Z
	SBRS R19, 0
	CBI	PORTD, PD2
	SBRC R19, 0
	SBI PORTD, PD2
	SBRS R19, 1
	CBI	PORTD, PD3
	SBRC R19, 1
	SBI PORTD, PD3
	SBRS R19, 2
	CBI	PORTD, PD4
	SBRC R19, 2
	SBI PORTD, PD4
	SBRS R19, 3
	CBI	PORTD, PD5
	SBRC R19, 3
	SBI PORTD, PD5
	SBRS R19, 4
	CBI	PORTD, PD6
	SBRC R19, 4
	SBI PORTD, PD6
	SBRS R19, 5
	CBI	PORTD, PD7
	SBRC R19, 5
	SBI PORTD, PD7
	SBRS R19, 6
	CBI	PORTB, PB0
	SBRC R19, 6
	SBI PORTB, PB0

	CLR R17
	CLR R18
	CLR R19
	CLR R20
	CLR R21
	CLR R22
	CLR R23
	CLR R24

	SBI PORTC, PC0
	SBI PORTC, PC1
Loop:
	/*IN R16, TIFR0 ; banderas en donde se encuentra la de overflow a R16 
	SBRS R16, TOV0 ; Si está encendida la bandera de overflow no regresa al loop
	RJMP Loop*/
	CLI
	MOV R16, R18
	SUBI R16, 3
	BRBC 2, decrementar
	MOV R16, R23
	SUBI R16, 3
	BRBC 2, incrementar
	CPI R20, 1
	BREQ revisar
	SEI
	RJMP Loop

;******************************************************************************
; Subrutinas (funciones)
;******************************************************************************

incrementar: //Incrementa el contador binario
	INC R17
	CPI R17, 0x10
	BREQ reiniciar
	RJMP leds
reinciar:
	CLR R17
	RJMP leds

;******************************************************************************

decrementar: //Incrementa el contador binario
	DEC R17
	CPI R17, 0xFF
	BREQ volver_arriba
	RJMP leds
volver_arriba:
	LDI R17, 0x0F
	RJMP leds

;******************************************************************************

leds: //muestra el valor del contador en las leds
	SBRS R17, 0
	CBI	PORTB, PB1
	SBRC R17, 0
	SBI PORTB, PB1
	SBRS R17, 1
	CBI	PORTB, PB2
	SBRC R17, 1
	SBI PORTB, PB2
	SBRS R17, 2
	CBI	PORTB, PB3
	SBRC R17, 2
	SBI PORTB, PB3
	SBRS R17, 3
	CBI	PORTB, PB4
	SBRC R17, 3
	SBI PORTB, PB4
	CLR R18
	CLR R23
	RJMP Loop

;******************************************************************************

revisar: //revisa cual display está encendido
	CLR R20
	SBIS PORTC, PC0
	RJMP decenas
	RJMP unidades

unidades: //carga el valor actual del contador de unidades
	CBI PORTC, PC0
	SBI PORTC, PC1
	MOV ZL, R26
	LPM R19, Z
	RJMP revisar_u

decenas: //carga el valor actual del contador de unidades
	SBI PORTC, PC0
	CBI PORTC, PC1
	MOV ZL, R25
	LPM R19, Z
	RJMP revisar_d

revisar_d: //Revisa si pasan 10 segundos
	CPI R24, 1
	BREQ incr_d
	RJMP display7

incr_d: //incrementa el contador de decenas
	CLR R24
	INC R25
	MOV ZL, R25
	LPM R19, Z
	CPI R19, 0x7D
	BREQ reset_decenas
	RJMP display7

reset_decenas: //Si llega a 6 lo resetea para que continue en 0
	LDI R25, LOW(tabla << 1)
	MOV ZL, R25
	LPM R19, Z
	RJMP display7

revisar_u: //Revisa si pasa un segundo
	CPI R22, 200
	BREQ incr_u
	INC R22
	RJMP display7

incr_u: //incrementa el contador de unidades
	CLR R22
	INC R26
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x77
	BREQ reset_unidades
	RJMP display7

reset_unidades: //Si llega a 10 lo resetea para que continue en 0
	LDI R26, LOW(tabla << 1)
	MOV ZL, R26
	LPM R19, Z
	INC R24
	RJMP display7

;******************************************************************************

display7: //Muestra el valor del contador en el display
	SBRS R19, 0
	CBI	PORTD, PD2
	SBRC R19, 0
	SBI PORTD, PD2
	SBRS R19, 1
	CBI	PORTD, PD3
	SBRC R19, 1
	SBI PORTD, PD3
	SBRS R19, 2
	CBI	PORTD, PD4
	SBRC R19, 2
	SBI PORTD, PD4
	SBRS R19, 3
	CBI	PORTD, PD5
	SBRC R19, 3
	SBI PORTD, PD5
	SBRS R19, 4
	CBI	PORTD, PD6
	SBRC R19, 4
	SBI PORTD, PD6
	SBRS R19, 5
	CBI	PORTD, PD7
	SBRC R19, 5
	SBI PORTD, PD7
	SBRS R19, 6
	CBI	PORTB, PB0
	SBRC R19, 6
	SBI PORTB, PB0
	RJMP Loop

;******************************************************************************

ISR_PCINT1:

	IN R21, PINC
	SBRS R21, PC4	;botón 1
	INC R18
	SBRS R21, PC5	;botón 2
	INC R23
	RETI

;******************************************************************************

ISR_TIMER_OVF0:
	LDI R16, 178 ; Cargar el valor calculado en donde debería iniciar.
	OUT TCNT0, R16
	LDI R20, 1
	RETI