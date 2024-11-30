.org $4000
  ld IX, args
  rst $08

  ld DE, $0000
  ld A, $00
  ld HL, $C000
loop:
  ld B, $8F
_:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  djnz -_
  inc A
  scf
  adc HL, DE
  jp NZ, _
  ld HL, $C000
_:
  ld (HL), A
  jr loop

args:
  .db $08, $00, $C0
