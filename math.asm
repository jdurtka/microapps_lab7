
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 3 - Temperature sensor
;
;*******************************************************************

;Adapted directly from Freescale document AN1219
;(but ADD16 is my own)

           INCLUDE 'derivative.inc' 

           XDEF INTACC1
           XDEF INTACC2
           
           XDEF SMULT16
           XDEF UMULT16
           
           XDEF extend_16_32
           XDEF ADD16
           XDEF computeAverage

MY_ZEROPAGE: SECTION  SHORT

	INTACC1: DC.B 1
			 DC.B 1
			 DC.B 1
			 DC.B 1
	INTACC2: DC.B 1
			 DC.B 1
			 DC.B 1
			 DC.B 1
			
MyCode:     SECTION

********************************************************************************
********************************************************************************
*
* Signed 16 x 16 multiply
*
* This routine multiplies the signed 16-bit number in INTACC1:INTACC1+1 by
* the signed 16-bit number in INTACC2:INTACC2+1 and places the signed 32-bit
* value in locations INTACC1:INTACC1+3 (INTACC1 = MSB:INTACC1+3 = LSB).
*
SMULT16:
	PSHX ;save x-reg
	PSHA ;save accumulator
	PSHH ;save h-reg
	AIS #-1 ;reserve 1 byte of temp. storage
	CLR 1,SP ;clear storage for result sign
	BRCLR 7,INTACC1,TST2 ;check multiplier sign bit and negate
	;(two's complement) if set
	NEG INTACC1+1 ;two's comp multiplier LSB
	BCC NOSUB1 ;check for borrow from zero
	NEG INTACC1 ;two's comp multiplier MSB
	DEC INTACC1 ;decrement MSB for borrow
	BRA MPRSIGN ;finished
NOSUB1:
	NEG INTACC1 ;two's comp multiplier MSB (no borrow)
MPRSIGN:
	INC 1,SP ;set sign bit for negative number
TST2:
	BRCLR 7,INTACC2,MLTSUB ;check multiplicand sign bit and negate
	;(two's complement) if set
	NEG INTACC2+1 ;two's comp multiplicand LSB
	BCC NOSUB2 ;check for borrow from zero
	NEG INTACC2 ;two's comp multiplicand MSB
	DEC INTACC2 ;decrement MSB for borrow
	BRA MPCSIGN ;finished
NOSUB2:
	NEG INTACC2 ;two's comp multiplicand MSB (no borrow)
MPCSIGN:
	INC 1,SP ;set or clear sign bit
MLTSUB:
	JSR UMULT16 ;multiply INTACC1 by INTACC2
	LDA 1,SP ;load sign bit
	CMP #1 ;check for negative
	BNE DONE ;exit if answer is positive,
	;otherwise two's complement result
	LDX #3 ;
COMP:
	COM INTACC1,X ;complement a byte of the result
	DECX ;point to next byte to be complemented
	BPL COMP ;loop until all four bytes of result
	;have been complemented
	LDA INTACC1+3 ;get result LSB
	ADD #1 ;add a "1" for two's comp
	STA INTACC1+3 ;store new value
	LDX #2 ;
TWSCMP:
	LDA INTACC1,X ; add any carry from the previous
	ADC #0 ; addition to the next three bytes
	STA INTACC1,X ; of the result and store the new
	DECX ; values
	BPL TWSCMP ;
DONE:
	AIS #1 ;deallocate temp storage on stack
	PULH ;restore h-reg
	PULA ;restore accumulator
	PULX ;restore x-reg
	RTS ;return
	
	
********************************************************************************
* Start of subroutine
* Unsigned 16x16 multiply
*
* This routine multiplies the 16-bit unsigned number stored in
* locations INTACC1:INTACC1+1 by the 16-bit unsigned number stored in
* locations INTACC2:INTACC2+1 and places the 32-bit result in locations
* INTACC1:INTACC1+3 (INTACC1 = MSB:INTACC1+3 = LSB.
*
********************************************************************************
UMULT16:
	PSHA ;save acc
	PSHX ;save x-reg
	PSHH ;save h-reg
	AIS #-6 ;reserve six bytes of temporary
	;storage on stack
	CLR 6,SP ;zero storage for multiplication carry
	*
	* Multiply (INTACC1:INTACC1+1) by INTACC2+1
	*
	LDX INTACC1+1 ;load x-reg w/multiplier LSB
	LDA INTACC2+1 ;load acc w/multiplicand LSB
	MUL ;multiply
	STX 6,SP ;save carry from multiply
	STA INTACC1+3 ;store LSB of final result
	LDX INTACC1 ;load x-reg w/multiplier MSB
	LDA INTACC2+1 ;load acc w/multiplicand LSB
	MUL ;multiply
	ADD 6,SP ;add carry from previous multiply
	STA 2,SP ;store 2nd byte of interm. result 1.
	BCC NOINCA ;check for carry from addition
	INCX ;increment MSB of interm. result 1.
NOINCA:
	STX 1,SP ;store MSB of interm. result 1.
	CLR 6,SP ;clear storage for carry
	*
	* Multiply (INTACC1:INTACC1+1) by INTACC2
	*
	LDX INTACC1+1 ;load x-reg w/multiplier LSB
	LDA INTACC2 ;load acc w/multiplicand MSB
	MUL ;multiply
	STX 6,SP ;save carry from multiply
	STA 5,SP ;store LSB of interm. result 2.
	LDX INTACC1 ;load x-reg w/multiplier MSB
	LDA INTACC2 ;load acc w/multiplicand MSB
	MUL ;multiply
	ADD 6,SP ;add carry from previous multiply
	STA 4,SP ;store 2nd byte of interm. result 2.
	BCC NOINCB ;check for carry from addition
	INCX ;increment MSB of interm. result 2.
NOINCB:
	STX 3,SP ;store MSB of interm. result 2.
	
	* Add the intermediate results and store the remaining three bytes of the
	* final value in locations INTACC1:INTACC1+2.
	*
	LDA 2,SP ;load acc with 2nd byte of 1st result
	ADD 5,SP ;add acc with LSB of 2nd result
	STA INTACC1+2 ;store 2nd byte of final result
	LDA 1,SP ;load acc with MSB of 1st result
	ADC 4,SP ;add w/ carry 2nd byte of 2nd result
	STA INTACC1+1 ;store 3rd byte of final result
	LDA 3,SP ;load acc with MSB from 2nd result
	ADC #0 ;add any carry from previous addition
	STA INTACC1 ;store MSB of final result
	*
	* Reset stack pointer and recover original register values
	*
	AIS #6 ;deallocate the six bytes of local
	;storage
	PULH ;restore h-reg
	PULX ;restore x-reg
	PULA ;restore accumulator
	RTS ;return


;--------------------------------------------------------------------------
;Subroutines written from scratch (not derived from the Freescale documents)
;--------------------------------------------------------------------------

;Extends 16-bit INTACC1 to 32-bit INTACC1
extend_16_32:
	LDA #$00
	STA INTACC1+2
	STA INTACC1+3
	RTS

ADD16:
	;LSB first
	LDA INTACC2+1
	ADD INTACC1+1
	STA INTACC1+1
	;Intermediate carry?
	BCS ADD16_CARRY
ADD16_NOCARRY:
	LDA INTACC2
	ADD INTACC1
	STA INTACC1
	;Set or clear the carry flag before returning?
	BCC ADD16_SCR
	BRA ADD16_CCR
ADD16_CARRY:
	LDA INTACC2
	ADD INTACC1
	;This is to add in that intermediate carry from the LSB
	INCA
	STA INTACC1
	BCC ADD16_SCR
	BRA ADD16_CCR
ADD16_SCR:
	;Carry in the MSB
	SEC
	RTS
ADD16_CCR:
	;No carry in the MSB
	CLC
	RTS

;Compute the mean of some values by dividing the precomputed sum by the number of values
;The sum (numerator) will be a 16 bit value stored at INTACC1
;The number of values (denominator) will be stored in the accumulator
;result will be returned in the accumulator
computeAverage:
	LDHX INTACC1
	PSHA
	PULX
	LDA INTACC1+1
	DIV
	RTS
