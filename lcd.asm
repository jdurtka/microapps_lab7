
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 2 - LCD
;
;*******************************************************************

           INCLUDE 'derivative.inc'
 
           XDEF setup_LCD
           
           ;low-level helper routine to send messages to the LCD controller.
           ;assumes RS and R/W are set as desired.
           XDEF _LCD_Cmd
           
           ;Pretty self-explanatory. Assume acc will be trashed.
           ;Only LCD_Write_Char needs to be fed input via acc.
           XDEF LCD_Cursor_Shift
           XDEF LCD_Write_Char
           XDEF LCD_Line_0
           XDEF LCD_Line_1
           XDEF LCD_Clear
           XDEF LCD_Display_Byte_Dec
           XDEF LCD_Display_Byte_Hex
           XDEF LCD_Display_Nibble
           XDEF LCD_Display_16_Dec
           XDEF LCD_Display_16_Hex

           XREF _bus_clk
           XREF _delay_loop
           
           XREF INTACC1
           XREF INTACC2
           ;XREF UDVD32

MY_ZEROPAGE: SECTION  SHORT

	HUNDREDS: DC.B 1
	TENS: DC.B 1
	ONES: DC.B 1
			
MyCode:     SECTION

setup_LCD:
	;RS := 0, R/W := 0 (for the entire init procedure)
	LDA PTAD
	AND #%11111100
	STA PTAD
	JSR _bus_clk
	
	;wait > 15 ms
	LDA #160
	JSR _delay_loop
	
	;DB[7 downto 4] := "0011" @ bus address (0)011
	LDA #$30
	JSR _LCD_Cmd
	
	;wait > 4.1 ms
	LDA #45
	JSR _delay_loop
	
	;<same, and clock>
	LDA #$30
	JSR _LCD_Cmd
	
	;wait > 4.1 ms
	LDA #45
	JSR _delay_loop
	
	;<same, and clock>
	LDA #$30
	JSR _LCD_Cmd
	
	;wait > 0.1 ms
	LDA #2
	JSR _delay_loop
	
	LDA #$20
	JSR _LCD_Cmd
	
	LDA #$20		;function set command DB[7 downto 4] := "0010"
	JSR _LCD_Cmd
	
	LDA #$80		;function set command DB[7 downto 4] := "NFXX" ;Settings (N=1, F=0 for 2 rows, 5x7 font)
	JSR _LCD_Cmd

	JSR LCD_Clear
	
	LDA #$00		;entry mode command MSB
	JSR _LCD_Cmd
	LDA #$60		;entry mode command LSB
	JSR _LCD_Cmd
	
	LDA #$80		;entry address MSB
	JSR _LCD_Cmd
	LDA #$00		;entry address LSB
	JSR _LCD_Cmd

	RTS

;Pass command in via accumulator high nibble
_LCD_Cmd:
	;SEI
	;Mask the low nibble to register (0)100 (4)
	AND #$F0
	ORA #$04
	STA PTBD
	;<clock>
	JSR _bus_clk
	;CLI
	
	;delay 40us: THIS DELAY IS CRITICAL, THINGS WILL NOT WORK WITHOUT IT!!!
	LDA #40
	_LCD_Cmd_Delay:
	DECA
	BNE _LCD_Cmd_Delay
	RTS
	
LCD_Clear:
	LDA #$00		;display ctrl MSB
	JSR _LCD_Cmd
	LDA #$80
	JSR _LCD_Cmd	;display ctrl LSB

	LDA #$00		;clear display MSB
	JSR _LCD_Cmd
	LDA #16
	JSR _delay_loop ;delay 1.6ms
	
	LDA #$10		;clear display LSB
	JSR _LCD_Cmd
	LDA #16
	JSR _delay_loop ;delay 1.6ms
	
	LDA #$00		;display ctrl MSB
	JSR _LCD_Cmd
	LDA #$F0
	JSR _LCD_Cmd	;display ctrl LSB
	
	RTS
	
LCD_Cursor_Shift:
	LDA #$10		;cursor shift MSB (always 0x1)
	JSR _LCD_Cmd
	LDA #$40	;cursor shift LSB CDxx (C = 0 cursor, 1 screen, D = 0 left, 1 right)
	JSR _LCD_Cmd
	RTS
	
