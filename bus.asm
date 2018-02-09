
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 2 - LCD
;
;*******************************************************************

;
; Generic "bus-related" routines
;
;   The most important routine here is _bus_clk, which is called to clock the demux
;	bus line after any given bus transaction.
;
;	Also included is _refresh_LEDs, which is used to update the LED bank.
;

           INCLUDE 'derivative.inc' 
 
           XDEF _bus_clk

           XDEF _refresh_LEDs

MY_ZEROPAGE: SECTION  SHORT
			
MyCode:     SECTION

;Toggles the "bus clock" i.e. by temporarily disabling the multiplex output
_bus_clk:
	;clock G2A by setting the port register (1)xxx
	LDA PTBD
	ORA #$08
	STA PTBD
	
	RTS

	
;Call with LED settings in accumulator
_refresh_LEDs:
	;save the accumulator
	PSHA
	
	NSA
	;LED status in upper 4
	;zero the lower part (port register (0)000)
	AND #$F0
	STA PTBD
	
	JSR _bus_clk
	
	PULA
	;LED status in upper 4, port register (0)001
	;port register (0)001
	AND #$F1
	ORA #$01
	STA PTBD
	
	JSR _bus_clk
	RTS
