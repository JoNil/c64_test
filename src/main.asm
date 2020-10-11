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

; Constants

SCREENRAM = $0400
SCREENRAM_1 = SCREENRAM + 240
SCREENRAM_2 = SCREENRAM + 480
SCREENRAM_3 = SCREENRAM + 720

VIC_Y_SCROLL             = $d011
VIC_RASTER_LINE_HIGH_BIT = $d011
VIC_RASTER_LINE          = $d012
VIC_X_SCROLL             = $d016
VIC_CHAR_PTR             = $d018
VIC_BORDER_COLOR         = $d020
VIC_BGCOLOR              = $d021
VIC_MULTI_COLOR_1        = $d022
VIC_MULTI_COLOR_2        = $d023
VIC_CR2                  = $d016

CIA_PRA  = $dc00 ; CIA#1 (Port Register A)
CIA_PRB  = $dc01 ; CIA#1 (Port Register B)
CIA_DDRA = $dc02 ; CIA#1 (Data Direction Register A)
CIA_DDRB = $dc03 ; CIA#1 (Data Direction Register B)

SID_VOICE_1_FREQ_LOW        = $d400
SID_VOICE_1_FREQ_HIGH       = $d401
SID_VOICE_1_CTRL            = $d404
SID_VOICE_1_ATTACK_DECAY    = $d405
SID_VOICE_1_SUSTAIN_RELEASE = $d406
SID_VOLUME                  = $d418

CHAR_COLOR = $d800
GETIN = $ffe4

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

;------------------------------------------
; void memcpy()
; Clear the screen
!zone {
memcpy
    
    rts
}

;------------------------------------------
; void make_sound()
; Sound!
!zone {
make_sound
    sei

    +store SID_VOLUME, $0f

    +store SID_VOICE_1_ATTACK_DECAY, $11
    +store SID_VOICE_1_SUSTAIN_RELEASE, $11
    
    +store SID_VOICE_1_FREQ_LOW, $34
    +store SID_VOICE_1_FREQ_HIGH, $10
    
    +store SID_VOICE_1_CTRL, $21

;    ldy #$00
;    ldx #$00
;-   inx
;    bne -
;    iny
;    bne -

    +store SID_VOICE_1_CTRL, $20

    cli
    rts
}

;------------------------------------------
; void draw_test_text()
!zone {
draw_test_text:
    ldx #$0
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
    ldx #$0
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

.loop
    !for row, 0, 24 {
        lda SCREENRAM + 40 * row - 1, x
        sta SCREENRAM + 40 * row, x
        ;lda CHAR_COLOR + 40 * row - 1, x
        ;sta CHAR_COLOR + 40 * row, x
    }
    dex
    beq +
    jmp .loop

+   lda #$0
    !for row, 0, 24 {
        sta SCREENRAM + 40 * row
    }

    rts
}

;------------------------------------------
; void scroll_screen_left()
!zone {
scroll_screen_left
    ldx #$0

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

+   lda #$0
    !for row, 0, 24 {
        sta SCREENRAM + 40 * row + 39
    }

    rts
}

;------------------------------------------
; void scroll_screen_up()
!zone {
scroll_screen_up
    ldx #$0

.loop
    !for row, 1, 24 {
        lda SCREENRAM + 40 * row + 40, x
        sta SCREENRAM + 40 * row, x
        ;lda CHAR_COLOR + 40 * row + 40, x
        ;sta CHAR_COLOR + 40 * row, x
    }
    inx
    cpx #40
    beq +
    jmp .loop

+   lda #$0
    !for col, 0, 39 {
        sta SCREENRAM + 40 * 24 + col
    }

    rts
}

;------------------------------------------
; void scroll_screen_down()
!zone {
scroll_screen_down
    
    ldx #$0
.loop
    !for row, 0, 23 {
        lda SCREENRAM + 40 * (23 - row), x
        sta SCREENRAM + 40 * (24 - row), x
    }
    inx
    cpx #40
    beq +
    jmp .loop

+   lda #$0
    !for col, 0, 39 {
        sta SCREENRAM + col
    }

    rts
}

BACKGROUND_SCROLL_X = *: !byte 0
BACKGROUND_SCROLL_Y = *: !byte 0

;------------------------------------------
; void scroll_x_plus_1()
!zone {
scroll_x_plus_1
    inc BACKGROUND_SCROLL_X
    lda BACKGROUND_SCROLL_X
    and #$07
    sta BACKGROUND_SCROLL_X

    lda VIC_X_SCROLL
    and #$f8
    ora BACKGROUND_SCROLL_X
    sta VIC_X_SCROLL

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

    lda VIC_X_SCROLL
    and #$f8
    ora BACKGROUND_SCROLL_X
    sta VIC_X_SCROLL

    lda BACKGROUND_SCROLL_X
    cmp #7
    bne +
    jsr scroll_screen_left

+   rts
}

