
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 2 - LCD
;
;*******************************************************************

           INCLUDE 'derivative.inc' 
 
;Exports
           XDEF _Timer_IRQ

           XDEF reset_Counter
           XDEF setup_Timer

           XDEF COUNTER_LOW

;Imports
           XREF LED_STATE
           XREF _toggle_LED
           
           XREF LCD_Clear
	
		   ;XREF lm92_state_dump
		   XREF lm92_poll_state
		   XREF lm92_safety_check
		   XREF lm92_temp_controller
		   ;XREF rtc_poll_state


MY_ZEROPAGE: SECTION  SHORT

		COUNTER_LOW: DC.B 1
		;COUNTER_HIGH: DC.B 1
		LM92_CHECK: DC.B 1
			
MyCode:     SECTION


;INTERRUPT HANDLER FOR MTIM OVERFLOW
_Timer_IRQ:
	PSHH	;recommended during IRQs (not handled automatically)
	
	;Acknowledge the interrupt
	BSET 2, IRQSC
	;Clear TOF by reading MTIMSC while the bit is 1, then writing 0
	LDA MTIMSC
	BCLR 7, MTIMSC
	BSET 5, MTIMSC
	
	
	;Update the low counter
	LDA COUNTER_LOW
	DECA
	STA COUNTER_LOW
	;we're done if it didn't overflow
	BNE _int_done
	
	;Both counters overflowed:
	;Toggle LEDs and reset the counters
	JSR _toggle_LED
	
	;JSR rtc_poll_state
	
	
	;JSR lm92_state_dump
	LDA LM92_CHECK
	DECA
	STA LM92_CHECK
	BEQ no_lm92_check
	LDA #$02
	STA LM92_CHECK
	JSR lm92_poll_state
	
	;Check for overtemp state (> 50C)
	;This should be done secondly so it overwrites whatever
	JSR lm92_safety_check
	
	;if we are in the danger state (>50C), we will not perform any other temp control measures
	CMP #$FF
	BEQ no_lm92_check
	
	;If we are NOT in the danger state,
	;check if we need to heat or cool to return to set temp
	JSR lm92_temp_controller
	
	no_lm92_check:
	
	
	JSR reset_Counter
	
	
	_int_done:
	PULH	;recommended during IRQs (not handled automatically)
	
	;return from interrupt
	RTI
	
reset_Counter:
	;Using prescaler and modulo counter, the clock is reduced to
	;125 Hz. Thus, we need one more counter = 125 to reduce to 1 Hz.
	LDA #$7D
	;LDA #$3D
	STA COUNTER_LOW
	
	LDA #$02
	STA LM92_CHECK
	RTS

setup_Timer:
	;Setup the soft counter for toggling LEDs
	JSR reset_Counter

	;Start LED_State at on
	;BCLR 2, PTAD
	LDA #$0
	STA LED_STATE

	;Set the clock modulo = 125
	LDA #$7D
	STA MTIMMOD
	;Prescale /256, use busclk (4 MHz -> 15625 Hz)
	LDA #$08
	STA MTIMCLK
	;Enable the overflow interrupt (TOIE)
	BSET 6, MTIMSC
	
	;Start the MTIM (clear TSTP)
	BCLR 4, MTIMSC
	
	RTS
	
