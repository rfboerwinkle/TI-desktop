.org $4000

  ld IX, $C000
  ld (IX), $08
  ld DE, $0162 ; length of each pane

hardLoop:
  ld HL, startOfAnimation + $0001
  ld A, (startOfAnimation)
  ld C, A

loop:

  ld B, $FF
_:
  ld A, $FF
_:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  dec A
  jr NZ, -_
  djnz --_

  ld ($C001), HL
  rst $08
  add HL, DE
  dec C
  jr NZ, loop
  jr hardLoop

startOfAnimation:
