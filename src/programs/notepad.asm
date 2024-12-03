.org $4000
  nop
  nop
  ld IX, setPane
  rst $08
loop:
  nop
  nop
  ld IX, input
  rst $08
  nop
  nop
  ld IX, print
  rst $08
  nop
  nop
  jr loop

setPane:
  .db $08, $0C, $C0
input:
  .db $0C, $00, $C0
print:
  .db $0A, $00, $C0
