; ZX48K simple wait for raster demonstration
; zmac raster.asm -o raster.tap

; In this code we use NOPs to wait particular number of cycles
; in order to reach particular scanline (raster),
; counting from the ULA frame interrupt.
;
; First we install empty interrupt mode 2 handler and
; measure that it takes 37+0..3T to get back to our code
; after interrup has occured (see label __37t).
;
; Next we insert NOPs to busywait till beam reaches certain raster.
; 1) Each line takes exactly 224 T states = 128 T (screen) + 96 T (border&retrace)
;    -  24 T states of left border,
;    - 128 T states of screen,
;    -  24 T states of right border,
;    -  48 T states of horizontal retrace.
; 2) After an interrupt occurs, 64 lines pass before the first byte of the screen is displayed.
; 3) A frame is (64+192+56)*224=69888 T states (3.5MHz/69888=50.08 Hz interrupt)

PORCH   equ 64 ; number of scanlines between interrupt and the top of the screen
ULA     equ $FE ; ULA port

BORDER macro color
        ld a,color
        out (ULA),a
endm

WAIT_RASTER macro line
 rept (224*(PORCH+line)-t($)-t(__37t))/4 ; 224T cycles per line on 48K
        nop ; 4T cycles
 endm
endm

;@TODO: WAIT_ODD_CYCLES macro

        org $8000
start:
init____________________________________________________________________________
        call setup_interrupt_mode2
        xor a
frame   
        ld bc, $FE
        out (c),a
        inc a
        ei
        ;WAIT_ODD_CYCLES

screen_loop:
render_frame____________________________________________________________________

        ld sp,(stack)
        ei
        ;WAIT_ODD_CYCLES
        halt            ; 37 cycles passes since the start of the frame,
                        ; our custom empty im2_handler executes and
                        ; CPU finishes HALT instruction
__37t:  sett 37         ; set zmac compiler internal T state to 37 cycles, WAIT_RASTER will use it
        di
        ld (stack),sp

porch___________________________________________________________________________        
        BORDER 6
        WAIT_RASTER -4
        BORDER 1
pixels__________________________________________________________________________
        WAIT_RASTER 8
        BORDER 2
        WAIT_RASTER 12
        BORDER 7
        WAIT_RASTER 24
        BORDER 1
        WAIT_RASTER 36
        BORDER 2
        WAIT_RASTER 40
        BORDER 7
        WAIT_RASTER 52
        BORDER 0

        jp screen_loop
        stack   dw 0

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
