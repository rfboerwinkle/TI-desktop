; OS Display Routines
; Provides routines for manipulating a buffer, as well as the screen

; Brief: updates the LCD based on the graphical delta buffer
UpdateLCD:
  ; D and E will by X and Y
  ld D, $00
  ld E, $00

  ; IX = start of graphical buffer
  ld IX, $0022
  ; IY = start of graphical delta buffer
  ld IY, $0322

  ; L is 1 if the Y position needs to be set, 0 otherwise
  ld L, $01

  ;
columnLoop:
  ; C is temp Y coordinate
  ld C, E
  ; H = delta byte
  ld H, (IY)
byteLoop:
  ; shift H right and update screen based on carry bit
  ld A, $00
  cp H
  jr Z emptyByte
  sra H
  jr NC, _
  ld A, $00
  cp L
  jr
  ; write byte at C
  ld L, $00
  jr +_
_:
  ld L, $01
_:
  inc C
  jr NZ byteLoop

emptyByte:
  ld L, $01
lastBitSet:
  ; E = E + $08
  ld A, E
  add $08
  ld E, A

; Clears an LCD buffer
; Input: IY: Buffer
ClearBuffer:
  push hl
  push de
  push bc
    push iy \ pop hl
    ld (hl), 0
    ld d, h
    ld e, l
    inc de
    ld bc, 767
    ldir
  pop bc
  pop de
  pop hl
  ret

; Brief: Copy the buffer to the screen, guaranteed
; Input: IY = address of the buffer
BufferToLCD:
  ld A, I
  push AF
  ; di is only required if an interrupt will alter the lcd.
  di
  push IY
  pop HL
  ld C, $10
  ld A, $80
setRow:
  in F, (C)
  jp m, setRow
  out ($10), A
  ld DE, $000C
  ld A, $20
col:
  in F, (C)
  jp m, col
  out ($10), A
  push AF
  ld B, 64
row:
  ld A, (HL)
rowWait:
  in F, (C)
  jp m, rowWait
  out ($11), A
  add HL, DE
  djnz row
  pop AF
  dec H
  dec H
  dec H
  inc HL
  inc A
  cp $2C
  jp nz, col
  pop AF

  jp po, _
  ei
_:

  ret

LCDDelay:
  push af

_:
  in a, ($10)
  rla
  jr c, -_

  pop af
  ret

; brief: utility for pixel manipulation
; input: a -> x coord, l -> y coord, IY -> graph buffer
; output: hl -> address in graph buffer, a -> pixel mask
; destroys: b, de
GetPixel:
  ld h, 0
  ld d, h
  ld e, l

  add hl, hl
  add hl, de
  add hl, hl
  add hl, hl

  ld e, a
  srl e
  srl e
  srl e
  add hl, de

  push iy \ pop de
  add hl, de

  and 7
  ld b, a
  ld a, $80
  ret z

  rrca
  djnz $-1

  ret

; Brief: set (darkens) a pixel in the graph buffer
; Input: a -> x coord, l -> y coord
; Output: none
SetPixel:
  push hl
  push de
  push af
  push bc
    call GetPixel
    or (hl)
    ld (hl), a
  pop bc
  pop af
  pop de
  pop hl
  ret

; Brief: reset (lighten) a pixel in the graph buffer
; Input: a -> x coord, l -> y coord
; Output: none
; Destroys: a, b, de, hl
ResetPixel:
  push hl
  push de
  push af
  push bc
    call GetPixel
    cpl
    and (hl)
    ld (hl), a
  pop bc
  pop af
  pop de
  pop hl
  ret

; Brief: flip (invert) a pixel in the graph buffer
; Input: a -> x coord, l -> y coord
; Output: none
; Destroys: a, b, de, hl
InvertPixel:
  push hl
  push de
  push af
  push bc
    call GetPixel
    xor (hl)
    ld (hl), a
  pop bc
  pop af
  pop de
  pop hl
  ret

; Brief: Fast line routine, only sets pixels
; Input: (d, e), (h, l) = (x1, y1), (x2, y2)
;        IY = buffer
; Notes: NO clipping
; Credit: James Montelongo
DrawLineOR:
  push hl
  push de
  push bc
  push af
  push ix
  push iy
    call _DrawLine
  pop iy
  pop ix
  pop af
  pop bc
  pop de
  pop hl
  ret

_DrawLine:
  ld a, h
  cp d
  jp nc, noswapx
  ex de, hl
