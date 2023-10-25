; ZX48K simple wait for TV beam to reach particular position
; zmac screen_timing.asm -o screen_timing.tap

; In this code we will change border color exactly 1 line above
; the first pixel in the top-left corner of the screen.
;
; Vertically ZX 48K frame consists of:
;  - 8   vertical sync scanlines
;  - 56  top border scanlines
;  - 192 pixel scanlines of the screen
;  - 56  bottom border scanlines;
; Each ZX 48K scanline is 224 T cycles (T states) and
; each T cycles is equal to TV beam horizontally passing 2 pixels.
;
; NOTE: ULA interrupt does NOT happen on the start of the scanline,
; but rather 16 T cycles later, directly above the first pixel. Handy!
;
; Screen organization of Spectrum 48K in T cycles,
; (*) marks the timing of ULA interrupts in relation to the screen:
; 
;            <------------------------ 224T ------------------------>    |
;            16->|<------------ 128T -----------><16><16><----48---->____v_
;   ^        ....*VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV______
;   |   ^    llllttttttttttttttttttttttttttttttttrrrrHHHH............    ^
;   |   |    llllttttttttttttttttttttttttttttttttrrrrHHHH............    |
;   |   |    llllttttttttttttttttttttttttttttttttrrrrHHHH............    8 scanlines of VSYNC
;   |   56   llllttttttttttttttttttttttttttttttttrrrrHHHH............     & vertical blanking
;   |   |    llllttttttttttttttttttttttttttttttttrrrrHHHH............
;   |   |    llllttttttttttttttttttttttttttttttttrrrrHHHH............   LEGEND:
;   |   v    llllttttttttttttttttttttttttttttttttrrrrHHHH............    * - ULA interrupt!
;   |   ^    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............    . - blanking / horizontal retrace
;   |   |    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............    V - VSync pulse & vertical retrace
;   |   |    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............    H - HSync pulse
;  312  |    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............    l - border on the (l)eft
;   |   |                                                                r - border on the (r)ight
;   |  192 scanlines            ...                                      t - border on the (t)op
;   |   |                                                                b - border on the (b)ottom
;   |   |    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............    X - pixel screen
;   |   |    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............
;   |   |    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............
;   |   v    llllXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXrrrrHHHH............
;   |   ^    llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............         The whole frame is:
;   |   |    llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............   (8+56+192+56)*224=69888 T states
;   |   |    llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............   (3.5MHz/69888=50.08 Hz interrupt)
;   |   56   llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............
;   |   |    llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............
;   |   |    llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............
;   v   v    llllbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrrrHHHH............
;            ....* next frame
;
; SEE: https://worldofspectrum.org/faq/reference/48kreference.htm#ZXSpectrum
;
; So to reach the scanline above the first pixel we need to wait
;    8 + 56 - 1 = 63 scanlines to pass after ULA interrupt.
; Therefore, we have to wait for 63 * 224T = 14112T cycles
;
; 1) First we install empty interrupt mode 2 handler which will take
;    37 + 0..3 T to get back to our code. See interrupt_mode2.asm for more info!
; 3) Immediately after HALT we SETT 37 to tell ZMAC exact number of T cycles for interrupt handler.
; 2) We align T cycles from odd 37 to 44 to divisible by 4 for simplicity
;    LD A,0 instruction takes 7 T cycles, 37 + 7 = 44T
; 3) We add enough NOP instructions to wait:
;    14112T - 44T (interrupt handler time /w alignment) - 20T (time takes to change the border color)
; 4) We use ZMAC's t($) to get T cycle count since the interrupt at a given adress.
;    $ - means current address
;
; BONUS: one way to think about timing is to measure instructions in pixels!
;    NOP                   4T cycles  =   8 pixels
;    PUSH HL              11T cycles  =  22 pixels
;    OUT                11/12T cycles =  24 pixels
;    LD (addr), HL        16T cycles  =  32 pixels


ULA     equ $FE         ; ULA port
BLUE    equ 1
WHITE   equ 7

LINE_T  equ 224         ; ZX Spectrum 48K scanline is 224 T cycles
NOP_T   equ 4           ; NOP takes 4T cycles

BORDER macro color      ; Helper macro to set BORDER color
        inc de          ;+  6T alignment of the whole BORDER macro on 4 T cycles
        ld a,color      ;+  7T cycles
        out (ULA),a     ;+ 11T cycles
                        ;-----------
endm                    ;= 24T cycles
BORDER_T equ 24 - 4     ; HYPOTHESIS: actual data is being sent on the 7th cycle of OUT, 4T cycles before OUT finishes

        org $8000
main____________________________________________________________________________
start:
        call setup_interrupt_mode2      ; install Mode 2 interrupt handler, im2_handler
                                        ; to handle ULA frame interrupt with minimal overhead

main_loop:
        halt            ; wait for ULA frame interrupt
                        ; our custom empty im2_handler executes in 37 T cycles
        sett 37         ; Set zmac assembler internal T state to 37 cycles
                        ; we have to specify T here explicitly because
                        ; zmac have no way to know how long interrupt has taken. 
        ld a, 0         ; Wait 7 cycles until 44 cycles to align for division by 4 (see NOP_T)
                        ; NOTE: see interrupt_mode2.asm for more info!

 rept (LINE_T*63 - BORDER_T - t($)) / NOP_T     ; t($) zmac assembler internal T state counter
        nop                                     ; t($) returns how many T cycles passed up until
 endm                                           ; the current instruction
        BORDER BLUE

        ; bonus, change border back exactly one line after
        ; the last pixel (bottom-right corner)
 rept (LINE_T*(64+192) + 128 - BORDER_T - t($)) / NOP_T
        nop
 endm
        BORDER WHITE

        jp main_loop

interrupt_______________________________________________________________________
setup_interrupt_mode2:
        di
        ld a, high interrupt_vector_table
        ld i, a
        im 2
        ei
        ret

        org $FDFD
im2_handler:    ; 19/20/21/22T
        ei      ; 23/24/25/26T
        reti    ; 37/38/39/40T
im2_handler_end:                ; check handler does not overrun the vector table
        assert(im2_handler_end <= $FE00)

        org $FE00
interrupt_vector_table
        dc 257, high im2_handler

entry_point_____________________________________________________________________
        end start               ; entry point for zmac and pasmo
