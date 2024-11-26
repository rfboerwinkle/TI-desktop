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
loop:
  jp loop

spawnFiller:
  .db $02, $03, $C0, $00
spawnClearer:
  .db $02, $04, $C0, $00
; this really should dynamically get its own pid...
; also, kill oneself is not yet supported!
killSelf:
  .db $04, $01
