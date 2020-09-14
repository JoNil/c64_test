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
SCREENRAM_1 = $0500
SCREENRAM_2 = $0600
SCREENRAM_3 = $0700
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
    ldx #$00

clear_loop
    lda #$20
    sta SCREENRAM, x
    sta SCREENRAM_1, x
    sta SCREENRAM_2, x
    sta SCREENRAM_3, x
    dex
    bne clear_loop
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

    +store VOICE_1_ATTACK_DECAY, $61
    +store VOICE_1_SUSTAIN_RELEASE, $c8
    
    +store VOICE_1_FREQ_LOW, $34
    +store VOICE_1_FREQ_HIGH, $10
    
    +store VOICE_1_CTRL, $21

    ldy #$00
    ldx #$00
make_sound_wait:
    inx
    bne make_sound_wait
    iny
    bne make_sound_wait

    +store VOICE_1_CTRL, $20

    cli
    rts

BGCOLOR = $d020
BORDERCOLOR = $d021

;------------------------------------------
; void draw_test_text()
draw_test_text:
    ldx #0
draw_test_text_loop
    txa
    sta SCREENRAM_1, x
    sta CHAR_COLOR, x  ; put A as a color at $d800+x. Color RAM only considers the lower 4 bits, 
                       ; so even though A will be > 15, this will wrap nicely around the 16 available colors
    inx
    cpx #27
    bne draw_test_text_loop
    rts

;------------------------------------------
; void draw_hello_world()
draw_hello_world:

    ldx #$00

draw_hello_world_loop
    lda hello_world, x
    beq draw_hello_world_end
    sta SCREENRAM, x
    inx
    jmp draw_hello_world_loop
draw_hello_world_end
    rts
hello_world
    !scr "hello world!",0    ; our string to display

;------------------------------------------
; void entry()
; Program entrypoint
entry
    lda #$06
    sta BGCOLOR
    sta BORDERCOLOR

    jsr clear
    jsr make_sound
    ;jsr $e544

    jsr draw_hello_world
    jsr draw_test_text

entry_exit
    jmp entry_exit