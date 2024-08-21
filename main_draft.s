; WPM     = 10

VECTORS         = $fffa
RESET           = $8000

RELEASED        = $00
DIT             = $01
DAH             = $02

DIT_TICKS       = $02
DAH_TICKS       = $06
DELAY_TICKS     = $02

PADDLE_MASK     = DIT | DAH
CW_HIGH_MASK    = $04                   ; OR to set, XOR to toggle
CW_LOW_MASK     = ~CW_HIGH_MASK & $ff   ; AND to reset

TX_HIGH_MASK    = $08                   ; OR to set, XOR to toggle
TX_LOW_MASK     = ~TX_HIGH_MASK & $ff   ; AND to reset

FALSE           = $00
TRUE            = $01

curr_pulse_type = $00
ticks_remaining = $01
toggle_next     = $02
delaying        = $03

    .org RESET
reset:

    ldx #$ff                    ; Start stack at $01ff instead of random start
    txs

    ; jsr lcd_init ; add later

    lda #%11101100 ; 7-5 LCD control, 4 unused, 3 tx, 2 cw, 1 dah, 0 dit
    sta DDRA

    jsr timer_1_free_run_mode

    lda FALSE                   ; Transmitting pulse upon paddle press
    sta delaying                ;

; initial version only worry about dit, remove dah logic for now
; add PORTA.3 TX line

input_wait:                     ; Monitor paddle until input provided
    lda PORTA                   ; Read paddle state + rest of Port A
    and #PADDLE_MASK            ; Ignore rest of Port A
    beq input_wait              ; Repeat while paddle released
    cmp #(DIT | DAH)            ; Check for both dit and dah pressed
    beq set_current_pulse       ; Set state immediately if only one pressed
    lda #TRUE                   ; Set toggle if both pressed
    sta toggle_next             ; A = DIT, fallthrough send dit first
set_current_pulse:              ; Set current pulse type
    sta curr_pulse_type         ; 

send_paddle:                    ; Send paddle input
    ora #DIT                    ; Dit -> 1 tick, Dah -> 3 ticks
    asl                         ; Dit -> 2 tick, Dah -> 6 ticks
    sta ticks_remaining         ; Set tick count for pulse
    ldy #$ea                    ; Start recurring 120 ms ticks
    ldx #$5e                    ;
    jsr timer_1_set             ;

    lda PORTA                   ; Start keyer output
    ora #CW_HIGH_MASK           ;
    sta PORTA                   ;

monitor_paddle:                 ; Monitor paddle state while transmitting
    lda PORTA                   ; Read paddle state + rest of Port A
    and #PADDLE_MASK            ; Ignore rest of Port A
    beq monitor_timeout_check   ; Both paddles released -> don't update next
    eor curr_pulse_type         ; Get differing bits current vs paddle
    beq monitor_timeout_check   ; Same input -> don't update next
    lda #TRUE                   ; Different output -> toggle next
    sta toggle_next             ;
monitor_timeout_check:          ; Check for pulse/delay timeout
    lda ticks_remaining         ; Leave loop after pulse elapsed
    bne monitor_paddle          ; Monitor paddle until timeout
    lda delaying                ; TX timeout, check if keying or delaying
    eor #TRUE
    beq send_next_pulse         ; If delay ended, send next pulse
    lda PORTA                   ; Otherwise if pulse ended, start delay
    and #CW_LOW_MASK            ; Stop keyer output
    sta PORTA                   ;
    lda #DELAY_TICKS            ; Delay for one tick
    sta ticks_remaining         ;
    bra monitor_paddle          ; Monitor paddle until delay timout

send_next_pulse:                ; Setup to send next pulse, or halt
    lda PORTA                   ; Read paddle state + rest of Port A
    and #PADDLE_MASK            ; Ignore rest of Port A
    cmp #RELEASED               ; Check if released
    beq input_wait              ; Released -> wait for input
    lda toggle_next             ; Check whether to toggle
    cmp #TRUE                   ;
    beq send_toggled            ; Toggle pulse if needed
    lda curr_pulse_type         ; If same, load same pulse
    bra send_paddle             ; Send same pulse
send_toggled:                   ; Toggle pulse to send
    lda curr_pulse_type         ; Get current pulse type
    eor #(DIT | DAH)            ; Toggle dit <-> dah
    sta curr_pulse_type         ; Store toggled pulse to next
    bra send_paddle             ; Send toggled paddle

nmi:
    rti
irq:
    dec ticks_remaining
    jsr timer_1_clear_interrupt
    rti

    .include display.s
    .include timer.s

    .org VECTORS
    .word nmi
    .word reset
    .word irq

