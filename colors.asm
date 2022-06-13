; ZX48K multicolor 64x48
; zmac colors.asm -o colors.tap


PORCH   equ 64-3

        org  0x8000

start
init_______________________________
        ld bc,$0018
        ld a,11110000b
        ld hl,$4000
init_a
        ld (hl),a
        inc hl
        djnz init_a
        dec c
        jp nz, init_a
      
        ld bc,$0003
        ld a,$70
init_b
        ld (hl),a
        inc hl
        djnz init_b
        dec c
        jp nz, init_b

screen_loop

        ld sp,(stack)
        ei
        halt
x       di
        ld (stack),sp
        
        ld hl,$0123
        ld de,$4444

porch_____________________________
BORDER macro color
        ld a,color
        out (254),a
endm

WAIT_RASTER macro line
 rept (224*(PORCH+line)-96-t($)-t(x))/4
        nop
 endm
endm

        BORDER 1
        WAIT_RASTER -4
        BORDER 2

pixels____________________________
LINEZ macro
 rept 16
        push hl
        add hl,de
 endm
endm

LINE macro attr_offset, line
        ld sp,$5800+attr_offset
        WAIT_RASTER line
        LINEZ
endm

        ld sp,$5800+32
        LINEZ        
        LINE 32*1, 4*1

        LINE 32*2, 4*2
        LINE 32*2, 4*3

        LINE 32*3, 4*4
        LINE 32*3, 4*5

        LINE 32*4, 4*6
        LINE 32*4, 4*7

        LINE 32*5, 4*8
        LINE 32*5, 4*9

        LINE 32*6, 4*10
        LINE 32*6, 4*11

        LINE 32*7, 4*12
        LINE 32*7, 4*13

        LINE 32*8, 4*14
        LINE 32*8, 4*15

        LINE 32*9, 4*16
        LINE 32*9, 4*17

        LINE 32*10, 4*18
        LINE 32*10, 4*19

        LINE 32*11, 4*20
        LINE 32*11, 4*21

        LINE 32*12, 4*22
        LINE 32*12, 4*23

        LINE 32*13, 4*24
        LINE 32*13, 4*25

        LINE 32*14, 4*26
        LINE 32*14, 4*27

        LINE 32*15, 4*28
        LINE 32*15, 4*29


        ld a,3
        out (254),a

        jp screen_loop
        
data    dw 0x8880
stack   dw 0

        end start               ; entry point for zmac and pasmo
