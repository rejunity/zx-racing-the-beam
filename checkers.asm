; ZX48K checkers on the border
; zmac checkers.asm -o checkers.tap

; https://worldofspectrum.org/faq/reference/48kreference.htm
; 1) Each line takes exactly 224 T states = 128 T (screen) + 96 T (border&retrace)
; 2) Every half T state a pixel is written to the CRT, so if the ULA is reading bytes it does so each 4 T states (and then it reads two: a screen and an ATTR byte).
; 3) The border is 48 pixels wide at each side. A video screen line is therefore timed as follows:
;    128 T states of screen, 24 T states of right border, 48 T states of horizontal retrace and 24 T states of left border.
; 4) After an interrupt occurs, 64 line times (14336 T states; see below for exact timings) pass before the first byte of the screen (16384) is displayed. At least the last 48 of these are actual border-lines; the others may be either border or vertical retrace.
; 5) A frame is (64+192+56)*224=69888 T states (3.5MHz/69888=50.08 Hz interrupt)

PORCH   equ 64
PORT    equ $fe
COLOR_A equ 1
COLOR_B equ 6

        org $8000

start
init_______________________________

        ld b, COLOR_A << 3
        ld c, COLOR_A << 3
        ld d, COLOR_B << 3
        ld e, COLOR_B << 3
        ld h, COLOR_B << 3
        ld l, COLOR_A << 3
        exx
        ld b', COLOR_B << 3
        ld c', COLOR_B << 3
        ld d', COLOR_A << 3
        ld e', COLOR_A << 3
        ld h', COLOR_A << 3
        ld l', COLOR_B << 3
        exx

        ld iy, 0
        add iy, sp                  ; temporarily store SP in IY
        ld sp, $5800+32*24
 rept 8
  rept 3
   rept 5
        push bc
        push de
        push hl
   endm
        push bc
  endm
        exx
 endm
        ld sp, iy

        xor a
        ld h, COLOR_A
        ld l, COLOR_B
        ld bc, PORT

screen_loop
        ei
        halt
frame   di

CONTENDED_CYCLE_COUNT defl 224*4-4  ; initialize with the number of wasted cycles since the start of the frame
                                    ; TODO: I found this number empirically, investigate why this exactly
WAIT_RASTER macro line, cycles_offset
 rept (224*(PORCH+line)+cycles_offset-CONTENDED_CYCLE_COUNT-(t($)-t(frame)))/4
        nop
 endm
endm

ALTERNATE_BORDER_N_TIMES macro times, reg_with_color_a, reg_with_color_b
 rept times
        out (c), reg_with_color_a
        out (c), reg_with_color_b
 endm
endm

CHECKERS_BORDER_LINE macro reg_with_color_a, reg_with_color_b
 ifdef DEBUG
        ; visualize the 1st and the last checker on the line
        ALTERNATE_BORDER_N_TIMES 1, a, a
        ALTERNATE_BORDER_N_TIMES 7, reg_with_color_a, reg_with_color_b
        ALTERNATE_BORDER_N_TIMES 1, a, h
 else
        ALTERNATE_BORDER_N_TIMES 9, reg_with_color_a, reg_with_color_b
 endif
        nop
        nop
endm

CHECKERS_SCREEN_LINE macro reg_with_color_a, reg_with_color_b
        out (c), reg_with_color_a   ; border change #1
        out (c), reg_with_color_b   ; border change #2
        out (c), reg_with_color_a   ; color change "under" the pixels
        CONTENDED_CYCLE_COUNT += 4  ; OUT before is contended, wastes 4 cycles waiting for ULA
 rept (10-1)*3+2                    ; 3 x NOPs == OUT(c),reg
                                    ; 10.6 OUTs per 256 pixels (128 cycles) - 1 out to change border color "under" the pixels
        nop
 endm
        out (c), reg_with_color_b   ; border change #3
        out (c), reg_with_color_a   ; border change #4
 rept (8-4)*3-1                     ; 8 OUTs per border&retrace (96 cycles)
        nop
 endm
endm

top_border_________________________
        WAIT_RASTER -24, -(24+12)

 rept 1
        CHECKERS_BORDER_LINE l, h
 endm
 rept 23
        CHECKERS_BORDER_LINE h, l
 endm

screen_____________________________
        WAIT_RASTER 0, -(24+12)

 rept 4
  rept 24
        CHECKERS_SCREEN_LINE l, h
  endm
  rept 24
        CHECKERS_SCREEN_LINE h, l
   endm
  endm
 endm

bottom_border______________________
        WAIT_RASTER 192, -(24+12)

 rept 24
        CHECKERS_BORDER_LINE l, h
 endm
 rept 1
        CHECKERS_BORDER_LINE h, l
 endm

        jp screen_loop
        
        end start               ; entry point for zmac and pasmo