;------------------------------------------
; void scroll_y_plus_1()
!zone {
scroll_y_plus_1

    inc BACKGROUND_SCROLL_Y
    lda BACKGROUND_SCROLL_Y
    and #$07
    sta BACKGROUND_SCROLL_Y

    lda VIC_Y_SCROLL
    and #$f8
    ora BACKGROUND_SCROLL_Y
    sta VIC_Y_SCROLL

    lda BACKGROUND_SCROLL_Y
    bne +
    jsr scroll_screen_down

+   rts
}

;------------------------------------------
; void scroll_y_neg_1()
!zone {
scroll_y_neg_1

    dec BACKGROUND_SCROLL_Y
    lda BACKGROUND_SCROLL_Y
    and #$07
    sta BACKGROUND_SCROLL_Y

    lda VIC_Y_SCROLL
    and #$f8
    ora BACKGROUND_SCROLL_Y
    sta VIC_Y_SCROLL

    lda BACKGROUND_SCROLL_Y
    cmp #7
    bne +
    jsr scroll_screen_up

+   rts
}

;------------------------------------------
; void right_pressed()
!zone {
right_pressed
    jsr scroll_x_plus_1
    rts
}

;------------------------------------------
; void left_pressed()
!zone {
left_pressed
    jsr scroll_x_neg_1
    rts
}

;------------------------------------------
; void up_pressed()
!zone {
up_pressed
    jsr scroll_y_neg_1
    rts
}

;------------------------------------------
; void down_pressed()
!zone {
down_pressed
    jsr scroll_y_plus_1
    rts
}

;------------------------------------------
; void entry()
; Program entrypoint
BACKGROUND_COLOR = *: !byte 0
!zone {
entry
    sei

    ; Set background color
    lda #$0
    sta VIC_BGCOLOR
    lda #11
    sta VIC_MULTI_COLOR_1
    lda #7
    sta VIC_MULTI_COLOR_2

    ; Enable multi color mode
    lda VIC_CR2
    ora #$10
    sta VIC_CR2

    ; Set char data at $3800
    lda VIC_CHAR_PTR
    ora #$0e
    sta VIC_CHAR_PTR

    ;jsr make_sound
    ;jsr clear
    ;jsr $e544

    ;jsr draw_hello_world
    ;jsr draw_test_text

.loop

.check_keyboard              
    lda #%11111111  ; CIA#1 Port A set to output 
    sta CIA_DDRA             
    lda #%00000000  ; CIA#1 Port B set to input
    sta CIA_DDRB

; Check D
    lda #%11111011
    sta CIA_PRA
    lda CIA_PRB
    and #%00000100
    bne +
    jsr right_pressed

; Check A
+   lda #%11111101
    sta CIA_PRA 
    lda CIA_PRB
    and #%00000100
    bne +
    jsr left_pressed

; Check W
+   lda #%11111101
    sta CIA_PRA 
    lda CIA_PRB
    and #%00000010
    bne +
    jsr up_pressed

; Check S
+   lda #%11111101
    sta CIA_PRA 
    lda CIA_PRB
    and #%00100000
    bne +
    jsr down_pressed

+   lda BACKGROUND_COLOR
    sta VIC_BORDER_COLOR

; Wait for v-sync
-   lda #251
    cmp VIC_RASTER_LINE
    bne -

    lda #5
    sta VIC_BORDER_COLOR

    jmp .loop
}

; Charset Data
* = $3800
!byte $00,$00,$00,$00,$00,$00,$00,$00,$55,$59,$59,$65,$65,$59,$59,$55
!byte $55,$55,$69,$69,$96,$96,$55,$55,$55,$65,$65,$59,$59,$65,$65,$55
!byte $55,$55,$96,$96,$69,$69,$55,$55,$50,$54,$64,$65,$a5,$a5,$55,$55
!byte $65,$65,$69,$69,$55,$54,$54,$50,$05,$15,$15,$55,$69,$69,$59,$59
!byte $55,$55,$5a,$5a,$59,$19,$15,$05,$55,$65,$65,$95,$95,$65,$65,$55
!byte $69,$69,$96,$96,$55,$55,$55,$55,$55,$59,$59,$56,$56,$59,$59,$55
!byte $55,$55,$55,$55,$96,$96,$69,$69,$50,$54,$54,$55,$59,$59,$69,$69
!byte $55,$55,$95,$95,$a5,$a4,$54,$50,$05,$15,$1a,$5a,$56,$56,$55,$55
!byte $69,$69,$65,$65,$55,$15,$15,$05,$55,$56,$56,$59,$59,$56,$56,$55
!byte $55,$55,$55,$55,$69,$69,$96,$96,$55,$95,$95,$65,$65,$95,$95,$55
!byte $96,$96,$69,$69,$55,$55,$55,$55,$90,$94,$94,$95,$55,$55,$55,$55
!byte $5a,$5a,$55,$55,$55,$54,$54,$50,$05,$15,$15,$55,$55,$55,$a5,$a5
!byte $55,$55,$55,$55,$56,$16,$16,$06

; Map Data
* = SCREENRAM
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$03,$03,$03
!byte $03,$03,$03,$03,$03,$03,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$08,$01,$01,$01,$01,$01,$01,$01,$01,$01,$06,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$05,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$08,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00