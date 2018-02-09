
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 6 - LM92 on i2c bus
;
;*******************************************************************

           INCLUDE 'derivative.inc' 

			XDEF tec_setup
           	XDEF tec_disp_state
           	XDEF tec_change_state
           	
           	XDEF tec_set_temp
           	
           	XDEF TEC_STATE
           	XDEF SET_TEMP
           	
           	
           	
           	XREF _update_LEDs

			;XREF rtc_reset_secs
			
			XREF LCD_Line_0
           
           XREF LCD_Display_Byte_Hex
           XREF LCD_Write_Char

MY_ZEROPAGE: SECTION  SHORT
	TEC_STATE: DC.B 1
	
	SET_TEMP: DC.B 1		;Keep track of what the set temp is
	
	ENT_ST: DC.B 1
	INTERMED1: DC.B 1
			
MyCode:     SECTION

tec_setup:
	LDA #$00
	STA TEC_STATE
	STA ENT_ST
	RTS

tec_disp_state:
	;LDA TEC_STATE
	;JSR LCD_Display_Byte_Hex
	LDA TEC_STATE
	CMP #$00		;0 = normal off
	BEQ _dispoff
	DECA			;1 = heat
	BEQ _dispheat
	DECA			;2 = cool
	BEQ _dispcool
	DECA
	DECA			;4 = overtemp safety off
	BEQ _disp_overtemp
	JMP _disperr
	
	_dispoff:
		JSR msg_holding_at
		RTS
	_dispheat:
		JSR msg_heat
		JSR msg_ingto
		RTS
	_dispcool:
		JSR msg_cool
		JSR msg_ingto
		RTS
	_disp_overtemp:
		JSR LCD_Line_0
		LDA #$4F	;O
		JSR LCD_Write_Char
		LDA #$56	;V
		JSR LCD_Write_Char
		LDA #$45	;E
		JSR LCD_Write_Char
		LDA #$52	;R
		JSR LCD_Write_Char
		LDA #$54	;T
		JSR LCD_Write_Char
		LDA #$45	;E
		JSR LCD_Write_Char
		LDA #$4D	;M
		JSR LCD_Write_Char
		LDA #$50	;P
		JSR LCD_Write_Char
		LDA #$3A	;":"
		JSR LCD_Write_Char
		LDA #$54	;T
		JSR LCD_Write_Char
		LDA #$45	;E
		JSR LCD_Write_Char
		LDA #$43	;C
		JSR LCD_Write_Char
		LDA #$20	;" "
		JSR LCD_Write_Char
		LDA #$4F	;O
		JSR LCD_Write_Char
		LDA #$46	;F
		JSR LCD_Write_Char
		LDA #$46	;F
		JSR LCD_Write_Char
		RTS
	_disperr:
		LDA #$65	;e
		JSR LCD_Write_Char
		LDA #$72	;r
		JSR LCD_Write_Char
		LDA #$72	;r
		JSR LCD_Write_Char
		RTS

tec_change_state:
	STA TEC_STATE
	JSR _update_LEDs
	RTS

msg_holding_at:
	;"Holding at "
	LDA #$48	;H
	JSR LCD_Write_Char
	LDA #$6F	;o
	JSR LCD_Write_Char
	LDA #$6C	;l
	JSR LCD_Write_Char
	LDA #$64	;d
	JSR LCD_Write_Char
	LDA #$69	;i
	JSR LCD_Write_Char
	LDA #$6E	;n
	JSR LCD_Write_Char
	LDA #$67	;g
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	LDA #$61	;a
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS
	
msg_heat:
	;"Heat"
	LDA #$48	;H
	JSR LCD_Write_Char
	LDA #$65	;e
	JSR LCD_Write_Char
	LDA #$61	;a
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	RTS

msg_cool:
	;"Cool"
	LDA #$43	;C
	JSR LCD_Write_Char
	LDA #$6F	;o
	JSR LCD_Write_Char
	LDA #$6F	;o
	JSR LCD_Write_Char
	LDA #$6C	;l
	JSR LCD_Write_Char
	RTS

msg_ingto:
	;"ing to "
	LDA #$69	;i
	JSR LCD_Write_Char
	LDA #$6E	;n
	JSR LCD_Write_Char
	LDA #$67	;g
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	LDA #$6F	;o
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS

;For entering new set temps
;Entry state: accumulator contains the most recently entered digit
;ENT_ST will be 0 for the first digit, 1 for the second digit
;INTERMED1 will be used to store the first digit while waiting for the second
;
;Return: 0 if a new temp was successfully entered
;		 1 if the temp entered was invalid and must be re-entered
;		 2 if only one digit has been entered so far
tec_set_temp:
	PSHA
	LDA ENT_ST			;what is the state of the entry mechanism?
	CMP #$00
	BEQ _first_digit
	BRA _second_digit
	
	_first_digit:
		PULA			;restore the first digit from the stack
		CMP #$00		;if it's 0, it's already wrong...
		BEQ _wrong_digit
		CMP #$04		;if it's higher than 4, it's already wrong...
		BHI _wrong_digit
		;else
		STA INTERMED1	;save it to INTERMED1
		
		LDA #$01		;update the entry mechanism state:
		STA ENT_ST		;we now have one character
		
		LDA #$02		;return 2, indicating we need another digit entered
		RTS
		
	_wrong_digit:
		LDA #$00		;since it was an invalid entry, we need to start over
		STA ENT_ST		
		LDA #$01		;return 1, indicating an invalid digit was entered
		RTS

	_second_digit:
		;multiply the intermediate digit by 10, and add the second digit
		LDA INTERMED1
		LDX #$0A
		MUL
		STA INTERMED1
		PULA
		ADD INTERMED1
		
		;moment of truth: it can't be >40 or <10!
		CMP #40
		BHI _wrong_digit
		CMP #10
		BLO _wrong_digit
		
		STA SET_TEMP	;store it to the set temp
		
		;reset the entry state for whenever we enter a new set temp
		LDA #$00
		STA ENT_ST
		
		;return 0, indicating that we are done
		RTS