noswapx:

  ld a, h
  sub d
  jp nc, posx
  neg
posx:
  ld b, a
  ld a, l
  sub e
  jp nc, posy
  neg
posy:
  ld c, a
  ld a, l
  ld hl, -12
  cp e
  jp c, lineup
  ld hl, 12
lineup:
  ld ix, xbit
  ld a, b
  cp c
  jp nc, xline
  ld b, c
  ld c, a
  ld ix, ybit
xline:
  push hl
  ld a, d
  ld d, 0
  ld h, d
  sla e
  sla e
  ld l, e
  add hl, de
  add hl, de
  ld e, a
  and %00000111
  srl e
  srl e
  srl e
  add hl, de
  push iy \ pop de
  ;ld de, gbuf
  add hl, de
  add a, a
  ld e, a
  ld d, 0
  add ix, de
  ld e, (ix)
  ld d, (ix+1)
  push hl
  pop ix
  ex de, hl
  pop de
  push hl
  ld h, b
  ld l, c
  ld a, h
  srl a
  inc b
  ret

xbit:
 .dw DrawX0, DrawX1, DrawX2, DrawX3
 .dw DrawX4, DrawX5, DrawX6, DrawX7
ybit:
 .dw DrawY0, DrawY1, DrawY2, DrawY3
 .dw DrawY4, DrawY5, DrawY6, DrawY7

DrawX0:
  set 7, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX1
  ret
DrawX1:
  set 6, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX2
  ret
DrawX2:
  set 5, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX3
  ret
DrawX3:
  set 4, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX4
  ret
DrawX4:
  set 3, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX5
  ret
DrawX5:
  set 2, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX6
  ret
DrawX6:
  set 1, (ix)
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX7
  ret
DrawX7:
  set 0, (ix)
  inc ix
  add a, c
  cp h
  jp c, $+3+2+1
  add ix, de
  sub h
  djnz DrawX0
  ret

DrawY0_:
  inc ix
  sub h
  dec b
  ret z
DrawY0:
  set 7, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY1_
  djnz DrawY0
  ret
DrawY1_:
  sub h
  dec b
  ret z
DrawY1:
  set 6, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY2_
  djnz DrawY1
  ret
DrawY2_:
  sub h
  dec b
  ret z
DrawY2:
  set 5, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY3_
  djnz DrawY2
  ret
DrawY3_:
  sub h
  dec b
  ret z
DrawY3:
  set 4, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY4_
  djnz DrawY3
  ret
DrawY4_:
  sub h
  dec b
  ret z
DrawY4:
  set 3, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY5_
  djnz DrawY4
  ret
DrawY5_:
  sub h
  dec b
  ret z
DrawY5:
  set 2, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY6_
  djnz DrawY5
  ret
DrawY6_:
  sub h
  dec b
  ret z
DrawY6:
  set 1, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY7_
  djnz DrawY6
  ret
DrawY7_:
  sub h
  dec b
  ret z
DrawY7:
  set 0, (ix)
  add ix, de
  add a, l
  cp h
  jp nc, DrawY0_
  djnz DrawY7
  ret

; ====SPRITE ROUTINES====

; D = xpos
; E = ypos
; B = height
; HL = image address
; IY = buffer address
PutSpriteXOR:
  push af
  push bc
  push hl
  push de
  push ix
    push hl \ pop ix
    call _ClipSprXOR
  pop ix
  pop de
  pop hl
  pop bc
  pop af
  ret

_ClipSprXOR:
; Start by doing vertical clipping
  ld A, %11111111     ; Reset clipping mask
  ld (CLIP_MASK), A
  ld A, E             ; If ypos is negative
  or A                ; try clipping the top
  jp M, ClipTop

  sub 64              ; If ypos is >= 64
  ret NC              ; sprite is off-screen

  neg                 ; If (64 - ypos) > height
  cp B                ; don't need to clip
  jr NC, VertClipDone

  ld B, A             ; Do bottom clipping by
  jr VertClipDone     ; setting height to (64 - ypos)

ClipTop:
  ld A, B             ; If ypos <= -height
  neg                 ; sprite is off-screen
  sub E
  ret NC

  push AF
  add A, B            ; Get the number of clipped rows
  ld E, 0             ; Set ypos to 0 (top of screen)
  ld B, E             ; Advance image data pointer
  ld C, A
  add IX, BC
  pop AF
  neg                 ; Get the number of visible rows
  ld B, A             ; and set as height

