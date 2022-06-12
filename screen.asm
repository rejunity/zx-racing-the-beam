; ZX48K fill screen with pixels, data interleaved with code
; too slow to fill all 196 lines due to VRAM contention:
; 1) use more registers and move pushes into the border
; 2) even without contention the line is 1.5 times slower than raster line, would have to reuse the pixel data per line to make it fast enough

; To compile with zmac or pasmo:
; a) zmac screen.asm -o screen-zmac.tap
; b) pasmo --tapbas screen.asm screen-pasmo.tap

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
        
        ld b, 128

inner_loop
        ld hl, 0xaaaa
        push hl
        ld hl, 0x0ff0
        push hl
        ld hl, 0x7777
        push hl
        ld hl, 0x0137
        push hl
        ld hl, 0xf731
        push hl
        ld hl, 0x7777
        push hl
        ld hl, 0x0ff0
        push hl
        ld hl, 0xaaaa
        push hl

        ld hl, 0xffff
        push hl
        ld hl, 0x7777
        push hl
        ld hl, 0x0137
        push hl        
        ld hl, 0x0000
        push hl
        ld hl, 0x0000
        push hl
        ld hl, 0xf731
        push hl
        ld hl, 0x7777
        push hl
        ld hl, 0xffff
        push hl

        djnz    inner_loop

        inc hl
        ld (cnt),hl
        ex de,hl
        ld sp,hl
        
        ld a,0
        out (254),a
        
        jp screen_loop
        
cnt     dw 0x0030

        end screen_loop         ; entry point for zmac and pasmo
