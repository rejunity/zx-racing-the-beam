; ZX fill with stack, preshift
        org  0x5ccb
        jmp  0x8000
        org  0x8000
        
screen_loop
        ei
        halt
        
        di
        ld a, 2
        out (254), a
        
        ld hl, 0
        add hl, sp
        ld (stack),hl
        ld hl, 0x4000+6144
        ld sp, hl

        ld a,(src)
        rla
        ld ix,src
        rl (ix+15)
        rl (ix+14)
        rl (ix+13)
        rl (ix+12)
        rl (ix+11)
        rl (ix+10)
        rl (ix+9)
        rl (ix+8)
        rl (ix+7)
        rl (ix+6)
        rl (ix+5)
        rl (ix+4)
        rl (ix+3)
        rl (ix+2)
        rl (ix+1)
        rl (ix+0)

        ;exx
        ld bc, (src+8)
        ld de, (src+6)
        ld hl, (src+4)
        ld ix, (src+2)
        ld iy, (src+0)
        exx
        ld bc, (src+14)
        ld de, (src+12)
        ld hl, (src+10)
        push hl
        pop af

        ld a, 1
        out (254), a
        
        ld a,196

inner_loop
        push bc
        push de
        push hl
        exx
        push bc
        push de
        push hl
        push ix
        push iy
        exx

        push bc
        push de
        push hl
        exx
        push bc
        push de
        push hl
        push ix
        push iy
        exx

        dec a
        jp nz, inner_loop
        
        ld hl,(stack)
        ld sp,hl
        
        ld a,0
        out (254),a
        
        jp screen_loop
        
src     dw 0xaaaa
        dw 0x0ff0 
        dw 0x7777
        dw 0x0137
        
        dw 0xf731
        dw 0x0137
        dw 0x7777
        dw 0x0ff0
        
        dw 0xaaaa
        dw 0x0000
        dw 0x0000
        dw 0x0000

stack   dw 0

        org 0xff57
        defb 00h

