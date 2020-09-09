BGCOLOR       = $d020
BORDERCOLOR   = $d021
BASIC         = $0801
SCREENRAM     = $0400

* = BASIC

                !byte $0b, $08
                !byte $E3                     ; BASIC line number:  $E2=2018 $E3=2019 etc       
                !byte $07, $9E
                !byte '0' + entry % 10000 / 1000        
                !byte '0' + entry %  1000 /  100        
                !byte '0' + entry %   100 /   10        
                !byte '0' + entry %    10             
                !byte $00, $00, $00           ; end of basic

entry
    lda #$01                ; the color value
    sta BGCOLOR             ; change background color
    sta BORDERCOLOR         ; change border color

    ldy #$0c                ; the string "hello world!" has 12 (= $0c) characters
    ldx #$00                ; start at position 0 of the string

character_loop
    lda hello, x            ; load character number x of the string
    sta SCREENRAM, x        ; save it at position x of the screen ram
    inx                     ; increment x by 1
    dey                     ; decrement y by 1
    bne character_loop      ; is y positive? then repeat
    rts                     ; exit the program

hello
    !scr "hello world!"     ; our string to display