VertClipDone:
; Now we're doing horizontal clipping
  ld C, 0             ; Reset correction factor
  ld A, D

  cp -7               ; If 0 > xpos >= -7
  jr NC, ClipLeft     ; clip the left side

  cp 96               ; If xpos >= 96
  ret NC              ; sprite is off-screen

  cp 89               ; If 0 <= xpos < 89
  jr C, HorizClipDone ; don't need to clip

ClipRight:
  and 7 ; Determine the clipping mask
  ld C, A
  ld A, %11111111
FindRightMask:
  add A, A
  dec C
  jr NZ, FindRightMask
  ld (CLIP_MASK), A
  ld A, D
  jr HorizClipDone

ClipLeft:
  and 7 ; Determine the clipping mask
  ld C, A
  ld A, %11111111
FindLeftMask:
  add A, A
  dec C
  jr NZ, FindLeftMask
  cpl
  ld (CLIP_MASK), A
  ld A, D
  add A, 96 ; Set xpos so sprite will "spill over"
  ld C, 12 ; Set correction

HorizClipDone:
; A = xpos
; E = ypos
; B = height
; IX = image address

; Now we can finally display the sprite.
  ld H, 0
  ld D, H
  ld L, E
  add HL, HL
  add HL, DE
  add HL, HL
  add HL, HL

  ld E, A
  srl E
  srl E
  srl E
  add HL, DE

  push iy \ pop de
  add HL, DE

  ld D, 0 ; Correct graph buffer address
  ld E, C ; if clipping the left side
  sbc HL, DE

  and 7
  jr Z, _Aligned

  ld C, A
  ld DE, 11

_RowLoop:
  push BC
  ld B, C
  ld A, (CLIP_MASK) ; Mask out the part of the sprite
  and (IX)          ; to be horizontally clipped
  ld C, 0

_ShiftLoop:
  srl A
  rr C
  djnz _ShiftLoop

  xor (HL)
  ld (HL), A

  inc HL
  ld A, C
  xor (HL)
  ld (HL), A

  add HL, DE
  inc IX
  pop BC
  djnz _RowLoop
  ret

_Aligned:
  ld DE, 12

_PutLoop:
  ld A, (IX)
  xor (HL)
  ld (HL), A
  inc IX
  add HL, DE
  djnz _PutLoop
  ret

; D = xpos
; E = ypos
; B = height
; HL = image address
; IY = buffer address
PutSpriteAND:
  push af
  push bc
  push hl
  push de
  push ix
    push hl \ pop ix
    call _ClipSprAND
  pop ix
  pop de
  pop hl
  pop bc
  pop af
  ret

_ClipSprAND:
; Start by doing vertical clipping
  ld A, %11111111      ; Reset clipping mask
  ld (CLIP_MASK), A
  ld A, E              ; If ypos is negative
  or A                 ; try clipping the top
  jp M, ClipTop2

  sub 64               ; If ypos is >= 64
  ret NC               ; sprite is off-screen

  neg                  ; If (64 - ypos) > height
  cp B                 ; don't need to clip
  jr NC, VertClipDone2

  ld B, A              ; Do bottom clipping by
  jr VertClipDone2     ; setting height to (64 - ypos)

ClipTop2:
  ld A, B    ; If ypos <= -height
  neg        ; sprite is off-screen
  sub E
  ret NC

  push AF
  add A, B   ; Get the number of clipped rows
  ld E, 0    ; Set ypos to 0 (top of screen)
  ld B, E    ; Advance image data pointer
  ld C, A
  add IX, BC
  pop AF
  neg        ; Get the number of visible rows
  ld B, A    ; and set as height

VertClipDone2:
; Now we're doing horizontal clipping
  ld C, 0              ; Reset correction factor
  ld A, D

  cp -7                ; If 0 > xpos >= -7
  jr NC, ClipLeft2     ; clip the left side

  cp 96                ; If xpos >= 96
  ret NC               ; sprite is off-screen

  cp 89                ; If 0 <= xpos < 89
  jr C, HorizClipDone2 ; don't need to clip

ClipRight2:
  and 7 ; Determine the clipping mask
  ld C, A
  ld A, %11111111
FindRightMask2:
  add A, A
  dec C
  jr NZ, FindRightMask2
  ld (CLIP_MASK), A
  ld A, D
  jr HorizClipDone2

