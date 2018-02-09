
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 6 - LM92 on i2c bus
;
;*******************************************************************

           INCLUDE 'derivative.inc' 

           XREF INTACC1
           XREF INTACC2
           
           XREF ADD16
           
           XDEF celsius_to_kelvin
           
           ;XREF LCD_Display_Byte_Hex

MY_ZEROPAGE: SECTION  SHORT
			
MyCode:     SECTION


;NOTE: for now, to keep things simple, this is built to assume unsigned!
;if negative temperatures are expected, this will need to be adjusted!
;
;input: unsigned 8-bit temperature in accum
;output: unsigned 16-bit temperature in pseudo accum1
celsius_to_kelvin:
	STA INTACC1+1
	LDA #$00
	STA INTACC1
	
	;now we need to put 273 into INTACC2 (273d = 0x111)
	LDA #$01
	STA INTACC2
	LDA #$11
	STA INTACC2+1
	
	;perform the addition
	JSR ADD16
	RTS
