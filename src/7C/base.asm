; Privledged Page Routines

.org $4000

; Safety
; If a program errors out and runs into this code,
; it should help avoid serious problems with outputting
; bad values to protected ports.
  rst 00h

UnlockFlash:
  ld a,i
  jp pe, _
  ld a, i
_:
  push af
  di
  ld a, 1
  nop
  nop
  im 1
  di
  out ($14),a
  pop af
  ret po
  ei
  ret

LockFlash:
  ld a,i
  jp pe, _
  ld a, i
_:
  push af
  di
  xor a
  nop
  nop
  im 1
  di
  out ($14),a
  pop af
  ret po
  ei
  ret