ClipLeft2:
  and 7 ; Determine the clipping mask
  ld C, A
  ld A, %11111111
FindLeftMask2:
  add A, A
  dec C
  jr NZ, FindLeftMask2
  cpl
  ld (CLIP_MASK), A
  ld A, D
  add A, 96 ; Set xpos so sprite will "spill over"
  ld C, 12  ; Set correction

HorizClipDone2:
; A = xpos
; E = ypos
; B = height
; IX = image address

; Now we can finally display the sprite.
  ld H, 0
  ld D, H
  ld L, E
  add HL, HL
  add HL, DE
  add HL, HL
  add HL, HL

  ld E, A
  srl E
  srl E
  srl E
  add HL, DE

  push iy \ pop de
  add HL, DE

  ld D, 0 ; Correct graph buffer address
  ld E, C ; if clipping the left side
  sbc HL, DE

  and 7
  jr Z, _Aligned2

  ld C, A
  ld DE, 11

_RowLoop2:
  push BC
  ld B, C
  ld A, (CLIP_MASK) ; Mask out the part of the sprite
  and (IX)          ; to be horizontally clipped
  ld C, 0

_ShiftLoop2:
  srl A
  rr C
  djnz _ShiftLoop2

  cpl
  and (HL)
  ld (HL), A

  inc HL
  ld A, C
  cpl
  and (HL)
  ld (HL), A

  add HL, DE
  inc IX
  pop BC
  djnz _RowLoop2
  ret

_Aligned2:
  ld DE, 12

_PutLoop2:
  ld A, (IX)
  cpl
  and (HL)
  ld (HL), A
  inc IX
  add HL, DE
  djnz _PutLoop2
  ret

; D = xpos
; E = ypos
; B = height
; IX = image address
; IY = buffer address
PutSpriteOR:
  push af
  push bc
  push hl
  push de
  push ix
    push hl \ pop ix
    call _ClipSprOR
  pop ix
  pop de
  pop hl
  pop bc
  pop af
  ret

_ClipSprOR:
; Start by doing vertical clipping
  ld A, %11111111      ; Reset clipping mask
  ld (CLIP_MASK), A
  ld A, E              ; If ypos is negative
  or A                 ; try clipping the top
  jp M, ClipTop3

  sub 64               ; If ypos is >= 64
  ret NC               ; sprite is off-screen

  neg                  ; If (64 - ypos) > height
  cp B                 ; don't need to clip
  jr NC, VertClipDone3

  ld B, A              ; Do bottom clipping by
  jr VertClipDone3     ; setting height to (64 - ypos)

ClipTop3:
  ld A, B    ; If ypos <= -height
  neg        ; sprite is off-screen
  sub E
  ret NC

  push AF
  add A, B   ; Get the number of clipped rows
  ld E, 0    ; Set ypos to 0 (top of screen)
  ld B, E    ; Advance image data pointer
  ld C, A
  add IX, BC
  pop AF
  neg        ; Get the number of visible rows
  ld B, A    ; and set as height

VertClipDone3:
; Now we're doing horizontal clipping
  ld C, 0                 ; Reset correction factor
  ld A, D

  cp -7                ; If 0 > xpos >= -7
  jr NC, ClipLeft3     ; clip the left side

  cp 96                ; If xpos >= 96
  ret NC               ; sprite is off-screen

  cp 89                ; If 0 <= xpos < 89
  jr C, HorizClipDone3 ; don't need to clip

ClipRight3:
  and 7 ; Determine the clipping mask
  ld C, A
  ld A, %11111111
FindRightMask3:
  add A, A
  dec C
  jr NZ, FindRightMask3
  ld (CLIP_MASK), A
  ld A, D
  jr HorizClipDone3

ClipLeft3:
  and 7 ; Determine the clipping mask
  ld C, A
  ld A, %11111111
FindLeftMask3:
  add A, A
  dec C
  jr NZ, FindLeftMask3
  cpl
  ld (CLIP_MASK), A
  ld A, D
  add A, 96 ; Set xpos so sprite will "spill over"
  ld C, 12  ; Set correction

HorizClipDone3:
; A = xpos
; E = ypos
; B = height
; IX = image address

