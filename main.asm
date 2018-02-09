
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 7 - TEC controller
;
;*******************************************************************

; Naming conventions:
;	-Normal subroutines as a mixture of camel and snake case: my_Subroutine
;	-Utility functions as snake case with a leading underscore: _my_utility
;	-ISRs as utility functions, but with camel case: _My_Interrupt
;	-Main loop and startup: mainLoop and _Startup
;	-Variables and constants as all caps snake case: MY_VARIABLE
;
; Version control via git

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            

; export symbols
            XDEF _Startup, main
            XDEF statusDisplay
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on
            
            
            
            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack
            
            XREF _refresh_LEDs
            XREF setup_LCD
            XREF setup_Timer
            
            XREF _keypad_polling
            XREF keypad_Decoder
            XREF KEY_CODE
            XREF KEY_VAL
            
            XREF LCD_Cursor_Shift
            XREF LCD_Write_Char
            XREF LCD_Line_0
            XREF LCD_Line_1
            XREF LCD_Clear
            XREF LCD_Display_Byte_Dec
            XREF LCD_Display_Byte_Hex
            XREF LCD_Display_Nibble
            XREF LCD_Display_16_Dec
            XREF LCD_Display_16_Hex
            
            XREF _delay_loop
            
            XREF i2c_setup
            
            ;XREF rtc_setup
            ;XREF rtc_state_dump
            ;XREF rtc_stop
            ;XREF rtc_start
            ;XREF rtc_poll_state
            ;XREF rtc_display_state
            ;XREF rtc_entry_prompt
            ;XREF rtc_write
            ;XREF RTC_REGADD
            ;XREF RTC_REGVAL
            ;XREF rtc_disp_secs
            
            ;XREF lm92_state_dump
            XREF lm92_disp_temp
            XREF lm92_disp_fractional
            
            XREF tec_setup
            XREF tec_disp_state
            XREF tec_change_state
            XREF tec_set_temp
            
            XREF SET_TEMP

; variable/data section
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definition
		
		LAST_KEY: DC.B 1		;Keep track of the last keycode received
		NUM_CHARS: DC.B 1		;Keep track of how many characters are on the screen
		
		LOOP_MAX: DC.B 1 		;Keep track of how many samples we are averaging
		CUR_ITER: DC.B 1		;Keep track of how many samples need to be taken
		
		DATA_ENTRY: DC.B 1		;Keep track of data entry on the keypad
		DATA_ENTRY_2: DC.B 1
		
		
; code section
MyCode:     SECTION
main:
_Startup:
            LDHX   #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
			
			LDA #$53
			STA SOPT1	; Disable Watchdog
			
			;Setup the data direction registers for LED I/O (SET = output)
			;BSET 3, PTADD
			
			;Data direction for LCD control lines
			BSET 0, PTADD ;R/W
			BSET 1, PTADD ;RS
			
			;Setup bus and port registers to write (default state)
			LDA #$FF
			STA PTBDD
			
			;Init "last key" to FF
			LDA #$FF
			STA LAST_KEY
			LDA #$00
			STA NUM_CHARS
			
			;Initialize the LED ticker into a known state
			;LDA #%10010110
			LDA #$00
			JSR _refresh_LEDs
			
			;Initialize set temperature at "room temperature"
			LDA #22
			STA SET_TEMP
			
			;Setup LCD display
			JSR setup_LCD
			
			;Setup ADC
			;JSR setup_ADC
			;Setup i2c
			JSR i2c_setup
				
			JSR tec_setup
			
			
			;Setup MTIM parameters
			JSR setup_Timer
			
			CLI			; enable interrupts
			
			;setup sampling loop parameters
			;1 sample
			LDA #$01
			STA LOOP_MAX
			;start at 1
			LDA #$01
			STA CUR_ITER
			
			BRA mainLoop

mainLoop:
	;Check if # has been pressed on the keypad
	JSR inputPoll
	
	JSR statusDisplay
	
	LDA #$FF			;Delay prevents cursor "snow"
	JSR _delay_loop
	
	BRA mainLoop
	
statusDisplay:
	JSR LCD_Clear
	
	JSR LCD_Line_0
	JSR msg_tec_state
	JSR tec_disp_state
	LDA SET_TEMP
	JSR LCD_Display_Byte_Dec
	
	JSR LCD_Line_1
	JSR msg_temp_0
	JSR lm92_disp_temp
	LDA #$2E			;decimal .
	JSR LCD_Write_Char
	JSR lm92_disp_fractional
	JSR msg_temp_1
	
	RTS

