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
SCREENRAM_1 = SCREENRAM + 240
SCREENRAM_2 = SCREENRAM + 480
SCREENRAM_3 = SCREENRAM + 720
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
!zone {
clear
    ldx #240
    lda #$20
-   sta SCREENRAM, x
    sta SCREENRAM_1, x
    sta SCREENRAM_2, x
    sta SCREENRAM_3, x
    dex
    bne -
    rts
}

VOLUME = $d418
VOICE_1_FREQ_LOW = $d400
VOICE_1_FREQ_HIGH = $d401
VOICE_1_CTRL = $d404
VOICE_1_ATTACK_DECAY = $d405
VOICE_1_SUSTAIN_RELEASE = $d406

;------------------------------------------
; void make_sound()
; Sound!
!zone {
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
}

;------------------------------------------
; void draw_test_text()
!zone {
draw_test_text:
    ldx #0
-   txa
    sta SCREENRAM_1 + 6, x
    ;sta CHAR_COLOR + 240 + 6, x
    inx
    cpx #27
    bne -
    rts
}

;------------------------------------------
; void draw_hello_world()
!zone {
draw_hello_world:
    ldx #$00
-   lda .hello_world, x
    beq +
    sta SCREENRAM, x
    inx
    jmp -
+   rts
.hello_world
    !scr "hello world!",0
}

;------------------------------------------
; void scroll_screen_right()
!zone {
scroll_screen_right
    ldx #39

.loop_1
    !for row, 0, 24 {
        lda SCREENRAM + 40 * row - 1, x
        sta SCREENRAM + 40 * row, x
        ;lda CHAR_COLOR + 40 * row - 1, x
        ;sta CHAR_COLOR + 40 * row, x
    }
    dex
    beq +
    jmp .loop_1

+   lda #$20
    !for row, 0, 24 {
        sta SCREENRAM + 40 * row
    }

    rts
}

;------------------------------------------
; void scroll_screen_left()
!zone {
scroll_screen_left
    ldx #0

.loop
    !for row, 0, 24 {
        lda SCREENRAM + 40 * row + 1, x
        sta SCREENRAM + 40 * row, x
        ;lda CHAR_COLOR + 40 * row + 1, x
        ;sta CHAR_COLOR + 40 * row, x
    }
    inx
    cpx #39
    beq +
    jmp .loop

+   lda #$20
    !for row, 0, 24 {
        sta SCREENRAM + 40 * row + 39
    }

    rts
}

Y_SCROLL = $d011
X_SCROLL = $d016

;------------------------------------------
; void scroll_x_plus_1()
!zone {
BACKGROUND_SCROLL_X = *: !byte 0
scroll_x_plus_1
    inc BACKGROUND_SCROLL_X
    lda BACKGROUND_SCROLL_X
    and #$07
    sta BACKGROUND_SCROLL_X

    lda X_SCROLL
    and #$f8
    ora BACKGROUND_SCROLL_X
    sta X_SCROLL

    lda BACKGROUND_SCROLL_X
    bne +
    jsr scroll_screen_right

+   rts
}

;------------------------------------------
; void scroll_x_neg_1()
!zone {
scroll_x_neg_1

    dec BACKGROUND_SCROLL_X
    lda BACKGROUND_SCROLL_X
    and #$07
    sta BACKGROUND_SCROLL_X

    lda X_SCROLL
    and #$f8
    ora BACKGROUND_SCROLL_X
    sta X_SCROLL

    lda BACKGROUND_SCROLL_X
    cmp #7
    bne +
    jsr scroll_screen_left

+   rts
}

;------------------------------------------
; void scroll_y_plus_1()
!zone {
BACKGROUND_SCROLL_Y = *: !byte 0
scroll_y_plus_1

    ;inc BACKGROUND_SCROLL_Y
    ;lda BACKGROUND_SCROLL_Y
    ;and #$07
    ;sta BACKGROUND_SCROLL_Y

    ;lda Y_SCROLL
    ;and #$f8
    ;ora BACKGROUND_SCROLL_Y
    ;sta Y_SCROLL

    rts
}

;------------------------------------------
; void right_pressed()
!zone {
right_pressed
    jsr scroll_x_plus_1
    inc BACKGROUND_COLOR
    rts
}

;------------------------------------------
; void left_pressed()
!zone {
left_pressed
    jsr scroll_x_neg_1
    inc BACKGROUND_COLOR
    rts
}

;------------------------------------------
; void up_pressed()
!zone {
up_pressed

    rts
}

;------------------------------------------
; void down_pressed()
!zone {
down_pressed

    rts
}


RASTER_LINE_HIGH_BIT = $d011
RASTER_LINE          = $d012
BORDERCOLOR          = $d020
BGCOLOR              = $d021

GETIN = $ffe4

PRA  = $dc00 ; CIA#1 (Port Register A)
PRB  = $dc01 ; CIA#1 (Port Register B)
DDRA = $dc02 ; CIA#1 (Data Direction Register A)
DDRB = $dc03 ; CIA#1 (Data Direction Register B)

;------------------------------------------
; void entry()
; Program entrypoint
BACKGROUND_COLOR = *: !byte 6
!zone {
entry
    sei

    lda BACKGROUND_COLOR
    sta BGCOLOR

    ;jsr make_sound
    jsr clear
    ;jsr $e544

    jsr draw_hello_world
    jsr draw_test_text

.loop

.check_keyboard              
    lda #%11111111  ; CIA#1 Port A set to output 
    sta DDRA             
    lda #%00000000  ; CIA#1 Port B set to input
    sta DDRB

; Check D
    lda #%11111011
    sta PRA
    lda PRB
    and #%00000100
    bne +
    jsr right_pressed

+ ; Check A
    lda #%11111101
    sta PRA 
    lda PRB
    and #%00000100
    bne +
    jsr left_pressed

+   lda #0
    sta BORDERCOLOR

; Wait for v-sync
-   lda #251
    cmp RASTER_LINE
    bne -

    lda #5
    sta BORDERCOLOR

    jmp .loop
}