; Now we can finally display the sprite.
  ld H, 0
  ld D, H
  ld L, E
  add HL, HL
  add HL, DE
  add HL, HL
  add HL, HL

  ld E, A
  srl E
  srl E
  srl E
  add HL, DE

  push iy \ pop de
  add HL, DE

  ld D, 0 ; Correct graph buffer address
  ld E, C ; if clipping the left side
  sbc HL, DE

  and 7
  jr Z, _Aligned3

  ld C, A
  ld DE, 11

_RowLoop3:
  push BC
  ld B, C
  ld A, (CLIP_MASK) ; Mask out the part of the sprite
  and (IX)          ; to be horizontally clipped
  ld C, 0

_ShiftLoop3:
  srl A
  rr C
  djnz _ShiftLoop3

  or (HL)
  ld (HL), A

  inc HL
  ld A, C
  or (HL)
  ld (HL), A

  add HL, DE
  inc IX
  pop BC
  djnz _RowLoop3
  ret

_Aligned3:
  ld DE, 12

_PutLoop3:
  ld A, (IX)
  or (HL)
  ld (HL), A
  inc IX
  add HL, DE
  djnz _PutLoop3
  ret

; From Axe's Commands.inc by Quigibo
; Inputs:  (e, l): X, Y
;    (c, b): width, height
RectXOR:
  ld a, 96 ; Clip Top
  sub e
  ret c
  ret z
  cp c ; Clip Bottom
  jr nc, $+3
  ld c, a
  ld a, 64 ; Clip Left
  sub l
  ret c
  ret z
  cp b ; Clip Right
  jr nc, $+3
  ld b, a

  xor a ; More clipping...
  cp b
  ret z
  cp c
  ret z
  ld h, a
  ld d, a

  push bc
  push iy
  pop bc
  ld a, l
  add a, a
  add a, l
  ld l, a
  add hl, hl
  add hl, hl ; (e, _) = (X, Y)
  add hl, bc ; (_, _) = (width, height)

  ld a, e
  srl e
  srl e
  srl e
  add hl, de
  and %00000111 ; (a, _) = (X^8, Y)
  pop de ; (e, d) = (width, height)

  ld b, a
  add a, e
  sub 8
  ld e, 0
  jr c, __BoxInvSkip
  ld e, a
  xor a
__BoxInvSkip:

__BoxInvShift: ; Input:  b = Left shift
  add a, 8     ; Input:  a = negative right shift
  sub b        ; Output: a = mask
  ld c, 0
__BoxInvShift1:
  scf
  rr c
  dec a
  jr nz, __BoxInvShift1
  ld a, c
  inc b
  rlca
__BoxInvShift2:
  rrca
  djnz __BoxInvShift2

__BoxInvLoop1: ; (e, d) = (width, height)
  push hl      ; a = bitmask
  ld b, d
  ld c, a
  push de
  ld de, 12
__BoxInvLoop2:
  ld a, c
  xor (hl)
  ld (hl), a
  add hl, de
  djnz __BoxInvLoop2
  pop de
  pop hl
  inc hl
  ld a, e
  or a
  ret z
  sub 8
  ld e, b
  jr c, __BoxInvShift
  ld e, a
  ld a, %11111111
  jr __BoxInvLoop1
__BoxInvEnd:

; From Axe's Commands.inc by Quigibo
; Input: (e, l): X, Y
;        (c, b): width, height
RectOR:
  ld a, 96 ; Clip Top
  sub e
  ret c
  ret z
  cp c ; Clip Bottom
  jr nc, $+3
  ld c, a
  ld a, 64 ; Clip Left
  sub l
  ret c
  ret z
  cp b ; Clip Right
  jr nc, $+3
  ld b, a

  xor a ; More clipping...
  cp b
  ret z
  cp c
  ret z
  ld h, a
  ld d, a

  push bc
  push iy
  pop bc
  ld a, l
  add a, a
  add a, l
  ld l, a
  add hl, hl
  add hl, hl ; (e, _) = (X, Y)
  add hl, bc ; (_, _) = (width, height)

  ld a, e
  srl e
  srl e
  srl e
  add hl, de
  and %00000111 ; (a, _) = (X^8, Y)
  pop de ; (e, d) = (width, height)

  ld b, a
  add a, e
  sub 8
  ld e, 0
  jr c, __BoxorSkip
  ld e, a
  xor a
__BoxorSkip:

__BoxorShift: ; Input:  b = Left shift
  add a, 8    ; Input:  a = negative right shift
  sub b       ; Output: a = mask
  ld c, 0
__BoxorShift1:
  scf
  rr c
  dec a
  jr nz, __BoxorShift1
  ld a, c
  inc b
  rlca
