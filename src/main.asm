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
; void entry()
; Program entrypoint
entry
    lda #$06
    sta BGCOLOR
    sta BORDERCOLOR

    jsr clear
    jsr make_sound
    ;jsr $e544

    ldx #$00

entry_character_loop
    lda entry_hello, x
    beq entry_character_end
    sta SCREENRAM, x
    inx
    jmp entry_character_loop
entry_character_end

entry_exit
    jmp entry_exit

entry_hello
    !scr "hello world!",0    ; our string to display