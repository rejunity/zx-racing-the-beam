; ZX48K interrupt mode 2
; zmac interrupt_mode2.asm -o interrupt_mode2.tap

; The code below installs empty interrupt handler
; and it is useful to measure and understand the exact timing of the interrupt!
; 
; NOTE: there is as an inherent 4T variability of the HALT instruction because
; HALT instruction is implmented in Z80 CPU as a busy wait loop that runs NOP.
; Interrupt occurs when /INT pin on Z80 is pulled low the external timer contained inside ULA.
; (See schematics: https://spectrumforeveryone.com/technical/zx-spectrum-pcb-schematics-layout/)
; Once /INT pin goes low CPU will first have to finish NOP it is currently running
; and since NOP is 4T it might take from 0 to 3T before CPU start processing interrup.
; Only after completing NOP instruction the CPU will start jumping to interrupt handler address.
;
; Jump to interrupt takes 19T plus 0..3T as discussed above.
; In other words CPU reaches im2_handler address 19/20/21/22T after the timer has occured.
;                                                ^^^^^^^^^^^^
;
; With the _shortest_ possible interrup handler just a single RET instruction,
; CPU will finish interrupt and return to the address following the HALT instruction
; 33T + 0..3T (33/34/35/36T) cycles after the ULA timer interrupt has occured.
;              ^^^^^^^^^^^^
; 
; With just EI, RETI interrupt handler CPU will finish HALT instruction
; 37T + 0..3T (37/38/39/40T) cycles after the ULA timer interrupt has occured.
;              ^^^^^^^^^^^^
;
; NOTE: A frame is (64+192+56)*224=69888 T states (3.5MHz/69888=50.08 Hz interrupt)

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
    rept $8080-$
        nop
    endm
                ; 552T / 49048T
_8080   halt    ; 37T
        ei      ;     (with the shortest interrupt: 33T)
_8081   halt    ; 38T
        ei      ;     (with the shortest interrupt: 34T)
_8082   halt    ; 39T
        ei      ;     (with the shortest interrupt: 35T)
_8083   halt    ; 40T
        ei      ;     (with the shortest interrupt: 36T)
_8084   halt    ; 37T
        ei      ;     (with the shortest interrupt: 33T)
_8085   halt    ; 38T
        ei      ;     (with the shortest interrupt: 34T)
_8086   halt    ; 39T
        ei      ;     (with the shortest interrupt: 35T)
_8087   halt    ; 40T
        ei      ;     (with the shortest interrupt: 36T)
        jp frame


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
        ;ei      ; 23/24/25/26T
        ;reti    ; 37/38/39/40T
        ret
im2_handler_end:                ; check handler does not overrun the vector table
        assert(im2_handler_end <= $FE00)

        org $FE00
interrupt_vector_table
        dc 257, high im2_handler

entry_point_____________________________________________________________________
        end start               ; entry point for zmac and pasmo
