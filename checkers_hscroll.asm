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
BRIGHT  equ 0 ; 8 for bright
COLOR_A equ (2+BRIGHT)
COLOR_B equ (6+BRIGHT)
PAUSE_N_FRAMES equ 2

PORCH   equ 64
PORT    equ $FE

ALIGN_WAIT_INSTRUCTION macro odd
 ; TODO: opption for clobbering flags, but shorter instructions
 ;        ld a, i         ; waste 9T, alters flags!
 ;        dec de          ; waste 6T, alters flags!
 if &odd==3 \ ld a, (0)         ; waste 13T,    odd(3)+13=16%4=0
 endif
 if &odd==2 \ jp $+3            ; waste 10T,    odd(2)+10=12%4=0
 endif
 if &odd==1 \ ld a, 1           ; waste 7T,     odd(1)+7=8%4=0
 endif
endm

WAIT_ODD_CYCLES macro extra_cycles
 if nul &extra_cycles
        ALIGN_WAIT_INSTRUCTION t($)%4
        assert t($)%4==0
 else
        ALIGN_WAIT_INSTRUCTION (t($)+(extra_cycles))%4
        assert (t($)+(extra_cycles))%4==0
 endif
endm

WAIT_CYCLES macro cycles
 assert (cycles >= 4 || cycles == 0)
 tstate_after_wait = t($)+(cycles)
        ALIGN_WAIT_INSTRUCTION 4-(cycles)%4

 cycles_left_to_wait = tstate_after_wait-t($)
 assert cycles_left_to_wait>=0
 assert cycles_left_to_wait%4==0
 rept cycles_left_to_wait/4
        nop
 endm
 assert t($)==tstate_after_wait
endm

        org $8000
start:
init____________________________________________________________________________
        call setup_interrupt_mode2
        halt
        ld (stack), sp
        WAIT_ODD_CYCLES         ; assumes that setup_interrupt_mode2
                                ; is 4 cycles aligned

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
        WAIT_ODD_CYCLES

keep_scroll_patterns:
render_frame____________________________________________________________________
        ld sp, (stack)
        ei
        WAIT_ODD_CYCLES
        halt            ; 37 cycles passes since the start of the frame,
                        ; our custom empty im2_handler executes and
                        ; CPU finishes HALT instruction
        sett 37         ; set T state to 37 cycles
        di

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

CONTENDED_CYCLE_COUNT = 0
WAIT_FOR_SCANLINE macro line, pixel_x, cycles_to_output
        WAIT_CYCLES 224*(PORCH+line)+(pixel_x)/2-(cycles_to_output)-CONTENDED_CYCLE_COUNT-t($)+4
endm

WAIT_FOR_PIXEL macro x, cycles_to_output
        WAIT_CYCLES (x)/2-(cycles_to_output)-(((t($)-CONTENDED_CYCLE_COUNT))%224)
endm

NEXT_RASTER_SCRIPT_ENTREE macro
        dec de          ; 6 cycles, just to align the following "RET" on 4 cycles
        ret             ; 10 cycles
endm

START_RASTER_SCRIPT_FROM_SCANLINE macro raster_script_jump_table, scanline, pixel_x
        ld sp, raster_script_jump_table
        WAIT_FOR_SCANLINE (scanline), pixel_x, 16
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

WAIT_FOR_PIXEL_IN_RASTER_SCRIPT macro label, x
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
        WAIT_FOR_PIXEL_IN_RASTER_SCRIPT ?this, -48+8*scroll_x
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
        WAIT_FOR_PIXEL_IN_RASTER_SCRIPT ?this, -48+8*scroll_x
        out (c), reg_with_color_a       ; border change #1
        out (c), reg_with_color_b       ; border change #2

        ; color change "under" the pixels
        WAIT_FOR_PIXEL_IN_RASTER_SCRIPT ?this, 128
 ifdef DEBUG
        out (c), 0
 else
        out (c), reg_with_color_a
 endif

        CONTENDED_CYCLE_COUNT += 4      ; the last OUT "under" pixels is contended and
                                        ; wastes 4 cycles waiting for ULA
        WAIT_FOR_PIXEL_IN_RASTER_SCRIPT ?this, 24*11+8*scroll_x
        out (c), reg_with_color_b       ; border change #3
        out (c), reg_with_color_a       ; border change #4
END_RASTER_SCRIPT_ENTREE ?this
 endm
endm

start_raster_script_____________________________________________________________
        ld ix, (raster_script)
        START_RASTER_SCRIPT_FROM_SCANLINE ix, -24, -(48+24)

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

finish_raster_script:                   ; 62688T = 280 scanlines (64+192+24)
                                        ;         -32T raster offset
        sett 62688

if 1
        ld hl, counter
        dec (hl)
        WAIT_ODD_CYCLES 10              ; followed by JNZ, additional 10T
        jnz keep_scroll_patterns
        ld a, PAUSE_N_FRAMES
        ld (hl), a
        WAIT_ODD_CYCLES 10              ; followed by JP, additional 10T
        jp animate_scroll_patterns
else
        ld hl, counter
        dec (hl)
        jnz continue \ _continue:
        ld a, PAUSE_N_FRAMES
        ld (hl), a
        WAIT_ODD_CYCLES 10              ; followed by JP, additional 10T
        jp animate_scroll_patterns
continue: sett t(_continue)             ; restart T state counting from the
                                        ; origin of the incoming jump
        WAIT_ODD_CYCLES 10
        jp keep_scroll_patterns         ; followed by JP, additional 10T

endif


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
        WAIT_ODD_CYCLES 10      ; followed by uncondintional RET, additional 10T
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
