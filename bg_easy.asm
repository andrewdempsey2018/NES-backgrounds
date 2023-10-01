.segment "HEADER"

    .byte $4e, $45, $53, $1a
    .byte $02
    .byte $01
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00, $00, $00, $00, $00

.segment "STARTUP"

reset:
;disable interrupts and decimal mode
    sei
    cld

;disable sound irq
    ldx #$40
    stx $4017

;initialize stack register
    ldx #$ff
    txs

    inx

;zero out the ppu registers.
    stx $2000
    stx $2001

;disable pcm.
    stx $4010

;wait for vblank
:
    bit $2002
    bpl :-

    txa

;clear the 2k of internal ram. ($0000–$07ff)
clearMem:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
;prep $0200 - $02ff for dma / sprites
    lda #$ff
    sta $0200, x
    inx
    bne clearMem

;wait for vblank
:
    bit $2002
    bpl :-

;prep ppu $3f10 - $3f1f for sprite and background palettes
    lda #$3f
    sta $2006
    lda #$00
    sta $2006

   ldx #$00

;load in the palettes
loadPalettes:
    lda paletteData, x
    sta $2007
    inx
    cpx #$20
    bne loadPalettes

loadBackground:
    lda $2002             ; read ppu status to reset the high/low latch
    lda #$20
    sta $2006             ; write the high byte of $2000 address
    lda #$00
    sta $2006             ; write the low byte of $2000 address
    ldx #$00              ; start out at 0

loadBackgroundLoop:
      lda nametable, x     ; load data from address (background + the value in x)
      sta $2007             ; write to ppu
      inx                   ; x = x + 1
      cpx #$80              ; compare x to hex $80, decimal 128 - copying 128 bytes
      bne loadBackgroundLoop  ; branch to loadbackgroundloop if compare was not equal to zero

loadAttribute:
      lda $2002             ; read ppu status to reset the high/low latch
      lda #$23
      sta $2006             ; write the high byte of $23c0 address
      lda #$c0
      sta $2006             ; write the low byte of $23c0 address
      ldx #$00              ; start out at 0

loadAttributeLoop:
      lda attribute, x      ; load data from address (attribute + the value in x)
      sta $2007             ; write to ppu
      inx                   ; x = x + 1
      cpx #$0f              ; compare x to hex $08, decimal 8 - copying 8 bytes
      bne loadAttributeLoop

;enable interrupts
    cli

;enable nmi and use second pattern table as background
    lda #%10010000
    sta $2000

;enable sprites and background
    lda #%00011110
    sta $2001

;no game logic yet, just loop
loop:
    jmp loop

;draw sprite data on vblank
nmi:
    lda #$02
    sta $4014
    rti

paletteData:
;background
    .byte $0f,$00,$10,$30,$0f,$02,$21,$31,$0f,$04,$14,$24,$0f,$09,$19,$29
;sprites
    .byte $0f,$00,$10,$30,$0f,$02,$21,$31,$0f,$06,$16,$26,$0f,$09,$19,$29

nametable:
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12
    .byte $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12, $12

attribute:
    .byte %00011011, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00011011
    .byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

.segment "ZEROPAGE"

.segment "CODE"

.segment "VECTORS"
    .word nmi
    .word reset
 
.segment "CHARS"
;load graphics chr
    .incbin "sprites.chr"