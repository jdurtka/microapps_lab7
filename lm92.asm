
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 6 - LM92 on i2c bus
;
;*******************************************************************

;
; Real-Time Clock (RTC) interface routines
; 


           INCLUDE 'derivative.inc' 

           XREF _delay_loop
           
           ;XREF i2c_setup
           XREF i2c_address
           XREF i2c_address_repst
           XREF i2c_send_8bit
           XREF i2c_recv_8bit
           XREF i2c_send_ack
           XREF i2c_send_nack
           XREF i2c_stop_condition
           
           XREF LCD_Clear
           XREF LCD_Line_0
           XREF LCD_Line_1
           XREF LCD_Write_Char
           XREF LCD_Display_Byte_Hex
           XREF LCD_Display_Byte_Dec
           XREF LCD_Display_Nibble
           ;XREF LCD_Display_16_Dec
           ;XREF celsius_to_kelvin
           XREF tec_change_state
           
           XREF SET_TEMP
           
           
           XDEF lm92_poll_state
           XDEF lm92_disp_temp
           XDEF lm92_disp_fractional
           
           XDEF lm92_safety_check
           XDEF lm92_temp_controller
           ;XDEF lm92_state_dump
           

MY_ZEROPAGE: SECTION  SHORT

	LM92_TEMP_HIGH: DC.B 1
	LM92_TEMP_LOW: DC.B 1
	
	LM92_TH_CORRECTED: DC.B 1
	
MyCode:     SECTION

lm92_disp_temp:
	LDA LM92_TEMP_HIGH
	LSLA
	
	temp_pos:
	PSHA				;save momentarily...
	LDA LM92_TEMP_LOW
	AND #%10000000
	BEQ low_zero
	;CMPA #%10000000		;what's the low bit?
	;BHS low_zero
	
	low_one:
	PULA
	ORA #$01
	STA LM92_TH_CORRECTED	;store the "corrected" high temp byte
	JSR LCD_Display_Byte_Dec
	;JSR celsius_to_kelvin
	;JSR LCD_Display_16_Dec
	;done
	RTS
	
	low_zero:
	PULA
	AND #$FE
	STA LM92_TH_CORRECTED	;store the "corrected" high temp byte
	JSR LCD_Display_Byte_Dec
	;JSR celsius_to_kelvin
	;JSR LCD_Display_16_Dec
	;done
	RTS
	
;Display one decimal place of precision
lm92_disp_fractional:
	LDA LM92_TEMP_LOW
	LSRA
	LSRA
	LSRA		;three shifts to get rid of the low 3 status bits
	AND #$0F	;make sure to zero out the top
	CMP #$00	;clamp to zero
	BEQ lm92df_zero
	
	
	
	;Add 2, divide by 2, display as decimal
	INCA
	INCA
	CMP #$0A
	BHI lm92df_correction
	LSRA
	JSR LCD_Display_Nibble
	RTS
	
	;clamp 0->0
	lm92df_zero:
		LDA #$30
		JSR LCD_Write_Char
		RTS
		
	;force >10 to increment
	lm92df_correction:
		LSRA
		INCA
		JSR LCD_Display_Nibble
		RTS

lm92_poll_state:
	LDA #%10010001		;10010xy is device addr, xy are both pulled to gnd, last 1 = read operation
	JSR i2c_address
	JSR i2c_recv_8bit
	STA LM92_TEMP_HIGH
	JSR i2c_send_ack
	JSR i2c_recv_8bit
	STA LM92_TEMP_LOW
	JSR i2c_send_ack
	JSR i2c_stop_condition
	RTS
	

;This is to ensure 
lm92_safety_check:
	LDA LM92_TH_CORRECTED
	
	;for testing purposes, try 22 (or whatever the room temp is)
	;CMP #%00010110
	;for actual application, 50
	CMP #%00110010
	
	;signed branch if >=
	BGE lm92_shutoff
	
	;not overtemp, return 0
	LDA #$00
	RTS
	
	;in the case where the temp exceeds what it should
	lm92_shutoff:
	LDA #$04
	JSR tec_change_state
	LDA #$FF				;indicate that we are in danger state
	RTS
	
lm92_temp_controller:
	LDA SET_TEMP
	CMP LM92_TH_CORRECTED
	
	;if equal, definitely done
	BEQ lm92tc_off
	
	;if not equal, we need to check if within the +/- 5C range
	;note the conditions are reversed, because of the comparison done:
	;ge means the temp is currently too LOW, and lt means it is too HIGH
	BGE lm92tc_ge
	BRA lm92tc_lt
	
	;TEC off (because set_temp = temp)
	lm92tc_off:
		LDA #$00
		JSR tec_change_state
		RTS
	;TEC heat (temp <= set_temp)
	lm92tc_ge:
		LDA #$01
		JSR tec_change_state
		RTS
	;TEC cool (temp > set_temp)
	lm92tc_lt:
		LDA #$02
		JSR tec_change_state
		RTS

;NOTE: This will fail if done more often than the device is capable!
;To ensure correct operation, the LM92 should be polled periodically,
;e.g. via the timer interrupt, not constantly!
;lm92_state_dump:
;	LDA #%10010001		;10010xy is device addr, xy are both pulled to gnd, last 1 = read operation
;	JSR i2c_address
;	JSR i2c_recv_8bit
;	JSR LCD_Display_Byte_Hex
;	JSR i2c_send_ack
;	JSR i2c_recv_8bit
;	JSR LCD_Display_Byte_Hex
;	JSR i2c_send_ack
;	JSR i2c_stop_condition
;	RTS
