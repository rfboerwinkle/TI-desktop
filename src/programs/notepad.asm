.org $4000
  ; Clear RAM
  ld hl, $C000
  ld (hl), 0
  ld de, $C001
  ld bc, $7FFF
  ldir


  ld IX, setPane
  rst $08
loop:

  ld IX, input
  rst $08

  ld IX, print
  rst $08

  jr loop

setPane:
  .db $08, $0C, $C0
input:
  .db $0C, $00, $C0
print:
  .db $0A, $00, $C0
