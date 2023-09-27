.segment "HEADER"

  .byte $4E, $45, $53, $1A
  .byte $02
  .byte $01
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00, $00, $00, $00, $00

.segment "STARTUP"

RESET:
;disable interrupts and decimal mode
  SEI
  CLD

;disable sound IRQ
  LDX #$40
  STX $4017

;initialize stack register
  LDX #$FF
  TXS

  INX

;zero out the PPU registers.
  STX $2000
  STX $2001

;disable pcm.
  STX $4010

;wait for vblank
:
  BIT $2002
  BPL :-

  TXA

;clear the 2k of internal ram. ($0000–$07FF)
CLEARMEM: 
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  ;prep $0200 - $02FF for dma / sprites
  LDA #$FF
  STA $0200, x
  INX
  BNE CLEARMEM

;wait for vblank
:
  BIT $2002
  BPL :-

;prep PPU $3F10 - $3F1F for sprite and background palettes
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006

  LDX #$00

;load in the palettes
LOADPALETTES:
  LDA PALETTEDATA, X
  STA $2007
  INX
  CPX #$20
  BNE LOADPALETTES

LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0

LoadBackgroundLoop:
    LDA nametable, x     ; load data from address (background + the value in x)
    STA $2007             ; write to PPU
    INX                   ; X = X + 1
    CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
    BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero

LoadAttribute:
    LDA $2002             ; read PPU status to reset the high/low latch
    LDA #$23
    STA $2006             ; write the high byte of $23C0 address
    LDA #$C0
    STA $2006             ; write the low byte of $23C0 address
    LDX #$00              ; start out at 0

LoadAttributeLoop:
    LDA attribute, x      ; load data from address (attribute + the value in x)
    STA $2007             ; write to PPU
    INX                   ; X = X + 1
    CPX #$0f              ; Compare X to hex $08, decimal 8 - copying 8 bytes
    BNE LoadAttributeLoop

;enable interrupts
  CLI

;enable NMI and use second pattern table as background
  LDA #%10010000
  STA $2000

;enable sprites and background
  LDA #%00011110
  STA $2001

;no game logic yet, just loop
LOOP:
  JMP LOOP

;draw sprite data on vblank
NMI:
    LDA #$02
    STA $4014
    RTI

PALETTEDATA:
;background
  .byte $0f,$00,$10,$30,$0f,$02,$21,$31,$0f,$04,$14,$24,$0f,$09,$19,$29
  ;.byte $0f,$00,$10,$30,$0f,$02,$21,$31,$0f,$06,$16,$26,$0f,$09,$19,$29
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
  .word NMI
  .word RESET
  
.segment "CHARS"
;load graphics chr
  .incbin "sprites.chr"