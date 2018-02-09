
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 2 - LCD
;
;*******************************************************************

;
; Keypad helper routines
;
;	These are extremely non-general! Call _keypad_polling whenever convenient, this
;	checks the state of the keypad at any given time.
;
;	Call keypad_Decoder to decode that state into useful information.
;	Note that keypad_Decoder decodes only the first key it sees, thus it does not
;	support multiple simultaneous key presses.
;

           INCLUDE 'derivative.inc' 
 
           XDEF _keypad_polling
           XDEF keypad_Decoder
           XDEF KEY_CODE
           XDEF KEY_VAL
           
           XREF _bus_clk
           XREF _refresh_LEDs
           XREF LCD_Write_Char
           XREF _delay_loop

MY_ZEROPAGE: SECTION  SHORT

	;Storage for keyboard status
	;Keys are stored as read in, i.e. 1 = nothing, 0 = pressed
		KEYS_ROW_0: DC.B 1
		KEYS_ROW_1: DC.B 1
		KEYS_ROW_2: DC.B 1
		KEYS_ROW_3: DC.B 1
		
		KEY_CODE: DC.B 1
		KEY_VAL: DC.B 1
			
MyCode:     SECTION

keypad_Decoder:
	;at this stage each key row would be of the form 1111_1111
	;unless a key is pressed, in which case e.g. 1111_1011
	LDA KEYS_ROW_0
	COMA
	BEQ _keypad_status_1
	
			;keypress in the first row, which one?
			CMPA #$01
			BEQ _ks_r0_0
			CMPA #$02
			BEQ _ks_r0_1
			CMPA #$04
			BEQ _ks_r0_2
			CMPA #$08
			BEQ _ks_r0_3
			
			;spurious entry, exit routine
			JMP _keypad_s_done
			
			_ks_r0_0:
				;key "1"
				LDA #$31
				STA KEY_CODE
				LDA #$01
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r0_1:
				;key "2"
				LDA #$32
				STA KEY_CODE
				LDA #$02
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r0_2:
				;key "3"
				LDA #$33
				STA KEY_CODE
				LDA #$03
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r0_3:
				;key "A"
				LDA #$41
				STA KEY_CODE
				LDA #$0A
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
	
	_keypad_status_1:
	LDA KEYS_ROW_1
	COMA
	BEQ _keypad_status_2
	
			;keypress in the second row, which one?
			CMPA #$01
			BEQ _ks_r1_0
			CMPA #$02
			BEQ _ks_r1_1
			CMPA #$04
			BEQ _ks_r1_2
			CMPA #$08
			BEQ _ks_r1_3
			
			;spurious entry, exit routine
			JMP _keypad_s_done
			
			_ks_r1_0:
				;key "4"
				LDA #$34
				STA KEY_CODE
				LDA #$04
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r1_1:
				;key "5"
				LDA #$35
				STA KEY_CODE
				LDA #$05
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r1_2:
				;key "6"
				LDA #$36
				STA KEY_CODE
				LDA #$06
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r1_3:
				;key "B"
				LDA #$42
				STA KEY_CODE
				LDA #$0B
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
	
	_keypad_status_2:
	LDA KEYS_ROW_2
	COMA
	BEQ _keypad_status_3
	
			;keypress in the third row, which one?
			CMPA #$01
			BEQ _ks_r2_0
			CMPA #$02
			BEQ _ks_r2_1
			CMPA #$04
			BEQ _ks_r2_2
			CMPA #$08
			BEQ _ks_r2_3
			
			;spurious entry, exit routine
			JMP _keypad_s_done
			
			_ks_r2_0:
				;key "7"
				LDA #$37
				STA KEY_CODE
				LDA #$07
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r2_1:
				;key "8"
				LDA #$38
				STA KEY_CODE
				LDA #$08
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r2_2:
				;key "9"
				LDA #$39
				STA KEY_CODE
				LDA #$09
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r2_3:
				;key "C"
				LDA #$43
				STA KEY_CODE
				LDA #$0C
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
	

	_keypad_status_3:
	LDA KEYS_ROW_3
	COMA
	BEQ _keypad_s_done
	
			;keypress in the first row, which one?
			CMPA #$01
			BEQ _ks_r3_0
			CMPA #$02
			BEQ _ks_r3_1
			CMPA #$04
			BEQ _ks_r3_2
			CMPA #$08
			BEQ _ks_r3_3
			
			;spurious entry, exit routine
			BRA _keypad_s_done
			
			_ks_r3_0:
				;key "*" - mapped to "E"
				LDA #$45
				STA KEY_CODE
				LDA #$0E
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r3_1:
				;key "0"
				LDA #$30
				STA KEY_CODE
				LDA #$00
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r3_2:
				;key "#" - mapped to "F"
				LDA #$46
				STA KEY_CODE
				LDA #$0F
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
			_ks_r3_3:
				;key "D"
				LDA #$44
				STA KEY_CODE
				LDA #$0D
				STA KEY_VAL
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				LDA #$FE
				JSR _delay_loop ;delay 25.4ms (debounce)
				RTS
	
	
	_keypad_s_done:
	;if no keys were pressed, save the special "flag" character
	LDA #$FF
	STA KEY_CODE
	LDA #$00
	STA KEY_VAL
	LDA #$FF
	JSR _delay_loop ;delay 25.5ms
	RTS
	
;Keypad poll (from main loop)
_keypad_polling:
	;Disable interrupts to prevent bus from being invalidated by LED updates
	SEI
	
	;MOV FROM, TO
	;Double buffer: move the stored keyboard states into the stored previous states
	;MOV KEYS_ROW_0, KR0_PREV
	;MOV KEYS_ROW_1, KR1_PREV
	;MOV KEYS_ROW_2, KR2_PREV
	;MOV KEYS_ROW_3, KR3_PREV 
	
	;clear bus
	JSR _bus_clk
	
	;Pattern to write to keypad in upper 4
	;lower 4 is port register (0)010
	LDA #%01110010
	STA PTBD
	JSR _bus_clk
	;clock the bus, read the input, and store it
	JSR _read_keypad
	STA KEYS_ROW_3
	
	LDA #%10110010
	STA PTBD
	JSR _bus_clk
	JSR _read_keypad
	STA KEYS_ROW_2
	
	LDA #%11010010
	STA PTBD
	JSR _bus_clk
	JSR _read_keypad
	STA KEYS_ROW_1
	
	LDA #%11100010
	STA PTBD
	JSR _bus_clk
	JSR _read_keypad
	STA KEYS_ROW_0
	
	;re-enable interrupts
	CLI
	RTS

	

;Read keypad
_read_keypad:
	;Change PTBDD upper 4 to input
	LDA #$0F
	STA PTBDD
	
	;Activate multiplexer (port register (0)100
	LDA #%11100011
	STA PTBD
	
	;Read from bus
	LDA PTBD
	;swap nibbles
	NSA
	;Use F0 if just cleaning up the high nibble
	;Use F7 when only interested in keys A, B, C, and D
	ORA #$F0
	
	;Change PTBDD upper 4 back to output mode
	PSHA
	LDA #$FF
	STA PTBDD
	PULA
	
	RTS
