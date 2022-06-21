; ZX48K checkers on the border
; zmac checkers.asm -o checkers.tap

; https://worldofspectrum.org/faq/reference/48kreference.htm
; 1) Each line takes exactly 224 T states = 128 T (screen) + 96 T (border&retrace)
; 2) Every half T state a pixel is written to the CRT, so if the ULA is reading bytes it does so each 4 T states (and then it reads two: a screen and an ATTR byte).
; 3) The border is 48 pixels wide at each side. A video screen line is therefore timed as follows:
;    128 T states of screen, 24 T states of right border, 48 T states of horizontal retrace and 24 T states of left border.
; 4) After an interrupt occurs, 64 line times (14336 T states; see below for exact timings) pass before the first byte of the screen (16384) is displayed. At least the last 48 of these are actual border-lines; the others may be either border or vertical retrace.
; 5) A frame is (64+192+56)*224=69888 T states (3.5MHz/69888=50.08 Hz interrupt)

;DEBUG   equ 0
PORCH   equ 64
PORT    equ $FE
BRIGHT  equ 0
COLOR_A equ (2+BRIGHT)
COLOR_B equ (6+BRIGHT)
PAUSE_N_FRAMES equ 1

        org $8000
start:
init____________________________________________________________________________
        ld (stack), sp
        call setup_interrupt_mode2

animate_________________________________________________________________________
animate_scroll_patterns:
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

keep_scroll_patterns:

render_frame____________________________________________________________________
        ld sp, (stack)
        ei
        halt            ; 39 cycles since the start of the frame
        adc hl, bc      ; 15 cycles, used here for cycle alignment on 4: 39+15=56
INTERRUPT_CYCLE_COUNT = 39+15
frame   di

        ld (stack), sp
 irp pattern, <attribute_pattern_a, attribute_pattern_b>
        ld sp, &pattern
        pop hl
        pop de
        pop bc
        exx
 endm

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

        ld a, (border_pattern_a)
        ld l, a
        ld a, (border_pattern_b)
        ld h, a
        xor a
        ld bc, PORT
        out (c),a

CONTENDED_CYCLE_COUNT = INTERRUPT_CYCLE_COUNT
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

WAIT_SCANLINE macro line, cycles_offset
        WAIT_CYCLES 224*(PORCH+line)+(cycles_offset)-CONTENDED_CYCLE_COUNT-(t($)-t(frame))+4
endm

WAIT_PIXEL macro x, cycles_to_output
        WAIT_CYCLES (x)/2-(cycles_to_output)-(((t($)-(t(frame)+CONTENDED_CYCLE_COUNT)))%224)
endm

NEXT_RASTER_SCRIPT_ENTREE macro
        dec de          ; 6 cycles, just to align the following "RET" on 4 cycles
        ret             ; 10 cycles
endm

START_RASTER_SCRIPT_FROM_SCANLINE macro raster_script_jump_table, scanline, cycles_offset
        ld sp, raster_script_jump_table
        WAIT_SCANLINE (scanline), ((cycles_offset)-16)
        NEXT_RASTER_SCRIPT_ENTREE
endm

CONTENDED_CYCLE_COUNT_AT_THE_BEGINNING_OF_THE_ENTREE = 0
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

ALTERNATE_BORDER_N_TIMES macro times, reg_with_color_a, reg_with_color_b
 rept times
        out (c), reg_with_color_a
        out (c), reg_with_color_b
 endm
endm

CHECKERS_BORDER_LINE macro reg_with_color_a, reg_with_color_b, scroll_x, ?this
?this:
BEGIN_RASTER_SCRIPT_ENTREE
        WAIT_PIXEL_IN_RASTER_SCRIPT ?this, -48+8*scroll_x
 ifdef DEBUG
        ; visualize the 1st and the last checker on the line
        ALTERNATE_BORDER_N_TIMES 1, 0, 0
        ALTERNATE_BORDER_N_TIMES 6, reg_with_color_a, reg_with_color_b
        ALTERNATE_BORDER_N_TIMES 1, 0, reg_with_color_b
 else
        ALTERNATE_BORDER_N_TIMES 8, reg_with_color_a, reg_with_color_b
 endif
END_RASTER_SCRIPT_ENTREE ?this
endm

