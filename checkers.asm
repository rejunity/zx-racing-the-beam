; ZX48K checkers on the border
; zmac checkers.asm -o checkers.tap

; https://worldofspectrum.org/faq/reference/48kreference.htm
; 1) Each line takes exactly 224 T states.
; 2) Every half T state a pixel is written to the CRT, so if the ULA is reading bytes it does so each 4 T states (and then it reads two: a screen and an ATTR byte).
; 3) The border is 48 pixels wide at each side. A video screen line is therefore timed as follows:
;    128 T states of screen, 24 T states of right border, 48 T states of horizontal retrace and 24 T states of left border.
; 4) After an interrupt occurs, 64 line times (14336 T states; see below for exact timings) pass before the first byte of the screen (16384) is displayed. At least the last 48 of these are actual border-lines; the others may be either border or vertical retrace.
; 5) A frame is (64+192+56)*224=69888 T states (3.5MHz/69888=50.08 Hz interrupt)

PORCH   equ 60 ; should be 64, but for some reason timing seems to be 4 raster lines behind

        org $8000

start
init_______________________________

screen_loop
        ei
        halt
frame   di

        xor a
        ld h, 1
        ld l, 6
        ld bc, $fe

WAIT_RASTER macro line
 rept (224*(PORCH+line)-t($)-t(frame)+4)/4
        nop
 endm
endm

top_border_________________________
        WAIT_RASTER -24

 rept 12
  rept 9
        out (c), l
        out (c), h
  endm
        nop
        nop
 endm

 rept 12
  rept 9
        out (c), h
        out (c), l
  endm
        nop
        nop
 endm

pixels_____________________________

        ld a, 2
        out (c), a

bottom_border______________________
        WAIT_RASTER 192

 rept 12
  rept 9
        out (c), l
        out (c), h
  endm
        nop
        nop
 endm

 rept 12
  rept 9
        out (c), h
        out (c), l
  endm
        nop
        nop
 endm

        jp screen_loop
        
        end start               ; entry point for zmac and pasmo
