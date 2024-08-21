    .ifndef __TIMER_H
    .defc __TIMER_H = 1

T1CL    = $6004 ; Timer 1 counter low byte
T1CH    = $6005 ; Timer 1 counter high byte
T1LL    = $6006 ; Timer 1 latch low byte
T1LH    = $6007 ; Timer 1 latch high byte
T2CL    = $6008 ; Timer 2 counter low byte
T2CH    = $6009 ; Timer 2 counter high byte
ACR     = $600B ; Auxiliary control register
IFR     = $600D ; Interrupt flag register
IER     = $600E ; Interrupt enable register

T1_ONE_SHOT_MASK    = %00111111
T1_FREE_RUN_MASK    = %01111111
IER_T1              = %01000000
IER_IRQ             = %10000000

timer_1_enable_irq:
    lda #(IER_T1 | IER_IRQ)
    sta IER
    rts

; Set timer 1 operation to one shot mode.
; Modifies A
timer_1_one_shot_mode:
    lda ACR
    and #T1_ONE_SHOT_MASK
    sta ACR
    rts

; Set timer 1 operation to free run mode.
; Modifies A
timer_1_free_run_mode:
    lda ACR
    and #T1_FREE_RUN_MASK
    sta ACR
    rts

; Load given value into timer then start
; Y stores counter high byte, X stores low byte
; Modifies A
timer_1_set:
    stx T1CL
    sty T1CH
    rts

; Clear timer 1 interrupt
; Modifies flags
    .inline
timer_1_clear_interrupt:
    bit T1CL  ; Reading T1CL makes IRQ go away
    rts
    .einline

    .endif

