; ZX48K checkers on the border
; zmac checkers.asm -o checkers.tap

; https://worldofspectrum.org/faq/reference/48kreference.htm
; 1) Each line takes exactly 224 T states = 128 T (screen) + 96 T (border&retrace)
; 2) Every half T state a pixel is written to the CRT, so if the ULA is reading bytes it does so each 4 T states (and then it reads two: a screen and an ATTR byte).
; 3) The border is 48 pixels wide at each side. A video screen line is therefore timed as follows:
;    128 T states of screen, 24 T states of right border, 48 T states of horizontal retrace and 24 T states of left border.
; 4) After an interrupt occurs, 64 line times (14336 T states; see below for exact timings) pass before the first byte of the screen (16384) is displayed. At least the last 48 of these are actual border-lines; the others may be either border or vertical retrace.
; 5) A frame is (64+192+56)*224=69888 T states (3.5MHz/69888=50.08 Hz interrupt)

;DEBUG   equ 1
PORCH   equ 64
PORT    equ $fe
BRIGHT  equ 8
COLOR_A equ (2+BRIGHT)
COLOR_B equ (6+BRIGHT)

        org $8000

start
init_______________________________

screen_loop
        ld sp, (stack)
        ei
        halt                    ; 895 cycles since interrupt
        ld a, (stack)           ; 13 cycles, used here for cycle alignment on 4: 895+13=908
        xor a
frame   di
        ld (stack), sp


        ld sp, raster_script
        pop hl
        pop de
        pop bc
        inc sp
        inc sp
        push bc
        push de
        push hl
        push bc

 irp pattern, <border_pattern_a, border_pattern_b, attribute_pattern_a, attribute_pattern_b>
        ld sp, &pattern
        pop hl
        pop de
        pop bc
        inc sp
        push bc
        push de
        push hl
        ld a,b
        ld (&pattern),a
        exx
 endm



SCROLLX defl 0
        comment ##############
if SCROLLX == 0
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
endif
if SCROLLX == 1
        ld b, COLOR_A << 3
        ld c, COLOR_B << 3
        ld d, COLOR_B << 3
        ld e, COLOR_B << 3
        ld h, COLOR_A << 3
        ld l, COLOR_A << 3
        exx
        ld b', COLOR_B << 3
        ld c', COLOR_A << 3
        ld d', COLOR_A << 3
        ld e', COLOR_A << 3
        ld h', COLOR_B << 3
        ld l', COLOR_B << 3
        exx
endif
if SCROLLX == 2
        ld b, COLOR_B << 3
        ld c, COLOR_B << 3
        ld d, COLOR_B << 3
        ld e, COLOR_A << 3
        ld h, COLOR_A << 3
        ld l, COLOR_A << 3
        exx
        ld b', COLOR_A << 3
        ld c', COLOR_A << 3
        ld d', COLOR_A << 3
        ld e', COLOR_B << 3
        ld h', COLOR_B << 3
        ld l', COLOR_B << 3
        exx
endif
###########
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
        ld h, 2;0;COLOR_A
        ld l, 6;7;COLOR_B
        ld a, (border_pattern_a)
        ld l, a
        ld a, (border_pattern_b)
        ld h, a
        xor a
        ld bc, PORT
        out (c),a

CONTENDED_CYCLE_COUNT defl 912;         ; initialize with the number of wasted cycles since the start of the frame
                                        ; TODO: I found this number empirically and verified it with Fuse
                                        ; investigate, if due to keyboard processing in ROM interrupt taking that much time?
WAIT_CYCLES macro cycles
 cycles_to_wait = (cycles)
 if cycles_to_wait%4!=0 && cycles_to_wait%2==0 && cycles_to_wait>=6
        dec de
        cycles_to_wait-=6
 endif
 if cycles_to_wait%4!=0 && cycles_to_wait%2==0 && cycles_to_wait>=6
        inc de
        cycles_to_wait-=6
 endif
 assert cycles_to_wait%4==0
 rept cycles_to_wait/4
        nop
 endm
