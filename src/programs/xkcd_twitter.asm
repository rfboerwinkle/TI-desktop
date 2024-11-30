; https://what-if.xkcd.com/34/

.org $4000
  ld BC, $0162
  ld HL, $C000
  ld DE, $C001
  ld A, $00
  ld ($C000), A
  ldir

  ld IX, args_set_buffer
  rst $08
  ld IX, $E000
  ld A, $0A
  ld (IX), A

  ; DE is my Xorshift LFSR
  ; https://en.wikipedia.org/wiki/Linear-feedback_shift_register
  ld DE, $ACE1
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

  ; DE = DE xor DE>>7
  ld B, D
  ld C, E
  srl B
  rr C
  srl B
  rr C
  srl B
  rr C
  srl B
  rr C
  srl B
  rr C
  srl B
  rr C
  srl B
  rr C

  ld A, D
  xor B
  ld D, A
  ld A, E
  xor C
  ld E, A

  ; DE = DE xor DE<<9
  ld B, E
  sla B

  ld A, D
  xor B
  ld D, A

  ; DE = DE xor DE>>13
  ld C, D
  srl C
  srl C
  srl C
  srl C
  srl C

  ld A, E
  xor C
  ld E, A



  ; E is even ? tweet2 : tweet1
  bit 0, E
  jr Z, tweet2

tweet1:
  ld HL, horse1
  ld ($E001), HL
  rst $08
  ; draw horizontal rule
  ld A, $FF
  ld ($C036), A
  ld ($C071), A
  ld ($C0AC), A
  ld ($C0E7), A
  ld ($C122), A
  ld ($C15D), A
  ld HL, horse2
  ld ($E001), HL
  rst $08
  ; clear horizontal rule
  ld A, $00
  ld ($C036), A
  ld ($C071), A
  ld ($C0AC), A
  ld ($C0E7), A
  ld ($C122), A
  ld ($C15D), A
  ld HL, horse3
  ld ($E001), HL
  rst $08
  jp loop

tweet2:
  ld HL, house1
  ld ($E001), HL
  rst $08
  ; draw horizontal rule
  ld A, $FF
  ld ($C036), A
  ld ($C071), A
  ld ($C0AC), A
  ld ($C0E7), A
  ld ($C122), A
  ld ($C15D), A
  ld HL, house2
  ld ($E001), HL
  rst $08
  ; clear horizontal rule
  ld A, $00
  ld ($C036), A
  ld ($C071), A
  ld ($C0AC), A
  ld ($C0E7), A
  ld ($C122), A
  ld ($C15D), A
  ld HL, house3
  ld ($E001), HL
  rst $08
  jp loop

args_set_buffer:
  .db $08, $00, $C0

horse1:
  .db $9D, $91, $8E, $9B, $8E, $AC, $9C, $BF, $8A, $BF, $BF, $BF
horse2:
  .db $91, $98, $9B, $9C, $8E, $BF, $92, $97, $BF, $BF, $BF, $BF
horse3:
  .db $92, $9C, $95, $8E, $BF, $85, $A9, $BF, $BF, $BF, $BF, $BF

house1:
  .db $96, $A2, $BF, $91, $98, $9E, $9C, $8E, $BF, $92, $9C, $BF
house2:
  .db $8F, $9E, $95, $95, $BF, $98, $8F, $BF, $BF, $BF, $BF, $BF
house3:
  .db $9D, $9B, $8A, $99, $9C, $AB, $BF, $BF, $BF, $BF, $BF, $BF

; T  H  E  R  E  '  S     A     H  O  R  S  E     I  N     I  S  L  E     5  .
; 9D 91 8E 9B 8E AC 9C BF 8A BF 91 98 9B 9C 8E BF 92 97 BF 92 9C 95 8E BF 85 A9
; M  Y     H  O  U  S  E     I  S     F  U  L  L     O  F     T  R  A  P  S  !
; 96 A2 BF 91 98 9E 9C 8E BF 92 9C BF 8F 9E 95 95 BF 98 8F BF 9D 9B 8A 99 9C AB
