; ZX clear with stack
; Valdemar version
        org  0x5ccb
        jmp  0x8000
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
        
cnt     dw 0x0030


        org 0xff57
        defb 00h