endm

WAIT_RASTER macro line, cycles_offset
        WAIT_CYCLES 224*(PORCH+line)+(cycles_offset)-CONTENDED_CYCLE_COUNT-(t($)-t(frame))
 ;rept (224*(PORCH+line)+(cycles_offset)-CONTENDED_CYCLE_COUNT-(t($)-t(frame)))/4
 ;       nop
 ;endm
endm

WAIT_PIXEL macro x, cycles_to_output
        WAIT_CYCLES (x)/2-(cycles_to_output)-(((t($)-(t(frame)+CONTENDED_CYCLE_COUNT)))%224)
endm

START_RASTER_SCRIPT macro raster_script_label
        ld sp, raster_script_label
endm

NEXT_RASTER_SCRIPT_ENTREE macro
        dec de
        ret
endm

CONTENDED_CYCLE_COUNT_AT_THE_BEGINNING_OF_THE_ENTREE defl 0
BEGIN_RASTER_SCRIPT_ENTREE macro
        CONTENDED_CYCLE_COUNT_AT_THE_BEGINNING_OF_THE_ENTREE = CONTENDED_CYCLE_COUNT
endm
END_RASTER_SCRIPT_ENTREE macro label
        WAIT_CYCLES 224-((t($)-t(label)+(CONTENDED_CYCLE_COUNT-CONTENDED_CYCLE_COUNT_AT_THE_BEGINNING_OF_THE_ENTREE))%224)-16
        NEXT_RASTER_SCRIPT_ENTREE
endm

WAIT_PIXEL_IN_RASTER_SCRIPT macro label, x
        WAIT_CYCLES (x)/2-(-24)-((t($)-t(label)+(CONTENDED_CYCLE_COUNT-CONTENDED_CYCLE_COUNT_AT_THE_BEGINNING_OF_THE_ENTREE))%224)
endm

        comment ###################        
        out (c),0
        ; 897 after halt, 914 after align
        ;ld a,7
        ;rept (14342-CONTENDED_CYCLE_COUNT-224*3)/4
        assert (224*64+4-(CONTENDED_CYCLE_COUNT+(t($)-t(frame)))-224*0-12*2+0)%4==0 
        rept (224*64+4-(CONTENDED_CYCLE_COUNT+(t($)-t(frame)))-224*0-12*2+0)/4
                nop
        endm
        ;14318 @ 0x8D1F                         ; 63 lines 14106 (14112) <--- must finish before 14108, 14118
        out (c),l       ; 12 cycles
        ;14330 @ 0x8D21
        out (c),h       ; 14 cycles
        ;14344 @ 0x8D23
        out (c),a
        ;14360          ; 16 cycles
        ;out (c),0
        jp screen_loop
        ###################

        ;comment ###################
        ld ix, (raster_script)
        START_RASTER_SCRIPT ix ; raster_script_0+SCROLLX*(raster_script_1-raster_script_0)
        WAIT_RASTER -24, -(24+12+16-4) ; 8908T
        NEXT_RASTER_SCRIPT_ENTREE    ; -> 8924T , (1st out finishes) 8936,8948,8960 

;_0:     WAIT_RASTER 0, -(24+12)
;        NEXT_RASTER_SCRIPT_ENTREE
;_192:   WAIT_RASTER 192, -(24+12)
;        NEXT_RASTER_SCRIPT_ENTREE
;###################

        comment ###################

ALTERNATE_BORDER_N_TIMES macro times, reg_with_color_a, reg_with_color_b
 rept times
        out (c), reg_with_color_a
        out (c), reg_with_color_b
 endm
endm

