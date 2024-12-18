; OS Utility Routines
; Provides several general-purpose routines
; Relies on privledged page code having an unlock flash routine at address $4001

; Output: B: Value from 0-4 indicating battery level (0 is critical)
GetBatteryLevel:
  push af

  ld b, 0
  ld a, %00000110
  out (6), a
  in a, (2)
  bit 0, a
  jr z, GetBatteryLevel_Done

  ld b, 1
  ld a, %01000110
  out (6), a
  in a, (2)
  bit 0, a
  jr z, GetBatteryLevel_Done

  ld b, 2
  ld a, %10000110
  out (6), a
  in a, (2)
  bit 0, a
  jr z, GetBatteryLevel_Done

  ld b, 3
  ld a, %11000110
  out (6), a
  in a, (2)
  bit 0, a
  jr z, GetBatteryLevel_Done

  ld b, 4
GetBatteryLevel_Done:
  ld a, %110
  out (6), a
  pop af
  ret

Sleep:
  ld a, i
  push af
  ld a, $02
  out ($10), a ; Disable LCD
  di ; And interrupts, for now
  im 1 ; interrupt mode 1, for cleanliness
  ld a, $01
  out ($03), a ; ON
  ei ; Enable interrupting when ON is pressed
  halt ; and halt :)
  di
  ld a, %00101001 ; Reset the interrupts
  out ($03), a
  ld a, $03
  out ($10), a ; Enable the screen
  pop af
  ret po
  ei
  ret

Shutdown:
  ld a, $02
  out ($10), a ; Disable LCD
  di ; And interrupts, for now
  im 1 ; interrupt mode 1, for cleanliness
  ld a, $01
  out ($03), a ; ON
  ei ; Enable interrupting when ON is pressed
  halt ; and halt :)
  jp Boot

DEMulA:        ; HL = DE � A
  ld HL, 0     ; Use HL to store the product
  ld B, 8      ; Eight bits to check
_loop:
  rrca         ; Check least-significant bit of accumulator
  jr NC, _skip ; If zero, skip addition
  add HL, DE
_skip:
  sla E        ; Shift DE one bit left
  rl D
  djnz _loop
  ret

UnlockFlash:
  push af
  push bc
    in a, (6)
    push af
      ld a, $7C ; privleged page
      out (6), a
      ld b, $01
      ld c, $14
      call $4001
    pop af
    out (6), a
  pop bc
  pop af
  ret

LockFlash:
  push af
  push bc
    in a, (6)
    push af
      ld a, $7C ; privleged page
      out (6), a
      ld b, $00
      ld c, $14
      call $4017
    pop af
    out (6), a
  pop bc
  pop af
  ret

; 16-bit Compare routines
CpHLDE:
  push hl
  or a
  sbc hl, de
  pop hl
  ret
CpHLBC:
  push hl
  or a
  sbc hl, bc
  pop hl
  ret
CpBCDE:
  push hl
  ld h, b
  ld l, c
  or a
  sbc hl, de
  pop hl
  ret
CpDEBC:
  push hl
  ld h, d
  ld l, e
  or a
  sbc hl, bc
  pop hl
  ret

; Compare Strings
; Z for equal, NZ for not equal
; Input: HL and DE are strings to compare
CompareStrings:
  ld a, (de)
  or a
  jr z, CompareStringsEoS
  cp (hl)
  ret nz
  inc hl
  inc de
  jr CompareStrings
CompareStringsEoS:
  ld a, (hl)
  or a
  ret

; >>> Quicksort routine v1.1 <<<
; by Frank Yaul 7/14/04
;
; Usage: bc->first, de->last,
;        call qsort
Quicksort:
  push hl
  push de
  push bc
  push af
  ld hl, 0
  push hl
qsloop:
  ld h,b
  ld l,c
  or a
  sbc hl, de
  jp c, next1 ; loop until lo<hi
  pop bc
  ld a, b
  or c
  jr z, endqsort
  pop de
  jp qsloop
next1:
  push de ; save hi,lo
  push bc
  ld a, (bc) ; pivot
  ld h,a
  dec bc
  inc de
fleft:
  inc bc ; do i++ while cur<piv
  ld a, (bc)
  cp h
  jp c, fleft
fright:
  dec de ; do i-- while cur>piv
  ld a, (de)
  ld l, a
  ld a, h
  cp l
  jp c, fright
  push hl ; save pivot
  ld h, d ; exit if lo>hi
  ld l, e
  or a
  sbc hl, bc
  jp c, next2
  ld a, (bc) ; swap (bc),(de)
  ld h, a
  ld a, (de)
  ld (bc), a
  ld a, h
  ld (de), a
  pop hl ; restore pivot
  jp fleft
next2:
  pop hl ; restore pivot
  pop hl ; pop lo
  push bc ; stack=left-hi
  ld b, h
  ld c, l ; bc=lo,de=right
  jp qsloop
endqsort:
  pop af
  pop bc
  pop de
  pop hl
  ret
