BASIC = $0801
* = BASIC
    !byte $0b, $08
    !byte $E3
    !byte $07, $9E
    !byte '0' + entry % 10000 / 1000        
    !byte '0' + entry %  1000 /  100        
    !byte '0' + entry %   100 /   10        
    !byte '0' + entry %    10             
    !byte $00, $00, $00

SCREENRAM = $0400
SCREENRAM_1 = SCREENRAM + 250
SCREENRAM_2 = SCREENRAM + 500
SCREENRAM_3 = SCREENRAM + 750
CHAR_COLOR = $d800

;------------------------------------------
; Macros

!macro store .target, .value {
    lda #.value
    sta .target
}

;------------------------------------------
; void clear()
; Clear the screen
clear
    ldx #250
    lda #$20
-   sta SCREENRAM, x
    sta SCREENRAM_1, x
    sta SCREENRAM_2, x
    sta SCREENRAM_3, x
    dex
    bne -
    rts


VOLUME = $d418
VOICE_1_FREQ_LOW = $d400
VOICE_1_FREQ_HIGH = $d401
VOICE_1_CTRL = $d404
VOICE_1_ATTACK_DECAY = $d405
VOICE_1_SUSTAIN_RELEASE = $d406

;------------------------------------------
; void make_sound()
; Sound!
make_sound
    sei

    +store VOLUME, $0f

    +store VOICE_1_ATTACK_DECAY, $11
    +store VOICE_1_SUSTAIN_RELEASE, $11
    
    +store VOICE_1_FREQ_LOW, $34
    +store VOICE_1_FREQ_HIGH, $10
    
    +store VOICE_1_CTRL, $21

;    ldy #$00
;    ldx #$00
;-   inx
;    bne -
;    iny
;    bne -

    +store VOICE_1_CTRL, $20

    cli
    rts

;------------------------------------------
; void draw_test_text()
draw_test_text:
    ldx #0
-   txa
    sta SCREENRAM_1, x
    sta CHAR_COLOR + 250, x
    inx
    cpx #27
    bne -
    rts

;------------------------------------------
; void draw_hello_world()
draw_hello_world:
    ldx #$00

-   lda .hello_world, x
    beq +
    sta SCREENRAM, x
    inx
    jmp -
+   rts
.hello_world
    !scr "hello world!",0    ; our string to display

RASTER_LINE_HIGH_BIT = $d011
RASTER_LINE = $d012
BORDERCOLOR = $d020
BGCOLOR = $d021

GETIN = $ffe4

;------------------------------------------
; void entry()
; Program entrypoint
BACKGROUND_COLOR = *: !byte 6
entry

    lda BACKGROUND_COLOR
    sta BGCOLOR

    ;jsr make_sound
    jsr clear
    ;jsr $e544

    JSR GETIN
    beq +
    inc BACKGROUND_COLOR

+   jsr draw_hello_world
    jsr draw_test_text

    lda #0
    sta BORDERCOLOR

-   lda #251
    cmp RASTER_LINE
    bne -

    lda #5
    sta BORDERCOLOR

    jmp entry