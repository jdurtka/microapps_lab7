
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 2 - LCD
;
;*******************************************************************

;
; LED helper routines
;
;   These are not very general!
;   The LED has now been moved to the LED bank on the 4-bit bus.
;	It can be on, off, or toggled - generally, toggled every 1s.
;

           INCLUDE 'derivative.inc' 

           XDEF LED_STATE

           XDEF _toggle_LED
           XDEF _update_LEDs
           XDEF _LED_toggle_off
           XDEF _LED_toggle_on
           
           XREF _refresh_LEDs 
           
           XREF TEC_STATE

MY_ZEROPAGE: SECTION  SHORT

	LED_STATE: DC.B 1
			
MyCode:     SECTION

_toggle_LED:
	;Check the current LED state
	LDA LED_STATE
	COMA
	STA LED_STATE
	JSR _update_LEDs
	RTS

_update_LEDs:
	;Check the current LED state
	LDA LED_STATE
	;If it's off, then it goes on, else if it's on, it goes off
	BEQ _LED_toggle_off
	
	_LED_toggle_on:
		;LDA #$FF
		LDA TEC_STATE
		ORA #$C0
		JSR _refresh_LEDs
		;LDA PTAD
		;AND #%11111011
		;STA PTAD
		BRA _LED_done
		
	_LED_toggle_off:
		;LDA #$00
		LDA TEC_STATE
		AND #$0F
		JSR _refresh_LEDs
		;LDA PTAD
		;ORA #%00000111
		;AND #%00000111
		;STA PTAD
	
	_LED_done:
	RTS