CHECKERS_BORDER_LINE macro reg_with_color_a, reg_with_color_b, scroll_x
 ifdef DEBUG
        ; visualize the 1st and the last checker on the line
        ALTERNATE_BORDER_N_TIMES 1, a, a
        ALTERNATE_BORDER_N_TIMES 6, reg_with_color_a, reg_with_color_b
        ALTERNATE_BORDER_N_TIMES 1, a, h
 else
        ALTERNATE_BORDER_N_TIMES 8, reg_with_color_a, reg_with_color_b
 endif
 rept 6+2 - scroll_x%3
        nop
 endm
endm

CHECKERS_SCREEN_LINE macro reg_with_color_a, reg_with_color_b, scroll_x
 rept scroll_x%3
        nop
 endm
        out (c), reg_with_color_a   ; border change #1
        out (c), reg_with_color_b   ; border change #2
        out (c), reg_with_color_a   ; color change "under" the pixels
        CONTENDED_CYCLE_COUNT += 4  ; OUT before is contended, wastes 4 cycles waiting for ULA
 rept (10-1)*3+2+scroll_x%2         ; INVESTIGATE: I had to do scroll_x%2 instead of scroll_x%3 here!!! Why, loosing 4 cycles somewhere?
                                    ; 3 x NOPs == OUT(c),reg
                                    ; 10.6 OUTs per 256 pixels (128 cycles) - 1 out to change border color "under" the pixels
        nop
 endm
        out (c), reg_with_color_b   ; border change #3
        out (c), reg_with_color_a   ; border change #4
 rept (8-4)*3-1-scroll_x%3          ; 8 OUTs per border&retrace (96 cycles)
        nop
 endm
endm

top_border_________________________
        WAIT_RASTER -24, -(24+12)

 rept 1
        CHECKERS_BORDER_LINE l, h, SCROLLX
 endm
 rept 23
        CHECKERS_BORDER_LINE h, l, SCROLLX
 endm

screen_____________________________
        WAIT_RASTER 0, -(24+12)

 rept 4
  rept 24
        CHECKERS_SCREEN_LINE l, h, SCROLLX
  endm
  rept 24
        CHECKERS_SCREEN_LINE h, l, SCROLLX
   endm
  endm
 endm

bottom_border______________________
        WAIT_RASTER 192, -(24+12)

 rept 24
        CHECKERS_BORDER_LINE l, h, SCROLLX
 endm
 rept 1
        CHECKERS_BORDER_LINE h, l, SCROLLX
 endm
###################################

        jp screen_loop


ALTERNATE_BORDER_N_TIMES macro times, reg_with_color_a, reg_with_color_b
 rept times
        out (c), reg_with_color_a
        out (c), reg_with_color_b
 endm
endm

CHECKERS_BORDER_LINE macro label, reg_with_color_a, reg_with_color_b, scroll_x
        BEGIN_RASTER_SCRIPT_ENTREE
        WAIT_PIXEL_IN_RASTER_SCRIPT label, -48+8*scroll_x
 ifdef DEBUG
        ; visualize the 1st and the last checker on the line
        ALTERNATE_BORDER_N_TIMES 1, 0, 0
        ALTERNATE_BORDER_N_TIMES 6, reg_with_color_a, reg_with_color_b
        ALTERNATE_BORDER_N_TIMES 1, 0, reg_with_color_b
 else
        ALTERNATE_BORDER_N_TIMES 8, reg_with_color_a, reg_with_color_b
 endif
        END_RASTER_SCRIPT_ENTREE label       ; rept 6+2 - scroll_x%3
endm

CHECKERS_SCREEN_LINE macro label, reg_with_color_a, reg_with_color_b, scroll_x
        BEGIN_RASTER_SCRIPT_ENTREE
        WAIT_PIXEL_IN_RASTER_SCRIPT label, -48+8*scroll_x
        out (c), reg_with_color_a   ; border change #1
        out (c), reg_with_color_b   ; border change #2

        WAIT_PIXEL_IN_RASTER_SCRIPT label, 128
 ifdef DEBUG
        out (c), a
 else
        out (c), reg_with_color_a   ; color change "under" the pixels
 endif
        CONTENDED_CYCLE_COUNT += 4  ; the last OUT "under" pixels is contended, wastes 4 cycles waiting for ULA
        WAIT_PIXEL_IN_RASTER_SCRIPT label, 24*11+8*scroll_x
        out (c), reg_with_color_b   ; border change #3
        out (c), reg_with_color_a   ; border change #4
        END_RASTER_SCRIPT_ENTREE label       ; rept (8-4)*3-1-scroll_x%3 ; 8 OUTs per border&retrace (96 cycles)
 endm
endm

border_line_lh_0 CHECKERS_BORDER_LINE border_line_lh_0, l, h, 0
border_line_lh_1 CHECKERS_BORDER_LINE border_line_lh_1, l, h, 1
border_line_lh_2 CHECKERS_BORDER_LINE border_line_lh_2, l, h, 2
border_line_hl_0 CHECKERS_BORDER_LINE border_line_hl_0, h, l, 0
border_line_hl_1 CHECKERS_BORDER_LINE border_line_hl_1, h, l, 1
border_line_hl_2 CHECKERS_BORDER_LINE border_line_hl_2, h, l, 2

screen_line_lh_0 CHECKERS_SCREEN_LINE screen_line_lh_0, l, h, 0
screen_line_lh_1 CHECKERS_SCREEN_LINE screen_line_lh_1, l, h, 1
screen_line_lh_2 CHECKERS_SCREEN_LINE screen_line_lh_2, l, h, 2
screen_line_hl_0 CHECKERS_SCREEN_LINE screen_line_hl_0, h, l, 0
screen_line_hl_1 CHECKERS_SCREEN_LINE screen_line_hl_1, h, l, 1
screen_line_hl_2 CHECKERS_SCREEN_LINE screen_line_hl_2, h, l, 2

stack   dw 0
border_pattern_a
        db COLOR_A
        db COLOR_A
        db COLOR_A
        db COLOR_B
        db COLOR_B
        db COLOR_B
        db 0
border_pattern_b
        db COLOR_B
        db COLOR_B
        db COLOR_B
        db COLOR_A
        db COLOR_A
        db COLOR_A
        db 0
attribute_pattern_a
        db COLOR_A << 3
        db COLOR_B << 3
        db COLOR_B << 3
        db COLOR_B << 3
        db COLOR_A << 3
        db COLOR_A << 3
        db 0
attribute_pattern_b
        db COLOR_B << 3
        db COLOR_A << 3
        db COLOR_A << 3
        db COLOR_A << 3
        db COLOR_B << 3
        db COLOR_B << 3
        db 0
raster_script
        dw raster_script_2
        dw raster_script_1
        dw raster_script_0
        dw 0
raster_script_0
        rept 1
                dw border_line_lh_0
        endm
        rept 23
                dw border_line_hl_0
        endm
        rept 4
        rept 24
                dw screen_line_lh_0
        endm
        rept 24
                dw screen_line_hl_0
        endm
        endm
        rept 23
                dw border_line_lh_0
        endm
        rept 1
                dw border_line_hl_0
        endm
        dw screen_loop
raster_script_1
        rept 1
                dw border_line_lh_1
        endm
        rept 23
                dw border_line_hl_1
        endm
        rept 4
        rept 24
                dw screen_line_lh_1
        endm
        rept 24
                dw screen_line_hl_1
        endm
        endm
        rept 23
                dw border_line_lh_1
        endm
        rept 1
                dw border_line_hl_1
        endm
        dw screen_loop
raster_script_2
        rept 1
                dw border_line_lh_2
        endm
        rept 23
                dw border_line_hl_2
        endm
        rept 4
        rept 24
                dw screen_line_lh_2
        endm
        rept 24
                dw screen_line_hl_2
        endm
        endm
        rept 23
                dw border_line_lh_2
        endm
        rept 1
                dw border_line_hl_2
        endm
        dw screen_loop

        end start               ; entry point for zmac and pasmo
