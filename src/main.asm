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
SCREENRAM_1 = SCREENRAM + 250
SCREENRAM_2 = SCREENRAM + 500
SCREENRAM_3 = SCREENRAM + 750

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

; - Do i want to animate by switching char set?
; - Structure code by having main loop do several frames in loop for all the stages
; - Do off screen rendering with double buffering

; Character memory
; $D018 = %xxxx000x -> charmem is at $0000
; $D018 = %xxxx001x -> charmem is at $0800
; $D018 = %xxxx010x -> charmem is at $1000
; $D018 = %xxxx011x -> charmem is at $1800
; $D018 = %xxxx100x -> charmem is at $2000
; $D018 = %xxxx101x -> charmem is at $2800
; $D018 = %xxxx110x -> charmem is at $3000
; $D018 = %xxxx111x -> charmem is at $3800

; Screen memory
; $D018 = %0000xxxx -> screenmem is at $0000
; $D018 = %0001xxxx -> screenmem is at $0400
; $D018 = %0010xxxx -> screenmem is at $0800
; $D018 = %0011xxxx -> screenmem is at $0c00
; $D018 = %0100xxxx -> screenmem is at $1000
; $D018 = %0101xxxx -> screenmem is at $1400
; $D018 = %0110xxxx -> screenmem is at $1800
; $D018 = %0111xxxx -> screenmem is at $1c00
; $D018 = %1000xxxx -> screenmem is at $2000
; $D018 = %1001xxxx -> screenmem is at $2400
; $D018 = %1010xxxx -> screenmem is at $2800
; $D018 = %1011xxxx -> screenmem is at $2c00
; $D018 = %1100xxxx -> screenmem is at $3000
; $D018 = %1101xxxx -> screenmem is at $3400
; $D018 = %1110xxxx -> screenmem is at $3800
; $D018 = %1111xxxx -> screenmem is at $3c00

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
    ldx #250
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
        lda CHAR_COLOR + 40 * row - 1, x
        sta CHAR_COLOR + 40 * row, x
    }
    dex
    beq +
    jmp .loop

+   lda #$0
    !for row, 0, 24 {
        sta SCREENRAM + 40 * row
        sta CHAR_COLOR + 40 * row
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
        lda CHAR_COLOR + 40 * row + 1, x
        sta CHAR_COLOR + 40 * row, x
    }
    inx
    cpx #39
    beq +
    jmp .loop

+   lda #$0
    !for row, 0, 24 {
        sta SCREENRAM + 40 * row + 39
        sta CHAR_COLOR + 40 * row + 39
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
        lda CHAR_COLOR + 40 * row + 40, x
        sta CHAR_COLOR + 40 * row, x
    }
    inx
    cpx #40
    beq +
    jmp .loop

+   lda #$0
    !for col, 0, 39 {
        sta SCREENRAM + 40 * 24 + col
        sta CHAR_COLOR + 40 * 24 + col
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
        lda CHAR_COLOR + 40 * (23 - row), x
        sta CHAR_COLOR + 40 * (24 - row), x
    }
    inx
    cpx #40
    beq +
    jmp .loop

