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

.segment "ZEROPAGE"

world:
    .res 2 ;reserve 2 bytes in the zero page. we'll use these two bytes to load in the 960 byte nametable

.segment "STARTUP"

reset:
;disable interrupts and decimal mode
    sei
    cld

;disable sound irq
    ldx #$40
    stx $4017

;initialise stack register
    ldx #$ff
    txs

    inx

;zero out the PPU registers.
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

;prep PPU $3f10 - $3f1f for sprite and background palettes
;$2006 is the PPU address register (aka 'PPUADDR').
;we first set the high byte of the address in the PPU we want to write to and then set the low byte
;we then start writing to the PPU with $2007 ($2007 is the PPUDATA read buffer)
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

;initialize world to point to world data
    lda #<nametable
    sta world
    lda #>nametable
    sta world+1

;using the PPUADDR and the PPUDATA read buffer ($2006 and $2007)
;tell the PPU we are going to start filling up the first nametable (which starts at $2000 in PPU ram)
loadBackground:
    bit $2002 ;read PPU status to reset the high/low latch. use the 'bit' instruction as it is slightly faster (we only want to read from $2002, we don't care about the value)
    lda #$20
    sta $2006 ;write the high byte of $2000 address
    lda #$00
    sta $2006 ;write the low byte of $2000 address
    ldx #$00

;sdfsdf
    ldy #$00
loadWorld:
    lda (world), y
    sta $2007
    iny
    cpx #$03
    bne :+
    cpy #$c0
    beq doneLoadingWorld
:
    cpy #$00
    bne loadWorld
    inx
    inc world+1
    jmp loadWorld

doneLoadingWorld:
    ldx #$00

;each nametable has an associated attribute table
;the nametable takes up 960 bytes and the remaining 64 bytes belong to the attribute table (960 + 64 = 1,024)
;as the first nametable starts at $2000 and takes up 960 bytes, the attributes start at $23c0 (960 decimal = 3c0 hex)
loadAttribute:
    lda $2002 ;read PPU status to reset the high/low latch
    lda #$23
    sta $2006 ;write the high byte of $23c0 address
    lda #$c0
    sta $2006 ;write the low byte of $23c0 address
    ldx #$00 ;start out at 0

;load all 64 attribues for this nametable
loadAttributeLoop:
    lda attribute, x ;load data from address (attribute + the value in x)
    sta $2007 ;write to PPU
    inx
    cpx #$40 ;compare x to hex $40, decimal 64 - copying 64 bytes
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
    .byte $31,$00,$10,$30,$31,$02,$21,$31,$31,$04,$14,$24,$31,$09,$19,$29
;sprites
    .byte $31,$00,$10,$30,$31,$02,$21,$31,$31,$06,$16,$26,$31,$09,$19,$29

nametable:
    .incbin "level1.nam"

attribute:
    .byte $00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$cc,$ff,$33,$00
    .byte $00,$80,$00,$00,$00,$00,$00,$00,$00,$cc,$00,$00,$80,$00,$00,$00
    .byte $00,$a8,$22,$00,$cc,$00,$20,$00,$f0,$aa,$aa,$c8,$cc,$80,$a3,$20
    .byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a

.segment "CODE"

.segment "VECTORS"
    .word nmi
    .word reset
 
.segment "CHARS"
;load graphics chr
    .incbin "sprites.chr"