__BoxorShift2:
  rrca
  djnz __BoxorShift2

__BoxorLoop1: ; (e, d) = (width, height)
  push hl     ; a = bitmask
  ld b, d
  ld c, a
  push de
  ld de, 12
__BoxorLoop2:
  ld a, c
  or (hl)
  ld (hl), a
  add hl, de
  djnz __BoxorLoop2
  pop de
  pop hl
  inc hl
  ld a, e
  or a
  ret z
  sub 8
  ld e, b
  jr c, __BoxorShift
  ld e, a
  ld a, %11111111
  jr __BoxorLoop1
__BoxorEnd:

; From Axe's Commands.inc by Quigibo
; Input: (e, l): X, Y
;        (c, b): width, height
RectAND:
  ld a, 96 ; Clip Top
  sub e
  ret c
  ret z
  cp c ; Clip Bottom
  jr nc, $+3
  ld c, a
  ld a, 64 ; Clip Left
  sub l
  ret c
  ret z
  cp b ; Clip Right
  jr nc, $+3
  ld b, a

  xor a ; More clipping...
  cp b
  ret z
  cp c
  ret z
  ld h, a
  ld d, a

  push bc
  push iy
  pop bc
  ld a, l
  add a, a
  add a, l
  ld l, a
  add hl, hl
  add hl, hl ; (e, _) = (X, Y)
  add hl, bc ; (_, _) = (width, height)

  ld a, e
  srl e
  srl e
  srl e
  add hl, de
  and %00000111 ; (a, _) = (X^8, Y)
  pop de        ; (e, d) = (width, height)

  ld b, a
  add a, e
  sub 8
  ld e, 0
  jr c, __BoxandSkip
  ld e, a
  xor a
__BoxandSkip:

__BoxandShift: ;Input:  b = Left shift
  add a, 8     ;Input:  a = negative right shift
  sub b        ;Output: a = mask
  ld c, 0
__BoxandShift1:
  scf
  rr c
  dec a
  jr nz, __BoxandShift1
  ld a, c
  inc b
  rlca
__BoxandShift2:
  rrca
  djnz __BoxandShift2

__BoxandLoop1: ; (e, d) = (width, height)
  push hl      ; a = bitmask
  ld b, d
  ld c, a
  push de
  ld de, 12
__BoxandLoop2:
  ld a, c
  cpl
  and (hl)
  ld (hl), a
  add hl, de
  djnz __BoxandLoop2
  pop de
  pop hl
  inc hl
  ld a, e
  or a
  ret z
  sub 8
  ld e, b
  jr c, __BoxandShift
  ld e, a
  ld a, %11111111
  jr __BoxandLoop1
__BoxandEnd:

; 2-byte (across) sprite xor routine by Jon Martin
; optimized to be faster than Joe Wingbermeuhle's largesprite routine
; based on the 1-byte xor routine from "learn ti 83+ asm in 28 days"
; inputs:
; d=xc
; e=yc
; b=height
; hl=sprite pointer
; destroys all except shadow registers
PutSprite16XOR:
  push af
  push hl
  push bc
  push de
  push ix
    push hl \ pop ix
    ld a, d
    call _PutSprite16XOR
  pop ix
  pop de
  pop bc
  pop hl
  pop af
  ret

_PutSprite16XOR:
  ld h, 0          ;7
  ld l, e          ;4
  ld d, h          ;4
  add hl, hl       ;11
  add hl, de       ;11
  add hl, hl       ;11
  add hl, hl       ;11
  push iy \ pop de ;10
  add hl, de       ;11
  ld e, a          ;4
  srl e            ;8
  srl e            ;8
  srl e            ;8
  ld d, 0          ;7
  add hl, de       ;11
  ld d, h          ;4
  ld e, l          ;4
  and 7            ;4
  jp z, aligned    ;10
  ld c, a          ;4
  ld de, 12        ;10
rowloop:           ;total: 194
  push bc          ;11
  ld b, c          ;4
  xor a            ;4
  ld d, (ix)       ;19
  ld e, (ix+1)     ;19
shiftloop:         ;60 per loop
  srl d            ;8
  rr e             ;8
  rra              ;4
  djnz shiftloop   ;13/8, 37 per loop
  inc hl
  inc hl
  xor (hl)
  ld (hl), a
  ld a, e
  dec hl
  xor (hl)
  ld (hl), a
  ld a, d
  dec hl
  xor (hl)
  ld (hl), a
  pop bc       ;10
  ld de, 12    ;10
  add hl, de   ;11
  inc ix       ;10
  inc ix       ;10
  djnz rowloop ;13/8
  ret          ;10
