; ZX48K clear with stack (Valdemar version)
; zasm clear.zasm.asm clear.tap

#target tap

; sync bytes:
headerflag:     equ 0
dataflag:       equ 0xff

; some Basic tokens:
tCLEAR      equ     $FD             ; token CLEAR
tLOAD       equ     $EF             ; token LOAD
tCODE       equ     $AF             ; token CODE
tPRINT      equ     $F5             ; token PRINT
tRANDOMIZE  equ     $F9             ; token RANDOMIZE
tUSR        equ     $C0             ; token USR

code_start  equ 0x8000

; ---------------------------------------------------
;       a Basic Loader:
; ---------------------------------------------------

#code PROG_HEADER,0,17,headerflag
        defb    0                       ; Indicates a Basic program
        defb    "mloader   "            ; the block name, 10 bytes long
        defw    variables_end-0         ; length of block = length of basic program plus variables
        defw    10                      ; line number for auto-start, 0x8000 if none
        defw    program_end-0           ; length of the basic program without variables


#code PROG_DATA,0,*,dataflag

        ; ZX Spectrum Basic tokens

; 10 CLEAR 32767
        defb    0,10                    ; line number
        defb    end10-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLEAR                  ; token CLEAR
        defm    "32767",$0e0000ff7f00   ; number 32767, ascii & internal format
end10:  defb    $0d                     ; line end marker

; 20 LOAD "" CODE 32768
        defb    0,20                    ; line number
        defb    end20-($+1)             ; line length
        defb    0                       ; statement number
        defb    tLOAD,'"','"',tCODE     ; token LOAD, 2 quotes, token CODE
        defm    "32768",$0e0000008000   ; number 32768, ascii & internal format
end20:  defb    $0d                     ; line end marker

; 30 RANDOMIZE USR 32768
        defb    0,30                    ; line number
        defb    end30-($+1)             ; line length
        defb    0                       ; statement number
        defb    tRANDOMIZE,tUSR         ; token RANDOMIZE, token USR
        defm    "32768",$0e0000008000   ; number 32768, ascii & internal format
end30:  defb    $0d                     ; line end marker

program_end:

        ; ZX Spectrum Basic variables

variables_end:


; ---------------------------------------------------
;       a machine code block:
; ---------------------------------------------------

#code CODE_HEADER,0,17,headerflag
        defb    3                       ; Indicates binary data
        defb    "mcode     "            ; the block name, 10 bytes long
        defw    code_end-code_start     ; length of data block which follows
        defw    code_start              ; default location for the data
        defw    0                       ; unused

#code CODE_DATA, code_start,*,dataflag

screen_loop:
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

inner_loop:
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

code_end:
