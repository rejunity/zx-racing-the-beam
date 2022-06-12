; ZX48K clear with stack (Valdemar version)

; To compile with zmac or pasmo:
; a) zmac clear.asm -o clear-zmac.tap
; b) pasmo --tapbas clear.asm clear-pasmo.tap

        org  0x8000

screen_loop
        ei
        halt
        
        ld a, 2
        out (254), a
        
        ld hl, 0
        add hl, sp
        ex de, hl
        ld hl, 0x4000+6144
        ld sp, hl
        ld hl, (cnt)
        
        ld b, 196

inner_loop
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl

        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl
        push hl

        djnz    inner_loop

        inc hl
        ld (cnt),hl
        ex de,hl
        ld sp,hl
        
        ld a,0
        out (254),a
        
        jp screen_loop


cnt     dw 0x0000

        end screen_loop         ; entry point for zmac and pasmo
