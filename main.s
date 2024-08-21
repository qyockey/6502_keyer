VECTORS         = $fffa
RESET           = $8000

DIT_MASK        = $01                   ; Active low
DAH_MASK        = $02                   ; Active low
RELEASED        = DIT_MASK | DAH_MASK

DIT_TICKS       = $02
DELAY_TICKS     = $02

PADDLE_MASK     = DIT_MASK | DAH_MASK
CW_HIGH_MASK    = $04                   ; OR to set, XOR to toggle
CW_LOW_MASK     = ~CW_HIGH_MASK & $ff   ; AND to reset

TX_HIGH_MASK    = $08                   ; OR to set, XOR to toggle
TX_LOW_MASK     = ~TX_HIGH_MASK & $ff   ; AND to reset

FALSE           = $00
TRUE            = $01

curr_pulse_type = $00
ticks_remaining = $01
delaying        = $03

    .org RESET
reset:

    ldx #$ff                    ; Start stack at $01ff instead of random start
    txs

    lda #%00000100              ; 7-3 unused, 2 cw, 1 dah, 0 dit
    sta DDRA

    jsr timer_1_free_run_mode   ; Set timer to free-run mode for recurring ticks
    cli                         ; Clear IRQ disable

    lda FALSE                   ; Transmitting pulse upon paddle press
    sta delaying                ;

input_wait:                     ; Monitor paddle until input provided
    lda PORTA                   ; Read paddle state + rest of Port A
    and #PADDLE_MASK            ; Ignore rest of Port A
    bne input_wait              ; Repeat while paddle released

send_paddle:                    ; Send paddle input
    sta ticks_remaining         ; Set tick count for pulse

    ; Start recurring 120 ms ticks
    ldy #$ea
    ldx #$5e
    jsr timer_1_set

    ; Start keyer output
    lda PORTA
    ora #CW_HIGH_MASK
    sta PORTA

monitor_wait_tick:              ; Wait for tick down
    wai                         ; Remove later when needing to monitor paddle
    lda ticks_remaining         ; Leave loop after pulse elapsed
    bne monitor_timeout_check   ; Monitor paddle until timeout

    ; Toggle pulse/delay state
    lda delaying                ; Check if keying or delaying
    eor #TRUE                   ; Toggle delay state
    beq send_next_pulse         ; If delay ended, send next pulse
    lda PORTA                   ; Otherwise if pulse ended, start delay
    and #CW_LOW_MASK            ; Stop keyer output
    sta PORTA                   ;
    lda #DELAY_TICKS            ; Delay for one tick
    sta ticks_remaining         ;
    bra monitor_timeout_check   ; Monitor paddle until delay timout

send_next_pulse:                ; Setup to send next pulse, or halt
    lda PORTA                   ; Read paddle state + rest of Port A
    and #PADDLE_MASK            ; Ignore rest of Port A
    cmp #RELEASED               ; Check if released
    beq input_wait              ; Released -> wait for input
    lda #DIT                    ; If same, load same pulse
    bra send_paddle             ; Send same pulse

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

