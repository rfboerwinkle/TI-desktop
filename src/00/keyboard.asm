; OS Keyboard Routines
; Exposes routines for interfacing with the keyboard.

; Brief: Does all the things the kernel should do with keys.
; Note: Assumes the kernel memory page is loaded.
HandleKeys:
  ; A = key
  ; if (A == 0) return
  call GetKey
  cp $00
  ret Z

  ; if (A > $20) jr notText
  cp $21
  jp P, notText

text:
  ; HL = scan_to_char + A*2
  ; if (alpha mode) HL++
  ; B = (HL) = char
  ; A = pane flags
  dec A
  ld B, $00
  ld C, A
  ld HL, scan_to_char
  add HL, BC
  add HL, BC
  ld A, ($C000 + PANE_FLAG_AD)
  bit 5, A
  jr NZ, _
  inc HL
_:
  ld B, (HL)

  ; HL = address to write char to
  ; char is written
  ; A is incremented, cliped to $0B
  and %00001111
  ld D, $00
  ld E, A
  ld HL, $C000 + KERNEL_PANE_AD
  add HL, DE
  ld (HL), B
  inc A
  cp $0C
  jp M, _
  ld A, $0B
_:

  ; write the new index back to the pane flags
  ld B, A
  ld A, ($C000 + PANE_FLAG_AD)
  and %11110000
  add A, B
  ld ($C000 + PANE_FLAG_AD), A

  call UpdateKernelPane
  ret

notText:
  sub $20
  ld HL, keyJmpArray
  ld B, $00
  ld C, A
  add HL, BC
  add HL, BC
keyJmpArray:
  jr key_21
  jr key_22
  jr key_23
  jr key_24
  jr key_25
  jr key_26
  jr key_27
  jr key_28
  jr key_29
  jr key_2A
  jr key_2B
  jr key_2C
  jr key_2D
  jr key_2E
  jr key_2F
  jr key_30
  jr key_31


key_21:
  ret
key_22:
  ret
key_23:
  ret
key_24:
  ret
key_25:
  ret
key_26:
  ret
key_27:
  ret
key_28:
  ret
key_29:
  ret
key_2A:
  ret
key_2B:
  ret
key_2C:
  ret
key_2D:
  ret
key_2E:
  ret
key_2F:
  ret
key_30:
  ret
key_31:
  ret

; Brief: Gets the key being pressed
; Output: A = keycode
GetKey:
gs_GetK2:
  ld b, 7
gs_GetK_loop:
  ld a, 7
  sub b
  ld hl, gs_keygroups
  ld d, 0 \ ld e, a
  add hl, de
  ld a, (hl)
  ld c, a

  ld a,0ffh
  out (1),a
  ld a,c
  out (1),a
  nop \ nop \ nop \ nop
  in a, (1)

  ld de,0
  cp 254 \ jr z, gs_GetK_254
  cp 253 \ jr z, gs_GetK_253
  cp 251 \ jr z, gs_GetK_251
  cp 247 \ jr z, gs_GetK_247
  cp 239 \ jr z, gs_GetK_239
  cp 223 \ jr z, gs_GetK_223
  cp 191 \ jr z, gs_GetK_191
  cp 127 \ jr z, gs_GetK_127

gs_GetK_loopend:
  djnz gs_GetK_loop

  xor a
  exx
  ld b, a
  exx
  jr gs_GetK_end
gs_GetK_127:
  inc e
gs_GetK_191:
  inc e
gs_GetK_223:
  inc e
gs_GetK_239:
  inc e
gs_GetK_247:
  inc e
gs_GetK_251:
  inc e
gs_GetK_253:
  inc e
gs_GetK_254:
  push de
  ld a, 7
  sub b
  add a, a \ add a, a \ add a, a
  ld d, 0 \ ld e, a
  ld hl, gs_keygroup1
  add hl, de
  pop de
  add hl, de
  ld a, (hl)

  ld d, a
  exx
  ld a, b
  exx
  cp d \ jr z, gs_GetK_end
  ld a, d
  exx
  ld b, a
  exx

gs_GetK_end:
  ret

gs_keygroups:
  .db $FE, $FD, $FB, $F7, $EF, $DF, $BF
gs_keygroup1:
  ;   DOWN  LEFT  RIGHT UP
  .db $2F,  $2E,  $2A,  $29,  $00,  $00,  $00,  $00
gs_keygroup2:
  ;   ENTER +     -     *     /     ^     CLEAR
  .db $31,  $1D,  $18,  $13,  $0E,  $09,  $30,  $00
gs_keygroup3:
  ;   (-)   3     6     9     )     TAN   VARS
  .db $20,  $1C,  $17,  $12,  $0D,  $08,  $04,  $00
gs_keygroup4:
  ;   .     2     5     8     (     COS   PRGM  STAT
  .db $1F,  $1B,  $16,  $11,  $0C,  $07,  $03,  $2D
gs_keygroup5:
  ;   0     1     4     7     ,     SIN   APPS  XT0N
  .db $1E,  $1A,  $15,  $10,  $0B,  $06,  $02,  $2C
gs_keygroup6:
  ;         STO   LN    LOG   X^2   X^-1  MATH  ALPHA
  .db $00,  $19,  $14,  $0F,  $0A,  $05,  $01,  $2B
gs_keygroup7:
  ;   GRAPH TRACE ZOOM  WIND  Y=    2ND   MODE  DEL
  .db $25,  $24,  $23,  $22,  $21,  $26,  $27,  $28

; These are stored as numeric, then alpha
scan_to_char:
  ;   MATH      APPS      PRGM      VARS      X^-1      SIN
  .db $B7, $8A, $B8, $8B, $B5, $8C, $AE, $BF, $BA, $8D, $B9, $8E
  ;   COS       TAN       ^         X^2       ,         (
  .db $B1, $8F, $B2, $90, $AD, $91, $BB, $92, $B6, $93, $AF, $94
  ;   )         /         LOG       7         8         9
  .db $B0, $95, $A8, $96, $BC, $97, $87, $98, $88, $99, $89, $9A
  ;   *         LN        4         5         6         -
  .db $A7, $9B, $BD, $9C, $84, $9D, $85, $9E, $86, $9F, $A5, $A0
  ;   STO       1         2         3         +         0
  .db $BE, $A1, $81, $A2, $82, $A3, $83, $B3, $A6, $AC, $80, $B4
  ;   .         (-)
  .db $A9, $AA, $A4, $AB