CHECKERS_SCREEN_LINE macro reg_with_color_a, reg_with_color_b, scroll_x, ?this
?this:
BEGIN_RASTER_SCRIPT_ENTREE
        WAIT_PIXEL_IN_RASTER_SCRIPT ?this, -48+8*scroll_x
        out (c), reg_with_color_a       ; border change #1
        out (c), reg_with_color_b       ; border change #2

        ; color change "under" the pixels
        WAIT_PIXEL_IN_RASTER_SCRIPT ?this, 128
 ifdef DEBUG
        out (c), 0
 else
        out (c), reg_with_color_a
 endif

        CONTENDED_CYCLE_COUNT += 4      ; the last OUT "under" pixels is contended and
                                        ; wastes 4 cycles waiting for ULA
        WAIT_PIXEL_IN_RASTER_SCRIPT ?this, 24*11+8*scroll_x
        out (c), reg_with_color_b       ; border change #3
        out (c), reg_with_color_a       ; border change #4
END_RASTER_SCRIPT_ENTREE ?this
 endm
endm

start_raster_script_____________________________________________________________
        ld ix, (raster_script)
        START_RASTER_SCRIPT_FROM_SCANLINE ix, -24, -(24+12)

 irpc scroll_x, 012                     ; 3 scroll "positions"
                                        ; each step by 8 pixels
border_line_lh_&scroll_x: CHECKERS_BORDER_LINE l, h, scroll_x
border_line_hl_&scroll_x: CHECKERS_BORDER_LINE h, l, scroll_x
screen_line_lh_&scroll_x: CHECKERS_SCREEN_LINE l, h, scroll_x
screen_line_hl_&scroll_x: CHECKERS_SCREEN_LINE h, l, scroll_x

raster_script_&scroll_x:                ; defines: raster_script_0,
                                        ; raster_script_1,
                                        ; raster_script_2
        rept 1
                dw border_line_lh_&scroll_x
        endm
        rept 23
                dw border_line_hl_&scroll_x
        endm
        rept 4
        rept 24
                dw screen_line_lh_&scroll_x
        endm
        rept 24
                dw screen_line_hl_&scroll_x
        endm
        endm
        rept 23
                dw border_line_lh_&scroll_x
        endm
        rept 1
                dw border_line_hl_&scroll_x
        endm
        dw finish_raster_script
 endm

finish_raster_script:                   ; 62688T (~280 scanlines=64+192+24)
if 0
        ld a, (counter)                 ; 13T
        dec a                           ; 4T
        ld (counter), a                 ; 13T
        jnz align_main_loopA            ; 10T - 40T -> 60T
        ld a, PAUSE_N_FRAMES            ; 7T
        ld (counter), a                 ; 13T -> 60T
else
        ld hl, counter                  ; 10T
        dec (hl)                        ; 11T
        jnz align_main_loopB            ; 10T - (31T) -> 52T
        ld a, PAUSE_N_FRAMES            ; 7T
        ld a, PAUSE_N_FRAMES            ; 7T
        ld (hl), a                      ; 7T  -> 52T
endif
        jp animate_scroll_patterns

align_main_loopA                        ; 40T
        ld hl, counter                  ; 10T
        ld hl, counter                  ; 10T -> 60T
        jp keep_scroll_patterns

align_main_loopB                        ; -> 31T
        ld a, PAUSE_N_FRAMES            ; 7T
        ld a, PAUSE_N_FRAMES            ; 7T
        ld a, PAUSE_N_FRAMES            ; 7T -> 52T
        jp keep_scroll_patterns

data____________________________________________________________________________
stack   dw 0
counter db PAUSE_N_FRAMES
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
        db COLOR_B << 3
        db COLOR_B << 3
        db COLOR_B << 3
        db COLOR_A << 3
        db COLOR_A << 3
        db COLOR_A << 3
        db 0
attribute_pattern_b
        db COLOR_A << 3
        db COLOR_A << 3
        db COLOR_A << 3
        db COLOR_B << 3
        db COLOR_B << 3
        db COLOR_B << 3
        db 0
raster_script
        dw raster_script_2
        dw raster_script_1
        dw raster_script_0
        dw 0

interrupt_______________________________________________________________________
setup_interrupt_mode2:
        di
        ld a, high interrupt_vector_table
        ld i, a
        im 2
        ei
        ret

        org $FDFD
im2_handler:
        ei
        reti
im2_handler_end:
        assert(im2_handler_end <= $FE00)

        org $FE00
interrupt_vector_table
        dc 257, high im2_handler

entry_point_____________________________________________________________________
        end start               ; entry point for zmac and pasmo
