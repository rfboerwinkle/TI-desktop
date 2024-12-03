; OS Keyboard Routines
; Exposes routines for interfacing with the keyboard.

; Brief: Does all the things the kernel should do with keys.
; Note: Assumes the kernel memory page is loaded.
HandleKeys: ; 0EA9
  ; A = key
  call GetKey

  ; HL = flag byte address
  ld HL, $C000 + PANE_FLAG_AD

  ; if (A == 0) {
  ;   reset key pressed flag
  ;   return
  ; }
  cp $00
  jr NZ, _
  res 6, (HL)
  ret
_:

  ; if (key pressed flag)
  ;   return
  bit 6, (HL)
  ret NZ

  ; set key pressed flag

  set 6, (HL)

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
  sub $21
  ld HL, keyJmpArray
  ld B, $00
  ld C, A
  add HL, BC
  add HL, BC
  add HL, BC
  jp (HL)
keyJmpArray:
  jp key_21
  jp key_22
  jp key_23
  jp key_24
  jp key_25
  jp key_26
  jp key_27
  jp key_28
  jp key_29
  jp key_2A
  jp key_2B
  jp key_2C
  jp key_2D
  jp key_2E
  jp key_2F
  jp key_30
  jp key_31

; select left pane
key_21:
  ld HL, $C000 + PANE_FLAG_AD
  res 4, (HL)
  ret
key_22:
  ret
key_23:
  ret
key_24:
  ret

; select right pane
key_25:
  ld HL, $C000 + PANE_FLAG_AD
  set 4, (HL)
  ret

; start proc
key_26:
  ld A, ($C000 + KERNEL_PANE_AD)
  and %00001111
  ld B, A
  ld A, ($C000 + KERNEL_PANE_AD + $0001)
  and %00001111
  add A, B
  ld H, A
  call SpawnProcess
  jp key_30

; select proc
key_27:
  ld A, ($C000 + KERNEL_PANE_AD)
  and %00000111
  jr Z, nullPane
  ld C, A

  ld DE, PCB_SIZE
  ld B, A
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_
  ld H, (IX+$04)
  ld L, (IX+$03)

  ld A, (IX)
  cp $00
  ld A, C ; does not affect F
  jr Z, nullPane

  ld E, A
  ld IY, $C000 + PANE_FLAG_AD
  bit 4, (IY)

  jr Z, _
  ld A, ($C000 + PID_LEFT_PANE_AD)
  cp E
  jr Z, nullPane
  ld A, E
  jr normPane
_:
  ld A, ($C000 + PID_RIGHT_PANE_AD)
  cp E
  jr Z, nullPane
  ld A, E
  jr normPane

nullPane:
  ld A, $00
  ld HL, $C000 + PLACEHOLDER_PANE_AD

normPane:
  ld IY, $C000 + PANE_FLAG_AD
  bit 4, (IY)
  jr Z, _
  ld ($C000 + PID_RIGHT_PANE_AD), A
  ld C, $06
  jr ++_
_:
  ld ($C000 + PID_LEFT_PANE_AD), A
  ld C, $00
_:

  ld ($C000 + SP_AD), SP
  out ($05), A
  ld SP, ($C000 + SP_AD)
  call UpdatePane
  ld ($C000 + SP_AD), SP
  ld A, $00
  out ($05), A
  ld SP, ($C000 + SP_AD)
  jr key_30

; kill proc
key_28:
  ld A, ($C000 + KERNEL_PANE_AD)
  and %00000111
  ld C, A
  push BC
  ld HL, $C000 + KERNEL_PANE_AD
  ld (HL), $BF
  ld DE, $C000 + KERNEL_PANE_AD + $01
  ld BC, $0C
  ldir
  ld HL, $C000 + PANE_FLAG_AD
  ld A, (HL)
  and %11110000
  ld (HL), A
  pop BC
  jp KillProcess
key_29:
  ret

; move right
key_2A:
  ld HL, $C000 + PANE_FLAG_AD
  ld A, (HL)
  and %00001111
  inc A
  cp $0C
  jr NZ, _
  ld A, $0B
_:
  ld B, A
  ld A, (HL)
  and %11110000
  add A, B
  ld (HL), A
  ret

; alpha / numeric toggle
key_2B:
  ld HL, $C000 + PANE_FLAG_AD
  bit 5, (HL)
  jr Z, _
  res 5, (HL)
  ret
_:
  set 5, (HL)
  ret
key_2C:
  ret
key_2D:
  ret

; move left
key_2E:
  ld HL, $C000 + PANE_FLAG_AD
  ld A, (HL)
  and %00001111
  dec A
  cp $FF
  jr NZ, _
  ld A, $00
_:
  ld B, A
  ld A, (HL)
  and %11110000
  add A, B
  ld (HL), A
  ret
key_2F:
  ret

; clear
key_30:
  ld HL, $C000 + KERNEL_PANE_AD
  ld (HL), $BF
  ld DE, $C000 + KERNEL_PANE_AD + $01
  ld BC, $0C
  ldir
  ld HL, $C000 + PANE_FLAG_AD
  ld A, (HL)
  and %11110000
  ld (HL), A
  ret
key_31:
  ; A = PID to send to
  ld HL, $C000 + PANE_FLAG_AD
  bit 4, (HL)
  jr Z, _
  ld A, ($C000 + PID_RIGHT_PANE_AD)
  jr ++_
_:
  ld A, ($C000 + PID_LEFT_PANE_AD)
_:

  cp $00
  ret Z

  ; DE = input address
  ; clear input address
  ld DE, PCB_SIZE
  ld B, A
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_
  ld E, (IX+$01)
  ld D, (IX+$02)
  ld (IX+$01), $00
  ld (IX+$02), $00

  ; C = PID
  ; clobber A
  ; return if input address is $0000 (dead process / not waiting)
  ld C, A
  ld A, $00
  or E
  or D
  ret Z

  ; Copy data over
  ld A, C
  push BC
  out ($05), A
  ld A, $80
  out ($07), A
  ld BC, $0C
  ; Whooooo!!! I knew storing addresses in offsets would be handy :D
  ld HL, $8000 + KERNEL_PANE_AD
  ldir
  out ($05), A
  pop BC

  ; add PID to end of ready queue
  ld HL, $BFFF
_:
  inc HL
  ld B, (HL)
  inc B
  djnz -_
  ld (HL), C

  jr key_30


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
