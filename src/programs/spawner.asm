.org $4000
  nop
  nop
  ld IX, spawnFiller
  rst $08
  nop
  nop
  ld IX, spawnClearer
  rst $08
  nop
  nop
  ld IX, killSelf
  rst $08
loop:
  jp loop

spawnFiller:
  .db $02, $03, $00, $C0
spawnClearer:
  .db $02, $04, $00, $C0
; this really should dynamically get its own pid...
killSelf:
  .db $04, $01
