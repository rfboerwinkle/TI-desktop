; OS Display Routines
; Provides routines for manipulating a buffer, as well as the screen

; Brief: draws a line of text to a process's pane
; Input: IY = text address
DrawText:
  ; C = old RAM
  ; swap to kernel RAM
  in A, ($05)
  ld C, A
  ld A, $00
  out ($05), A

  ; DE = pane buffer address
  ld A, ($C000)
  ld DE, PCB_SIZE
  ld B, A
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_
  ld E, (IX+$03)
  ld D, (IX+$04)

  ; swap to old RAM
  ld A, C
  out ($05), A

  ; push pane buffer address
  push DE

  ; C' = $06 (number of columns per pane)
  ld C, $06
  exx

  ; pop pane buffer address into DE
  pop DE

_:
  ; Get the first $36 rows of pixels from $05 pixels downward
  ld B, $00
  ld C, $36
  push DE
  pop HL
  inc HL
  inc HL
  inc HL
  inc HL
  inc HL
  ldir
  ; copy write head (DE) to IX
  push DE
  pop IX

  ; BC = first character
  ld D, $00
  ld A, (IY)
  and %00111111
  ld E, A
  ld HL, FONT
  add HL, DE
  add HL, DE
  ld B, (HL)
  inc HL
  ld C, (HL)
  inc IY
  ; DE = first character
  ld D, $00
  ld A, (IY)
  and %00111111
  ld E, A
  ld HL, FONT
  add HL, DE
  add HL, DE
  ld D, (HL)
  inc HL
  ld E, (HL)
  inc IY

  inc IX

  ; draw first byte
  ld A, B
  and %11110000
  ld H, A
  ld A, D
  srl A \ srl A \ srl A \ srl A
  add A, H
  ld (IX), A
  inc IX
  ; draw second byte
  ld A, B
  sla A \ sla A \ sla A \ sla A
  ld H, A
  ld A, D
  and %00001111
  add A, H
  ld (IX), A
  inc IX
  ; draw third byte
  ld A, C
  and %11110000
  ld H, A
  ld A, E
  srl A \ srl A \ srl A \ srl A
  add A, H
  ld (IX), A
  inc IX
  ; draw fourth byte
  ld A, C
  sla A \ sla A \ sla A \ sla A
  ld H, A
  ld A, E
  and %00001111
  add A, H
  ld (IX), A
  inc IX

  ; loop as long as we have more columns to update
  exx
  dec C
  exx
  ; copy write head (IX) to DE
  push IX
  pop DE
  jp NZ, -_

  ret

; Brief: checks if the currently running (typically just swapped off) process
;        is resident in one of the display frames, and updates the screen
;        accordingly.
UpdatePane:
  ; A' = old RAM page
  ; load kernel RAM page
  in A, ($05)
  ex AF, AF'
  ld A, $00
  out ($05), A

  ; HL = pane buffer address
  ; A = PID
  ld A, ($C000)
  ld B, A
  ld DE, PCB_SIZE
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_
  ld L, (IX+$03)
  ld H, (IX+$04)

  ; C = starting column
  ld IX, $C000 + PID_LEFT_PANE_AD
  cp (IX)
  jr NZ, _
  ld C, $00
  jr startUpdatePane
_:
  ld IX, $C000 + PID_RIGHT_PANE_AD
  cp (IX)
  jr NZ, _
  ld C, $06
  jr startUpdatePane
_:

  ex AF, AF'
  out ($05), A
  ret
startUpdatePane:
  ; return to old RAM page
  ex AF, AF'
  out ($05), A
loopUpdatePane:
  ; reset position
  ld A, $80
  call LCDDelay
  out ($10), A
  ld A, $20
  add A, C
  call LCDDelay
  out ($10), A
  ; loop through the rows
  ld B, $3B
