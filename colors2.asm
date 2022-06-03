; ZX multicolor based on Nirvana+ loop
; https://worldofspectrum.org/forums/discussion/comment/768319#Comment_768319
; https://worldofspectrum.org/forums/discussion/38591/redirect/p1
; 64x48 multicolor in demo - https://www.pouet.net/prod.php?which=62802
PORCH   equ 64-3

        org  0x5ccb
        jmp  0x8000
        org  0x8000
        
init_______________________________
        ld bc,$0018
        ld a,11110000b
        ld hl,$4000
init_a
        ld (hl),a
        inc hl
        djnz init_a
        dec c
        jp nz, init_a
      
        ld bc,$0003
        ld a,$70
init_b
        ld (hl),a
        inc hl
        djnz init_b
        dec c
        jp nz, init_b

screen_loop

        ld sp,(stack)
        ei
        halt
x       di
        ld (stack),sp
        
        ld hl,$0123
        ld de,$4444

porch_____________________________
BORDER macro color
        ld a,color
        out (254),a
endm

;WAIT_RASTER macro line
; rept (224*(PORCH+line)-96-t($)-t(x))/4
;        nop
; endm
;endm

        BORDER 1
;       WAIT_RASTER -4
        ;ld hl, 224*64-100
        ld hl,15806-224*8-100
        call wHL256
        BORDER 2

pixels____________________________


; rept (15806-224*7-t($)-t(x))/4
; rept (224*(PORCH+4)-99-t($)-t(x))/4
;        nop
; endm
	
        
        ld a,1
        out (254),a
	LD SP,$5800+32*0+24

	; starts @ 15806T
        ; 70 lines (64+6) + 126T
        LD IX,$0100 
        LD IY,$0101
        LD BC,$0102
        LD DE,$0103
        LD HL,$0104
        EXX
        LD BC,$0105
        LD DE,$0106
        LD HL,$0107
        LD ($5800+32*0+0),HL   ; columns 0 and 1
        LD HL,$0200
        LD ($5800+32*0+2),HL   ; columns 2 and 3
        LD HL,$0201
        LD ($5800+32*0+4),HL   ; columns 4 and 5
        LD HL,$0203
        PUSH IY      ; columns 22 and 23
        PUSH HL      ; columns 20 and 21
        PUSH DE      ; columns 18 and 19
        PUSH BC      ; columns 16 and 17
        EXX
        PUSH IX      ; columns 14 and 15
        PUSH HL      ; columns 12 and 13
        PUSH DE      ; columns 10 and 11
        PUSH BC      ; columns 8 and 9
        LD HL,$0204
        PUSH HL      ; columns 6 and 7
        LD SP,$5800+32*0+30     ; reference columns 28 and 29
        LD BC,$0205
        LD DE,$0206
        LD HL,$0207
        PUSH HL      ; columns 28 and 29
        PUSH DE      ; columns 26 and 27
        PUSH BC      ; columns 24 and 25
        LD HL,$0208
        LD ($5800+32*0+30),HL   ; columns 30 and 31
        INC HL       ; extra delay
















        ld a,3
        out (254),a

	ld hl,$5800
        ld bc,$0003
        ld a,$70
fill
        ld (hl),a
        inc hl
        djnz fill
        dec c
        jp nz, fill



        jp screen_loop
        
        
wHL256:
        dec     h               ;<0>  | <4>
        ld      a,256-4-4-12-4-7-17-81       ; 81 is wA overhead
                                ;<0>  | <7>
        call    wA              ;<0>  | <17+A>
wHL:    inc     h               ;<4>  | <4>
        dec     h               ;<4>  | <4>
        jr      nz,wHL256       ;<7>  | <12>
        ld      a,l             ;<4>
wA:     rrca                    ;<4>
        jr      c,wHL_0s        ;<7>  | <12> 1 extra cycle if bit 0 set
        nop                     ;<4>  | <0>
wHL_0s: rrca                    ;<4>
        jr      nc,wHL_1c       ;<12> | <7>  2 extra cycles if bit 1 set
        jr      nc,wHL_1c       ;<0>  | <7>
wHL_1c: rrca                    ;<4>
        jr      nc,wHL_2c       ;<12> | <7>  4 extra cycles if bit 2 set
        ret     nc              ;<0>  | <5>
        nop                     ;<0>  | <4>
wHL_2c: rrca                    ;<4>
        jr      nc,wHL_3c       ;<12> | <7>  8 extra cycles if bit 3 set
        ld      (0),a           ;<0>  | <13>
wHL_3c: and     a,0fh           ;<7>
        ret     z               ;<11> | <5>  done if no other bits set
wHL_16: dec     a               ;<0>  | <4>  loop away 16 for remaining count
        jr      nz,wHL_16       ;<0>  | <12>
        ret     z               ;<0>  | <11>
        
data    dw 0x8880
stack   dw 0

        org 0xff57
        defb 00h




