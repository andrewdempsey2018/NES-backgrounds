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
  .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F
;sprites
  .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17

nametable:
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01

.segment "ZEROPAGE"

.segment "CODE"

.segment "VECTORS"
  .word NMI
  .word RESET
  
.segment "CHARS"
;load graphics chr
  .incbin "sprites.chr"