_:
    ld A, (HL)
    call LCDDelay
    out ($11), A
    inc HL
  djnz -_
  inc C
  ld A, C
  cp $06
  jr Z, _
  cp $0C
  jr Z, _
  jr loopUpdatePane

_:
  ; return to scheduler who called this process
  ret

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

; ; Brief: Copy the buffer to the screen, guaranteed
; BufferToLCD:
;   ld A, I
;   ld HL, GBUF_ADDRESS
;   ld C, $10
;   ld A, $80
; setRow:
;   in F, (C)
;   jp m, setRow
;   out ($10), A
;   ld DE, $000C
;   ld A, $20
; col:
;   in F, (C)
;   jp m, col
;   out ($10), A
;   push AF
;   ld B, 64
; row:
;   ld A, (HL)
; rowWait:
;   in F, (C)
;   jp m, rowWait
;   out ($11), A
;   add HL, DE
;   djnz row
;   pop AF
;   dec H
;   dec H
;   dec H
;   inc HL
;   inc A
;   cp $2C
;   jp nz, col
;
;   ret

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


; 1XXX XXXX
; printing character
;
; 10XX XXXX
; B on W
;
; 11XX XXXX
; W on B
;
; for B on W:
;
; $80 0   $90 G   $A0 W   $B0 )
; $81 1   $91 H   $A1 X   $B1 <
; $82 2   $92 I   $A2 Y   $B2 >
; $83 3   $93 J   $A3 Z   $B3 #
; $84 4   $94 K   $A4 =   $B4 _
; $85 5   $95 L   $A5 -   $B5 P-HOR
; $86 6   $96 M   $A6 +   $B6 P-VER
; $87 7   $97 N   $A7 *   $B7 P-C-UL
; $88 8   $98 O   $A8 /   $B8 P-C-UR
; $89 9   $99 P   $A9 .   $B9 P-C-LR
; $8A A   $9A Q   $AA :   $BA P-C-LL
; $8B B   $9B R   $AB !   $BB P-T-T
; $8C C   $9C S   $AC '   $BC P-T-R
; $8D D   $9D T   $AD ^   $BD P-T-B
; $8E E   $9E U   $AE v   $BE P-T-L
; $8F F   $9F V   $AF (   $BF SP
;
; NOTE: "v" indicates the pateto character

FONT:
; Most-significant bit is Upper Left pixel. Bits proceed right, then down.
; 0 1 2 3 4 5
.db $EA, $AE, $4C, $4E, $C2, $4E, $E2, $6E, $AA, $62, $E8, $6E
; 6 7 8 9 A B
.db $68, $EE, $E2, $22, $EE, $AE, $EA, $E2, $4A, $EA, $CA, $EC
; C D E F G H
.db $E8, $8E, $CA, $AC, $E8, $CE, $E8, $C8, $E8, $BE, $AA, $EA
; I J K L M N
.db $E4, $4E, $E4, $4C, $AC, $EA, $88, $8E, $EE, $AA, $CA, $AA
; O P Q R S T
.db $4A, $A4, $EA, $E8, $EA, $AF, $EA, $CA, $68, $6E, $E4, $44
; U V W X Y Z
.db $AA, $AE, $AA, $E4, $AE, $EE, $AA, $4A, $AA, $44, $E2, $4E
; = - + * / .
.db $0E, $0E, $00, $E0, $04, $E4, $0A, $4A, $02, $48, $00, $04
; : ! ' ^ PATETO (
.db $04, $04, $44, $04, $44, $00, $4A, $00, $A4, $00, $24, $42
; ) < > # _ P-HOR
.db $42, $24, $06, $86, $0C, $2C, $AF, $AF, $00, $0E, $0F, $00
; P-VER P-C-UL P-C-UR P-C-LR P-C-LL P-T-T
.db $44, $44, $07, $44, $0C, $44, $4C, $00, $47, $00, $0F, $44
; P-T-R P-T-B P-T-L SPACE
.db $4C, $44, $4F, $00, $47, $44, $00, $00