aligned:
  ld de, 11
alignedloop:
  ld a, (ix)
  xor (hl)
  ld (hl), a
  ld a, (ix+1)
  inc hl
  xor (hl)
  ld (hl), a
  add hl, de
  inc ix
  inc ix
  djnz alignedloop
  ret

PutSprite16OR:
  push af
  push hl
  push bc
  push de
  push ix
    push hl \ pop ix
    ld a, d
    call _PutSprite16OR
  pop ix
  pop de
  pop bc
  pop hl
  pop af
  ret

_PutSprite16OR:
  ld h, 0          ;7
  ld l, e          ;4
  ld d, h          ;4
  add hl, hl       ;11
  add hl, de       ;11
  add hl, hl       ;11
  add hl, hl       ;11
  push iy \ pop de ;10
  add hl, de       ;11
  ld e, a          ;4
  srl e            ;8
  srl e            ;8
  srl e            ;8
  ld d, 0          ;7
  add hl, de       ;11
  ld d, h          ;4
  ld e, l          ;4
  and 7            ;4
  jp z, alignedor  ;10
  ld c, a          ;4
  ld de, 12        ;10
rowloopor:         ;total: 194
  push bc          ;11
  ld b, c          ;4
  xor a            ;4
  ld d, (ix)       ;19
  ld e, (ix+1)     ;19
shiftloopor:       ;60 per loop
  srl d            ;8
  rr e             ;8
  rra              ;4
  djnz shiftloopor ;13/8, 37 per loop
  inc hl
  inc hl
  xor (hl)
  ld (hl), a
  ld a, e
  dec hl
  or (hl)
  ld (hl), a
  ld a, d
  dec hl
  or (hl)
  ld (hl), a
  pop bc         ;10
  ld de, 12      ;10
  add hl, de     ;11
  inc ix         ;10
  inc ix         ;10
  djnz rowloopor ;13/8
  ret            ;10
alignedor:
  ld de, 11
alignedloopor:
  ld a, (ix)
  or (hl)
  ld (hl), a
  ld a, (ix+1)
  inc hl
  or (hl)
  ld (hl), a
  add hl, de
  inc ix
  inc ix
  djnz alignedloopor
  ret

PutSprite16AND:
  push af
  push hl
  push bc
  push de
  push ix
    push hl \ pop ix
    ld a, d
    call _PutSprite16AND
  pop ix
  pop de
  pop bc
  pop hl
  pop af
  ret

_PutSprite16AND:
  ld h, 0           ;7
  ld l, e           ;4
  ld d, h           ;4
  add hl, hl        ;11
  add hl, de        ;11
  add hl, hl        ;11
  add hl, hl        ;11
  push iy \ pop de  ;10
  add hl, de        ;11
  ld e, a           ;4
  srl e             ;8
  srl e             ;8
  srl e             ;8
  ld d, 0           ;7
  add hl, de        ;11
  ld d, h           ;4
  ld e, l           ;4
  and 7             ;4
  jp z, alignedand  ;10
  ld c, a           ;4
  ld de, 12         ;10
rowloopand:         ;total: 194
  push bc           ;11
  ld b, c           ;4
  xor a             ;4
  ld d, (ix)        ;19
  ld e, (ix+1)      ;19
shiftloopand:       ;60 per loop
  srl d             ;8
  rr e              ;8
  rra               ;4
  djnz shiftloopand ;13/8, 37 per loop
  inc hl
  inc hl
  xor (hl)
  ld (hl), a
  ld a, e
  dec hl
  cpl
  and (hl)
  ld (hl), a
  ld a, d
  dec hl
  cpl
  and (hl)
  ld (hl), a
  pop bc          ;10
  ld de, 12       ;10
  add hl, de      ;11
  inc ix          ;10
  inc ix          ;10
  djnz rowloopand ;13/8
  ret             ;10
alignedand:
  ld de, 11
alignedloopand:
  ld a, (ix)
  cpl
  and (hl)
  ld (hl), a
  ld a, (ix+1)
  inc hl
  cpl
  and (hl)
  ld (hl), a
  add hl, de
  inc ix
  inc ix
  djnz alignedloopand
  ret
