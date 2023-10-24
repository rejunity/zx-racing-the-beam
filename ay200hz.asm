; ZX48K divide frame into 4 equal parts 50 * 4 = 200
; zmac ay200hz.asm -o ay200hz.tap


; Divide 64+192+56=312 into 4 separate equal parts 312/4=78 scanlines each
;  1) scanline 0, immediately after ULA interrupt
;  2) scanline 78  =  78-64= 14th screen scanline
;  3) scanline 156 = 156-64= 92th screen scanline
;  4) scanline 234 = 156-64=170th screen scanline
; We can also reduce number of "music" scanlines overlapping the screen
; for performance reasons with offset of 192-170 = 22

OFFSET  equ 0
;OFFSET  equ 22

UPDATE_AY macro
; TODO: implemnet AY music routine
endm

BORDER macro color
        ld a,color
        out ($FE),a
endm

WAIT_VBLANK macro
        ei
        halt            ; wait for ULA frame interrupt
                        ; our custom empty im2_handler executes in 37 T cycles
        sett 37         ; set zmac compiler internal T state to 37 cycles, WAIT_RASTER will use it
        ld a, 0         ; Wait 7 cycles until 44 cycles to aling for division by 4
        di
endm

WAIT_RASTER macro line
 rept (224*(64+line)-48-t($))/4 ; 224 T cycles per line on 48K
                                ; 48 T cycles to the left of the pixels, guaranteed to be not displayed on TV
                                ; 64 lines before we reach pixels
        nop ; 4T cycles
 endm
endm

        org $8000
start:
init____________________________________________________________________________
        call setup_interrupt_mode2

render_frame____________________________________________________________________
main_loop:
        WAIT_VBLANK
        if OFFSET > 0
                WAIT_RASTER -64+OFFSET
        endif
        UPDATE_AY
        BORDER 1
        WAIT_RASTER 14+OFFSET
        UPDATE_AY
        BORDER 2
        WAIT_RASTER 92+OFFSET
        UPDATE_AY
        BORDER 6
        WAIT_RASTER 170+OFFSET
        UPDATE_AY
        BORDER 4

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
w