+   lda #$0
    !for col, 0, 39 {
        sta SCREENRAM + col
        sta CHAR_COLOR + col
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

ANIMATION_DELAY = *: !byte 0
ANIMATION_FRAME_COUNT = *: !byte 0

;------------------------------------------
; void animate()
!zone {
animate

    inc ANIMATION_DELAY
    lda ANIMATION_DELAY
    cmp #4
    beq +
    rts
    
+   lda #0
    sta ANIMATION_DELAY

    lda ANIMATION_FRAME_COUNT
    adc #%01000000
    and #%11000000
    sta ANIMATION_FRAME_COUNT

    ldx #250

.loop:
    lda SCREENRAM, x
    and #%00111111
    ora ANIMATION_FRAME_COUNT
    sta SCREENRAM, x

    lda SCREENRAM_1, x
    and #%00111111
    ora ANIMATION_FRAME_COUNT
    sta SCREENRAM_1, x

    lda SCREENRAM_2, x
    and #%00111111
    ora ANIMATION_FRAME_COUNT
    sta SCREENRAM_2, x

    lda SCREENRAM_3, x
    and #%00111111
    ora ANIMATION_FRAME_COUNT
    sta SCREENRAM_3, x

    dex
    bne .loop
    rts
}

RESOLVE_BELT_DELAY = *: !byte 0

;------------------------------------------
; void resolve_belt_rules()
!zone {
resolve_belt_rules

    inc RESOLVE_BELT_DELAY
    lda RESOLVE_BELT_DELAY
    cmp #12
    beq .start
    cmp #16
    bne +
    lda #0
    sta RESOLVE_BELT_DELAY
+   rts

.start 
!for row, 0, 24 {
!zone {
   ldx #1
.loop

    lda SCREENRAM + row*40, x
    and #%00111111    ; Remove the animation part of the tile no

    cmp #17           ; If we are on a left tile with content
    beq +
    cmp #21
    beq +
    cmp #25
    bne .next

+   lda SCREENRAM + row*40 - 1, x
    and #%00010000
    bne .next

    lda SCREENRAM + row*40 - 1, x
    ora #%00010000
    sta SCREENRAM + row*40 - 1, x
    lda SCREENRAM + row*40, x
    and #%11101111
    sta SCREENRAM + row*40, x

.next:
    inx
    cpx #40
    bne .loop
}
}

!for row, 0, 24 {
!zone {
   ldx #39
.loop

    lda SCREENRAM + row*40 - 1, x
    and #%00111111    ; Remove the animation part of the tile no

    cmp #19           ; If we are on a right tile with content
    beq +
    cmp #23
    beq +
    cmp #27
    bne .next

+   lda SCREENRAM + row*40, x
    and #%00010000
    bne .next

    lda SCREENRAM + row*40, x
    ora #%00010000
    sta SCREENRAM + row*40, x
    lda SCREENRAM + row*40 - 1, x
    and #%11101111
    sta SCREENRAM + row*40 - 1, x

.next:
    dex
    bne .loop
}
}

!for row, 1, 24 {
!zone {
   ldx #40
.loop

    lda SCREENRAM + row*40 - 1, x
    and #%00111111    ; Remove the animation part of the tile no

    cmp #18           ; If we are on a up tile with content
    beq +
    cmp #22
    beq +
    cmp #26
    bne .next

+   lda SCREENRAM + row*40 - 1 - 40, x
    and #%00010000
    bne .next

    lda SCREENRAM + row*40 - 1 - 40, x
    ora #%00010000
    sta SCREENRAM + row*40 - 1 - 40, x
    lda SCREENRAM + row*40 - 1, x
    and #%11101111
    sta SCREENRAM + row*40 - 1, x

.next:
    dex
    bne .loop
}
}

!for row, 23, 0 {
!zone {
   ldx #40
.loop

    lda SCREENRAM + row*40 - 1, x
    and #%00111111    ; Remove the animation part of the tile no

    cmp #20           ; If we are on a down tile with content
    beq +
    cmp #24
    beq +
    cmp #28
    bne .next

+   lda SCREENRAM + row*40 + 40 - 1, x
    and #%00010000
    bne .next

    lda SCREENRAM + row*40 + 40 - 1, x
    ora #%00010000
    sta SCREENRAM + row*40 + 40 - 1, x
    lda SCREENRAM + row*40 - 1, x
    and #%11101111
    sta SCREENRAM + row*40 - 1, x

.next:
    dex
    bne .loop
}
}
    
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
    sta VIC_BORDER_COLOR
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

    jsr resolve_belt_rules
    jsr animate

; Check Keyboard
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

    ; Measure Perf with background color
    lda #5
    sta VIC_BORDER_COLOR

    jmp .loop
}

END_OF_CODE = *

; Charset Data
* = $3800
!byte $00,$00,$00,$00,$00,$00,$00,$00,$55,$59,$59,$65,$65,$59,$59,$55
!byte $55,$55,$69,$69,$96,$96,$55,$55,$55,$65,$65,$59,$59,$65,$65,$55
!byte $55,$55,$96,$96,$69,$69,$55,$55,$95,$95,$a9,$a9,$55,$54,$54,$50
!byte $55,$5a,$6a,$65,$65,$25,$15,$05,$05,$15,$15,$55,$6a,$6a,$56,$56
!byte $50,$54,$58,$59,$59,$a9,$a5,$55,$50,$54,$54,$55,$a9,$a9,$95,$95
!byte $55,$a5,$a9,$59,$59,$58,$54,$50,$56,$56,$6a,$6a,$55,$15,$15,$05
!byte $05,$15,$25,$65,$65,$6a,$5a,$55,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$3c,$3c,$3c,$3c,$00,$00,$55,$59,$7d,$7d,$7d,$7d,$59,$55
!byte $55,$55,$7d,$7d,$be,$be,$55,$55,$55,$65,$7d,$7d,$7d,$7d,$65,$55
!byte $55,$55,$be,$be,$7d,$7d,$55,$55,$95,$95,$bd,$bd,$7d,$7c,$54,$50
!byte $55,$5a,$7e,$7d,$7d,$3d,$15,$05,$05,$15,$3d,$7d,$7e,$7e,$56,$56
!byte $50,$54,$7c,$7d,$7d,$bd,$a5,$55,$50,$54,$7c,$7d,$bd,$bd,$95,$95
!byte $55,$a5,$bd,$7d,$7d,$7c,$54,$50,$56,$56,$7e,$7e,$7d,$3d,$15,$05
!byte $05,$15,$3d,$7d,$7d,$7e,$5a,$55,$00,$00,$00,$00,$00,$00,$00,$00
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
!byte $00,$00,$00,$00,$00,$00,$00,$00,$55,$65,$65,$95,$95,$65,$65,$55
!byte $69,$69,$96,$96,$55,$55,$55,$55,$55,$59,$59,$56,$56,$59,$59,$55
!byte $55,$55,$55,$55,$96,$96,$69,$69,$55,$65,$65,$95,$95,$64,$64,$50
!byte $69,$6a,$96,$95,$55,$15,$15,$05,$05,$19,$19,$56,$56,$59,$59,$55
!byte $50,$54,$54,$55,$56,$96,$a9,$69,$50,$64,$64,$95,$95,$65,$65,$55
!byte $69,$a9,$96,$56,$55,$54,$54,$50,$55,$59,$59,$56,$56,$19,$19,$05
!byte $05,$15,$15,$55,$95,$96,$6a,$69,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$3c,$3c,$3c,$3c,$00,$00,$55,$65,$f5,$f5,$f5,$f5,$65,$55
!byte $7d,$7d,$be,$be,$55,$55,$55,$55,$55,$59,$5f,$5f,$5f,$5f,$59,$55
!byte $55,$55,$55,$55,$be,$be,$7d,$7d,$55,$65,$f5,$f5,$f5,$f4,$64,$50
!byte $7d,$7e,$be,$bd,$55,$15,$15,$05,$05,$19,$1f,$5f,$5f,$5f,$59,$55
!byte $50,$54,$54,$55,$7e,$be,$bd,$7d,$50,$64,$f4,$f5,$f5,$f5,$65,$55
!byte $7d,$bd,$be,$7e,$55,$54,$54,$50,$55,$59,$5f,$5f,$5f,$1f,$19,$05
!byte $05,$15,$15,$55,$bd,$be,$7e,$7d,$00,$00,$00,$00,$00,$00,$00,$00
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
!byte $00,$00,$00,$00,$00,$00,$00,$00,$55,$95,$95,$56,$56,$95,$95,$55
!byte $96,$96,$55,$55,$55,$55,$69,$69,$55,$56,$56,$95,$95,$56,$56,$55
!byte $69,$69,$55,$55,$55,$55,$96,$96,$69,$a9,$95,$55,$55,$94,$94,$50
!byte $96,$96,$55,$56,$56,$15,$15,$05,$05,$16,$16,$55,$55,$56,$6a,$69
!byte $50,$54,$54,$95,$95,$55,$96,$96,$50,$94,$94,$55,$55,$95,$a9,$69
!byte $96,$96,$55,$95,$95,$54,$54,$50,$69,$6a,$56,$55,$55,$16,$16,$05
!byte $05,$15,$15,$56,$56,$55,$96,$96,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$3c,$3c,$3c,$3c,$00,$00,$55,$95,$d5,$d6,$d6,$d5,$95,$55
!byte $be,$be,$55,$55,$55,$55,$69,$69,$55,$56,$57,$97,$97,$57,$56,$55
!byte $69,$69,$55,$55,$55,$55,$be,$be,$7d,$bd,$d5,$d5,$d5,$d4,$94,$50
!byte $be,$be,$55,$55,$55,$15,$15,$05,$05,$16,$17,$57,$57,$57,$56,$55
!byte $50,$54,$54,$55,$55,$55,$be,$be,$50,$94,$d4,$d5,$d5,$d5,$bd,$7d
!byte $be,$be,$d5,$d5,$d5,$d4,$54,$50,$7d,$7e,$57,$57,$57,$17,$16,$05
!byte $05,$15,$17,$57,$57,$57,$be,$be,$00,$00,$00,$00,$00,$00,$00,$00
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
!byte $00,$00,$00,$00,$00,$00,$00,$00,$55,$56,$56,$59,$59,$56,$56,$55
!byte $55,$55,$55,$55,$69,$69,$96,$96,$55,$95,$95,$65,$65,$95,$95,$55
!byte $96,$96,$69,$69,$55,$55,$55,$55,$96,$96,$69,$69,$55,$54,$54,$50
!byte $55,$56,$56,$59,$59,$16,$16,$05,$05,$15,$15,$55,$69,$69,$96,$96
!byte $50,$94,$94,$65,$65,$95,$95,$55,$50,$54,$54,$55,$69,$69,$96,$96
!byte $55,$95,$95,$65,$65,$94,$94,$50,$96,$96,$69,$69,$55,$15,$15,$05
!byte $05,$16,$16,$59,$59,$56,$56,$55,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$3c,$3c,$3c,$3c,$00,$00,$55,$56,$5f,$5f,$5f,$5f,$56,$55
!byte $55,$55,$55,$55,$7d,$7d,$be,$be,$55,$95,$f5,$f5,$f5,$f5,$95,$55
!byte $be,$be,$7d,$7d,$55,$55,$55,$55,$be,$be,$7d,$7d,$55,$54,$54,$50
!byte $55,$56,$5f,$5f,$5f,$1f,$16,$05,$05,$15,$15,$55,$7d,$7d,$be,$be
!byte $50,$94,$f4,$f5,$f5,$f5,$95,$55,$50,$54,$54,$55,$7d,$7d,$be,$be
!byte $55,$95,$f5,$f5,$f5,$f4,$94,$50,$be,$be,$7d,$7d,$55,$15,$15,$05
!byte $05,$16,$1f,$5f,$5f,$5f,$56,$55,$00,$00,$00,$00,$00,$00,$00,$00
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
!byte $00,$00,$00,$00,$0c,$01,$01,$01,$09,$00,$00,$00,$07,$03,$03,$03
!byte $03,$13,$03,$03,$03,$03,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00
!byte $02,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
!byte $00,$07,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$04,$00,$00,$00,$12,$00,$00,$00,$02,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$14,$00,$00,$02,$0b,$03,$03,$03,$03,$03
!byte $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00
!byte $02,$00,$00,$00,$12,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00
!byte $00,$02,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$0b,$03,$03,$03,$0a,$00,$00,$00,$02,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$04,$00,$00,$06,$01,$01,$01,$01,$01,$01
!byte $05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$06,$01,$01,$01,$01,$01,$11,$01,$01,$01,$05,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$11
!byte $01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $41,$41,$41,$41,$41,$41,$41,$51,$41,$41,$41,$41,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$81,$81,$81,$81,$81,$81,$81,$91
!byte $81,$81,$81,$81,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $c1,$c1,$c1,$c1,$c1,$c1,$d1,$c1,$c1,$c1,$c1,$c1,$00,$00,$00,$00
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
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00