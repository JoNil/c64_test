BGCOLOR       = $d020
BORDERCOLOR   = $d021
BASIC         = $0801
SCREENRAM     = $0400
SCREENRAM_1   = $0500
SCREENRAM_2   = $0600
SCREENRAM_3   = $0700

* = BASIC
    !byte $0b, $08
    !byte $E3                     ; BASIC line number:  $E2=2018 $E3=2019 etc       
    !byte $07, $9E
    !byte '0' + entry % 10000 / 1000        
    !byte '0' + entry %  1000 /  100        
    !byte '0' + entry %   100 /   10        
    !byte '0' + entry %    10             
    !byte $00, $00, $00           ; end of basic

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

entry
    lda #$06                ; the color value
    sta BGCOLOR             ; change background color
    sta BORDERCOLOR         ; change border color

    jsr clear
    ;jsr $e544

    ldy #$0c                ; the string "hello world!" has 12 (= $0c) characters
    ldx #$00                ; start at position 0 of the string

character_loop
    lda hello, x            ; load character number x of the string
    sta SCREENRAM, x        ; save it at position x of the screen ram
    inx                     ; increment x by 1
    dey                     ; decrement y by 1
    bne character_loop      ; is y positive? then repeat

exit
    jmp exit

hello
    !scr "hello world!"     ; our string to display