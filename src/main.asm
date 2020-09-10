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

;------------------------------------------
; void entry()
; Program entrypoint
entry
    lda #$06
    sta BGCOLOR
    sta BORDERCOLOR

    jsr clear
    ;jsr $e544

    ldx #$00

character_loop
    lda hello, x
    beq character_end
    sta SCREENRAM, x
    inx
    jmp character_loop
character_end

exit
    jmp exit

hello
    !scr "hello world!",0    ; our string to display