inputPoll:
	;Poll keypad
	JSR _keypad_polling
	
	;Check what keys have been pressed, and update accordingly
	;(debouncing occurs here)
	JSR keypad_Decoder
	
	;Avoid duplicating keys
	LDA KEY_CODE
	CMPA LAST_KEY
	BNE nodeb
	;delay to debounce
	LDA #$FE
	JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	BRA _no_new_key
	
	nodeb:
	;This is the code for "no new key"
	CMPA #$FF
	BEQ _no_new_key
	
	;Reject any keys except #
	LDA KEY_VAL
	;CMP #$00
	;BEQ _no_new_key
	CMP #$0F
	BNE inloopdone
	JSR enterTemp
	
	inloopdone:
	
	;return to caller
	RTS
	
	;whether new keys came in or not, we update the "last key"
	_no_new_key:
	LDA KEY_CODE
	STA LAST_KEY
	
	RTS
	
enterTemp:
	JSR msg_enter_temp
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	et_loop:
	;Poll keypad
	JSR _keypad_polling
	
	;Check what keys have been pressed, and update accordingly
	;(debouncing occurs here)
	JSR keypad_Decoder
	
	;Avoid duplicating keys
	LDA KEY_CODE
	CMPA #$FF
	BNE nodeb_2
	;delay to debounce
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	BRA _no_new_key_2
	
	nodeb_2:
	;This is the code for "no new key"
	CMPA #$FF
	BEQ _no_new_key_2
	
	;Reject any keys except * or 0-9
	LDA KEY_VAL
	;CMP #$00
	;BEQ _no_new_key
	CMP #$0E
	BEQ _et_exit	;* means exit to main menu
	CMP #$09
	BHI _no_new_key_2 ;anything else means loop again
	
	;write the character out, then deal with the value
	LDA KEY_CODE
	JSR LCD_Write_Char
	LDA KEY_VAL
	
	;now, we have a number!
	;send it to the TEC set temp routine
	JSR tec_set_temp
	;if it returns a 0, we are done
	CMP #$00
	BEQ _et_exit
	;if it returns a 1, we need to start over (invalid entry)
	DECA
	BEQ enterTemp
	;else, we simply need another character
	BRA _no_new_key_2
	
	;whether new keys came in or not, we update the "last key"
	_no_new_key_2:
	LDA KEY_CODE
	STA LAST_KEY
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	LDA #$FE
	JSR _delay_loop
	BRA et_loop
	
	_et_exit:
	
	RTS
	
msg_tec_state:
	;"C: "
	LDA #$43	;C
	JSR LCD_Write_Char
	LDA #$3A	;":"
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS
	
msg_temp_0:
	;"T92: "
	LDA #$54	;T
	JSR LCD_Write_Char
	LDA #$39	;9
	JSR LCD_Write_Char
	LDA #$32	;2
	JSR LCD_Write_Char
	LDA #$3A	;":"
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS
	
msg_temp_1:
	;"C"
	LDA #$43	;C
	JSR LCD_Write_Char
	RTS

msg_enter_temp:
	JSR LCD_Clear
	JSR LCD_Line_0
	
	;"C: Target Temp?"
	;"Enter 10-40C   "
	JSR msg_tec_state	;"C: "
	LDA #$54	;T
	JSR LCD_Write_Char
	LDA #$61	;a
	JSR LCD_Write_Char
	LDA #$72	;r
	JSR LCD_Write_Char
	LDA #$67	;g
	JSR LCD_Write_Char
	LDA #$65	;e
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	LDA #$54	;T
	JSR LCD_Write_Char
	LDA #$65	;e
	JSR LCD_Write_Char
	LDA #$6D	;m
	JSR LCD_Write_Char
	LDA #$70	;p
	JSR LCD_Write_Char
	LDA #$3F	;?
	JSR LCD_Write_Char
	
	JSR LCD_Line_1
	
	LDA #$45	;E
	JSR LCD_Write_Char
	LDA #$6E	;n
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	LDA #$65	;e
	JSR LCD_Write_Char
	LDA #$72	;r
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	LDA #$31	;1
	JSR LCD_Write_Char
	LDA #$30	;0
	JSR LCD_Write_Char
	LDA #$2D	;-
	JSR LCD_Write_Char
	LDA #$34	;4
	JSR LCD_Write_Char
	LDA #$30	;0
	JSR LCD_Write_Char
	LDA #$43	;C
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS
