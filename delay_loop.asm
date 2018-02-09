
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 2 - LCD
;
;*******************************************************************

           INCLUDE 'derivative.inc' 
 
           XDEF _delay_loop

MY_ZEROPAGE: SECTION  SHORT
			
MyCode:     SECTION

;USAGE:
;
;  Timing on this isn't necessarily precise, but assume the inner loop takes 8 clock cycles.
;  E.g., if you load the accumulator with 5 before entering the inner loop then it should take
;  about 40 clock cycles. Treat the overhead of each of the other loops as zero. Then, each
;  enclosing loop simply multiplies into the full expression.
;
;  In this case, we use 50 in the middle loop and 4 in the outer loop. 50*4*8 = 1600. This should
;  bring us down to about 2,500 Hz (on a 4 MHz clock rate) and that translates to 0.4ms delay.
;
;  Since we only care about making the delay large enough, treat it as 0.1ms to be extra conservative.
;  This also simplifies the math. Pass in 1 for a "0.1ms" delay. Pass in 150 for a "15.0ms" delay.
;

;innermost loop
_delay_loop_inner_1:
	DECA
	BNE _delay_loop_inner_1
	RTS

;middle loop
_delay_loop_inner_2:
	PSHA
	LDA #50
	JSR _delay_loop_inner_1
	PULA
	DECA
	BNE _delay_loop_inner_2
	RTS

;outer loop
_delay_loop:
	PSHA
	LDA #4
	JSR _delay_loop_inner_2
	PULA
	DECA
	BNE _delay_loop
	RTS