LCD_Line_0:
	LDA #$80
	JSR _LCD_Cmd
	LDA #$00
	JSR _LCD_Cmd
	RTS
	
LCD_Line_1:
	LDA #$C0
	JSR _LCD_Cmd
	LDA #$00
	JSR _LCD_Cmd
	RTS


;Pass the char in the accum
LCD_Write_Char:
	;Save the character to the stack
	PSHA

	;RS := 1, R/W := 0 (write character out)
	LDA PTAD
	AND #%11111110
	ORA #%00000010
	STA PTAD
	JSR _bus_clk
	
	;Retrieve the character from the stack, then save it again
	PULA
	PSHA
	
	;High nibble first
	JSR _LCD_Cmd
	
	;Low nibble second
	PULA
	NSA
	JSR _LCD_Cmd
	
	;RS := 0, R/W := 0 (return to command mode)
	LDA PTAD
	AND #%11111100
	STA PTAD
	JSR _bus_clk
	
	RTS
	
LCD_Display_Nibble:
	CMPA #$0A
	BLO disp_nib_nonhex
	;hex nibble (i.e., >10)
	disp_nib_hex:
		AND #$0F
		ADD #55
		JSR LCD_Write_Char
		RTS
	;non-hex nibble (i.e. 0-9)
	disp_nib_nonhex:
		AND #$0F
		ORA #$30
		JSR LCD_Write_Char
		RTS

LCD_Display_Byte_Hex:
	PSHA
	NSA
	AND #$0F
	JSR LCD_Display_Nibble
	PULA
	AND #$0F
	JSR LCD_Display_Nibble
	RTS
	

LCD_Display_Byte_Dec:
	PSHA
	LDA #$00
	STA HUNDREDS
	STA TENS
	STA ONES
	PULA
	disp_byte_100s:
		CMPA #100
		BLO disp_byte_10s
		SUB #100
		INC HUNDREDS
		BRA disp_byte_100s
	disp_byte_10s:
		CMPA #10
		BLO disp_byte_1s
		SUB #10
		INC TENS
		BRA disp_byte_10s
	disp_byte_1s:
		CMPA #1
		BLO disp_byte_done
		DECA
		INC ONES
		BRA disp_byte_1s
	disp_byte_done:
		LDA HUNDREDS
		BEQ dispb_skip_hund
		JSR LCD_Display_Nibble
	dispb_skip_hund:
		LDA TENS
		JSR LCD_Display_Nibble
		LDA ONES
		JSR LCD_Display_Nibble
		RTS


;input is 16 bit in the pseudoaccumulator
;destroys H, X, and A
;assumption: the "16-bit" number is in the range [0,999]
; Although it would be trivial to display a full 16-bit number, this
; isn't necessary for any of the numbers we want to display
;
;note: for some reason, DIV crashes when the dividend is zero (this is illogical,
;although we would expect a crash when the DIVISOR is zero). To solve this, we check
;each time to ensure that the dividend is non-zero.
LCD_Display_16_Dec:
	PSHA
	LDA #$00
	STA ONES
	STA TENS
	STA HUNDREDS
	PULA
	
	LDHX INTACC1
	LDA INTACC1+1
	BEQ d16dec_done	;if it's zero, we should not divide!
	LDX #$0A
	DIV
	
	PSHA
	PSHH			;remainder in H
	PULA
	STA ONES
	PULA			;quotient from A
	BEQ d16dec_done	;if it's zero, we're done!
	LDHX #$000A
	DIV
	
	PSHA
	PSHH
	PULA
	STA TENS
	PULA
	BEQ d16dec_done	;if it's zero, we're done!
	
	LDHX #$000A
	DIV
	;JSR LCD_Display_Byte_Hex
	;RTS
	PSHH
	PULA
	
	STA HUNDREDS

	;LDA HUNDREDS
	
	d16dec_done:
	JSR LCD_Display_Nibble
	LDA TENS
	JSR LCD_Display_Nibble
	LDA ONES
	JSR LCD_Display_Nibble
	RTS

;input in accumulator (destructive)
LCD_Display_16_Hex:
	LDA INTACC1
	JSR LCD_Display_Byte_Hex
	LDA INTACC1+1
	JSR LCD_Display_Byte_Hex
	RTS
