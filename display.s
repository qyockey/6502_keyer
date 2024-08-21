    .ifndef __DISPLAY_S
    .defc __DISPLAY_S = 1

PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003

LCD_CLEAR           = %00000001
LCD_HOME            = %00000010
LCD_ENTRY           = %00000100
LCD_DISPLAY_CTL     = %00001000
LCD_CURSOR          = %00010000
LCD_FUNCTION        = %00100000
LCD_CGRAM           = %01000000
LCD_DDRAM           = %10000000

ENTRY_INCREMENT     = %00000010
ENTRY_SHIFT         = %00000001

CTL_DISPLAY_ON      = %00000100
CTL_CURSOR_ON       = %00000010
CTL_BLINK           = %00000001

FUNC_4_BIT          = %00000000
FUNC_8_BIT          = %00010000
FUNC_1_LINE         = %00000000
FUNC_2_LINE         = %00001000
FUNC_5_BY_8_FONT    = %00000000
FUNC_5_BY_10_FONT   = %00000100 ; Unavailable on LCD model

EN = %10000000  ; Toggle to send instruction
RW = %01000000  ; 1 = read, 0 = write
RS = %00100000  ; 1 = data register (R/W), 0 = busy flag (R) or instruction (W)

LCD_BUSY_FLAG = %10000000

display_init:
    lda #%11111111         ; set all pins on port B to output
    sta DDRB
    lda #%11100000         ; set top 3 pins on port A to output
    sta DDRA

    lda #LCD_CLEAR
    jsr lcd_instruction
    lda #LCD_HOME
    jsr lcd_instruction
    lda #(LCD_FUNCTION | FUNC_8_BIT | FUNC_2_LINE | FUNC_5_BY_8_FONT)
    jsr lcd_instruction
    lda #(LCD_DISPLAY_CTL | CTL_DISPLAY_ON | CTL_CURSOR_ON & ~CTL_BLINK)
    jsr lcd_instruction
    lda #(LCD_ENTRY | ENTRY_INCREMENT & ~ENTRY_SHIFT)
    jsr lcd_instruction

    rts

; Pause until LCD instruction has resolved, busy flag reset.
; Modifies none
lcd_wait:
    pha                 ; Save A contents

    stz DDRB            ; Port B is input
    lda #RW             ; Read data from LCD
    sta PORTA
    ora #EN             ; Send instruction
    sta PORTA
_lcd_busy:           
    lda PORTB           ; Check busy flag
    and #LCD_BUSY_FLAG
    bne _lcd_busy       ; Repeat until busy flag clear
    lda #RW             ; Clear enable bit
    sta PORTA

    lda #%11111111      ; Restore Port B to output
    sta DDRB
    pla                 ; Restore A contents
    rts


; Send instruction to LCD display
; A: instruction to send
; Modifies A
lcd_instruction:
    jsr lcd_wait
    sta PORTB           ; Write instruction
    stz PORTA           ; Clear EN/RW/RS
    lda #EN             ; Send instruction
    sta PORTA
    stz PORTA           ; Clear EN/RW/RS
    rts


; Print character to LCD
; A: character to print
; Modifies A
print_char:
    jsr lcd_wait
    sta PORTB           ; Store char data to Port B bus
    lda #RS             ; Write to data register
    sta PORTA
    ora #EN             ; Enable character write
    sta PORTA
    and #(~EN & $ff)    ; Clear enable
    sta PORTA
    rts

    .endif

