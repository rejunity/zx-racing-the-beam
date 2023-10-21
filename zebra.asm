; ZX48K interrupt mode 2
; zmac zebra.asm -o zebra.tap

PORCH   equ 64 ; number of scanlines between interrupt and the top of the screen
ULA     equ $FE ; ULA port

BORDER macro color
        ld a,color
        out (ULA),a
endm

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


screen_loop:
render_frame____________________________________________________________________

        ld sp,(stack)
        ei
        ;WAIT_ODD_CYCLES
        halt            ; 37 cycles passes since the start of the frame,
                        ; our custom empty im2_handler executes and
                        ; CPU finishes HALT instruction
_37t    sett 37         ; set T state to 37 cycles
        di
        ld (stack),sp
        
WAIT_RASTER macro line
 rept (224*(PORCH+line)-t($)-t(_37t))/4
        nop
 endm
endm

        BORDER 6
        WAIT_RASTER -4
        BORDER 1
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

porch___________________________________________________________________________
pixels__________________________________________________________________________
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
