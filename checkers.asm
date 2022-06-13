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
PORT    equ $fe
COLOR_A equ 1
COLOR_B equ 6

        org $8000

start
init_______________________________

        xor a
        ld h, COLOR_A
        ld l, COLOR_B
        ld bc, PORT

screen_loop
        ei
        halt
frame   di

WAIT_RASTER macro line
 rept (224*(PORCH+line)-(24+12)-(t($)-t(frame)-4))/4
        nop
 endm
endm

ALTERNATE_BORDER_N_TIMES macro times, reg_with_color_a, reg_with_color_b
 rept times
        out (c), reg_with_color_a
        out (c), reg_with_color_b
 endm
endm

top_border_________________________
        WAIT_RASTER -24

 rept 12
        ALTERNATE_BORDER_N_TIMES 1, a, a ; debug, visualize 1st checker
        ALTERNATE_BORDER_N_TIMES 7, l, h
        ALTERNATE_BORDER_N_TIMES 1, a, h ; debug, visualize last checker on the 1st border line
        nop
        nop
 endm
 rept 12
        ALTERNATE_BORDER_N_TIMES 9, h, l
        nop
        nop
 endm

pixels_____________________________
        WAIT_RASTER 0

 rept 8
  rept 12
        out (c), l ; border change #1
        out (c), h ; border change #2
        out (c), l ; color change "under" the pixels
   rept (10-1)*3+2 ; 3 x NOPs == OUT(c),reg
                   ; 10.6 OUTs per 256 pixels (128 cycles) - 1 out to change border color "under" the pixels
        nop
   endm
        out (c), h ; border change #3
        out (c), l ; border change #4
   rept (8-4)*3-1  ; 8 OUTs per border&retrace (96 cylcles)
        nop
   endm
  endm
  rept 12
        out (c), h
        out (c), l
        out (c), h
   rept (10-1)*3+2
        nop
   endm
        out (c), l
        out (c), h
   rept (8-4)*3-1
        nop
   endm
  endm
 endm

bottom_border______________________
        ;WAIT_RASTER 192

 rept 12
        ALTERNATE_BORDER_N_TIMES 9, l, h
        nop
        nop
 endm
 rept 12
        ALTERNATE_BORDER_N_TIMES 9, h, l
        nop
        nop
 endm

        jp screen_loop
        
        end start               ; entry point for zmac and pasmo
