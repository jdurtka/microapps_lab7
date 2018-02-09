
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 5 - Real-Time Clock (RTC) on i2c bus
;
;*******************************************************************

; i2c bus routines
; 
; These are bit-banged i2c bus routines.
; 


           INCLUDE 'derivative.inc' 

           ;XDEFs and XREFs
           
           ;Start i2c bus in known condition (i.e. the idle state)
           XDEF i2c_setup
           
           ;Send the start condition and the address+R/W bit (in the accumulator)
           XDEF i2c_address
           ;Same as above, but with a repeated start condition
           XDEF i2c_address_repst
           
           ;not necessary as these are handled by i2c_address and i2c_address_repst
           ;XDEF i2c_start_condition
           ;XDEF i2c_repeated_start
           
           ;Must be used to end every transaction
           XDEF i2c_stop_condition
           
           XDEF i2c_send_8bit
           ;XDEF i2c_recv_ack
           
           XDEF i2c_recv_8bit
           XDEF i2c_send_ack
           XDEF i2c_send_nack
           
           XREF _delay_loop
           XREF LCD_Display_Byte_Hex
           XREF LCD_Display_Nibble
           

MY_ZEROPAGE: SECTION  SHORT

	;I2C_BITMASK: DC.B %1000000
			
MyCode:     SECTION

;Setup routine: initialize SCL and SDA pins to write mode, both HIGH
i2c_setup:
	JSR i2c_SDA_high
	JSR i2c_SCL_high
	RTS

;i2c bus start condition
i2c_start_condition:
	;SDA low first, then SCL
	JSR i2c_SDA_low
	JSR i2c_SCL_low
	RTS

;i2c bus stop condition
i2c_stop_condition:
	;SCL high first, then SDA
	JSR i2c_SCL_high
	JSR i2c_SDA_high
	RTS
	
;i2c repeated start condition
i2c_repeated_start:
	;SDA high first, then SCL
	JSR i2c_SDA_high
	JSR i2c_SCL_high
	;then start condition
	JSR i2c_start_condition
	RTS

;send whatever is in the accumulator
;return ACK/NACK in accumulator LSB
;(assumes that the address frame has been sent with the LSB = 1 for write)
i2c_send_8bit:
	LDX #$08
	sendloop:
	LSLA
	BCC send_clr			;0=send clear, 1=send set
	
	send_set:
	JSR i2c_SDA_high		;data 1
	BRA bit_done
	
	send_clr:
	JSR i2c_SDA_low			;data 0
	
	;Finished one bit, now shift the bitmask and do the next
	bit_done:
	
	;pulse clock
	JSR i2c_SCL_high
	JSR i2c_SCL_low
	
	DECX			;are we done yet?
	BEQ send_done	;yes=done
	BNE sendloop	;no=else, loop
	
	
	;All 8 bits sent
	send_done:
	
	;get the ACK (this will be returned in the accumulator)
	JSR i2c_recv_ack
	
	RTS
	

;This is the beginning of a transmission/receipt, so it will put the bus
;into start condition, then transmit the address from the accumulator.
;Additional data must be sent/received elsewhere, and the caller is responsible
;for terminating the transaction via i2c_stop_condition.
;
;accumulator (7 MSB = address, 1 LSB = read(1)/write(0)
i2c_address:
	JSR i2c_start_condition
	JSR i2c_send_8bit
	RTS
	
;This is the same as i2c_address, but with a repeated start condition
;(however, the address must be loaded into the accumulator again!)
i2c_address_repst:
	JSR i2c_repeated_start
	JSR i2c_send_8bit
	RTS
	
;receive the 9th bit (only during send transactions!)
i2c_recv_ack:				
	BCLR 2, PTADD				;change to read mode
	BRSET 2, PTAD, rcvackset	;if it's set, set accumulator (this is a NACK)
	;else, clear accumulator (this is an ACK)
	LDA #$00
	BRA rcvackdone
	rcvackset:
	;set the accumulator
	LDA #$FF
	rcvackdone:
	BSET 2, PTADD					;back to write mode
	BCLR 2, PTAD					;keep it low!
	
	JSR i2c_SCL_high				;9th clock pulse
	JSR i2c_SCL_low
	RTS

;send the 9th bit (only during recv transactions!)
i2c_send_ack:
	JSR i2c_SDA_low			;SDA must be pulled low before the 9th clock pulse
	;9th clock pulse!
	JSR i2c_SCL_high
	JSR i2c_SCL_low
	RTS
i2c_send_nack:
	JSR i2c_SDA_high			;SDA must be pulled high before the 9th clock pulse
	;9th clock pulse!
	JSR i2c_SCL_high
	JSR i2c_SCL_low
	RTS

;receive 8 bits off the i2c bus into the accumulator
;(assumes that the address frame has been sent with the LSB = 0 for read)
i2c_recv_8bit:
	BCLR 2, PTADD			;change to read mode
	LDA #$00				;prepare to receive
	LDX #$08				;count down the bits
	rcv8loop:
	LSLA					;shift accumulator for next bit (has no effect on the first bit)
	BRCLR 2, PTAD, rcvclr	;are we receiving a 1 or a 0?
	
	rcvset:
	ORA #$01				;make the LSB 1
	BRA nextbit
	
	rcvclr:
	AND #$FE				;make the LSB 0
	
	nextbit:
	
	;pulse clock
	JSR i2c_SCL_high
	JSR i2c_SCL_low
	
	DECX					;are we done?
	BEQ rcvdone				;yes, we're done
	BRA rcv8loop			;no, go again
	rcvdone:
	;This is left exposed to the application because e.g. 1337 needs a NACK to end read operation
	RTS
	
	

;-----------------------------------------
; i2c helper functions
;-----------------------------------------
; i2c_short_delay
; i2c_SCL_high
; i2c_SCL_low
; i2c_SDA_high
; i2c_SDA_low
;-----------------------------------------
;Note: these ALWAYS ensure that the relevant GPIO is in write-mode	
i2c_SCL_high:
	BSET 3, PTADD
	BSET 3, PTAD
	RTS
i2c_SCL_low:
	BSET 3, PTADD
	BCLR 3, PTAD
	RTS
i2c_SDA_high:
	BSET 2, PTADD
	BSET 2, PTAD
	RTS
i2c_SDA_low:
	BSET 2, PTADD
	BCLR 2, PTAD
	RTS


;(primarily for debugging purposes, to make it easier to see on oscilloscope)	
i2c_short_delay:
	PSHA
	LDA #2
	JSR _delay_loop ;delay 2ms
	PULA
	RTS
