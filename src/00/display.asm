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
  ; DE = second character
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
; Input: C = starting column
;        HL = pane buffer address
UpdatePane:
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
  ret Z
  cp $0C
  ret Z
  jr loopUpdatePane

; Brief: updates the bottom $5 rows of pixels based on kernel state
; Note: assumes kernel memory page is loaded
UpdateKernelPane:
  ; Y-increment, column 0, row 3B
  ld A, $07
  out ($10), A
  ld A, $20
  call LCDDelay
  out ($10), A
  ld A, $BB
  call LCDDelay
  out ($10), A

  ; A = is left pane selected ? $FF : $00
  ld A, ($C000 + PANE_FLAG_AD)
  bit 4, A
  jr Z, _
  ld A, $00
  jr ++_
_:
  ld A, $FF
_:

  ; C = byte type for left pane
  ld C, A

  ; output 6 columns, then complement A and repeat
  ld B, $06
_:
  call LCDDelay
  out ($11), A
  djnz -_
  cpl
  ld B, $06
_:
  call LCDDelay
  out ($11), A
  djnz -_

  ; draw cursor position
  ld A, ($C000 + PANE_FLAG_AD)
  and %00001111
  srl A
  add A, $20
  call LCDDelay
  out ($10), A
  ld A, ($C000 + PANE_FLAG_AD)
  bit 0, A
  ld A, C ; does not affect F
  jr Z, _
  and %11110101
  or  %00000101
  call LCDDelay
  out ($11), A
  jr ++_
_:
  and %01011111
  or  %01010000
  call LCDDelay
  out ($11), A
_:

  ; assign alpha / numeric char
  ld HL, $C000 + PANE_FLAG_AD
  bit 5, (HL)
  ld HL, $C000 + KERNEL_PANE_AD + $0017 ; does not affect F
  jr Z, _
  ld (HL), $B3
  jr ++_
_:
  ld (HL), $8A
_:

  ; X-increment mode
  ld A, $05
  call LCDDelay
  out ($10), A

  ; IX = start of kernel pane
  ld IX, $C000 + KERNEL_PANE_AD

  ; B' = # columns to draw
  ; C' = column
  ld B, $0C
  ld C, $20

  ; This exx is to put the previous registers into the (') slot, but also is
  ; matched with an exx right before the "jp NZ, kernelPaneCharLoop".
kernelPaneCharLoop:
  exx

  ; A = next char to draw
  ld A, (IX)
  inc IX
  ; BC = first character
  ld D, $00
  and %00111111
  ld E, A
  ld HL, FONT
  add HL, DE
  add HL, DE
  ld B, (HL)
  inc HL
  ld C, (HL)

  ; A = next char to draw
  ld A, (IX)
  inc IX
  ; DE = second character
  ld D, $00
  and %00111111
  ld E, A
  ld HL, FONT
  add HL, DE
  add HL, DE
  ld D, (HL)
  inc HL
  ld E, (HL)

  ; reset pointer
  ld A, $BC
  out ($10), A
  exx
  ld A, C
  inc C
  exx
  call LCDDelay
  out ($10), A

  ; draw first byte
  ld A, B
  and %11110000
  ld H, A
  ld A, D
  srl A \ srl A \ srl A \ srl A
  add A, H
  call LCDDelay
  out ($11), A
  ; draw second byte
  ld A, B
  sla A \ sla A \ sla A \ sla A
  ld H, A
  ld A, D
  and %00001111
  add A, H
  call LCDDelay
  out ($11), A
  ; draw third byte
  ld A, C
  and %11110000
  ld H, A
  ld A, E
  srl A \ srl A \ srl A \ srl A
  add A, H
  call LCDDelay
  out ($11), A
  ; draw fourth byte
  ld A, C
  sla A \ sla A \ sla A \ sla A
  ld H, A
  ld A, E
  and %00001111
  add A, H
  call LCDDelay
  out ($11), A

  exx
  dec B
  jp NZ, kernelPaneCharLoop

  ret

; Brief: wait until the LCD can be written
LCDDelay:
  push af
_:
  in a, ($10)
  rla
  jr c, -_
  pop af
  ret

; FONT INFORMATION
; Note: Only black on white is supported right now...
;
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
; $87 7   $97 N   $A7 *   $B7 P-CUL
; $88 8   $98 O   $A8 /   $B8 P-CUR
; $89 9   $99 P   $A9 .   $B9 P-CDR
; $8A A   $9A Q   $AA :   $BA P-CDL
; $8B B   $9B R   $AB !   $BB P-TU
; $8C C   $9C S   $AC '   $BC P-TR
; $8D D   $9D T   $AD ^   $BD P-TD
; $8E E   $9E U   $AE v   $BE P-TL
; $8F F   $9F V   $AF (   $BF SPACE
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
; P-VER
.db $44, $44, $07, $44, $0C, $44, $4C, $00, $47, $00, $0F, $44
; P-TR P-TD P-TL SPACE
.db $4C, $44, $4F, $00, $47, $44, $00, $00
