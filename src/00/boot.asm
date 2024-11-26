; OS Start-Up
; Initializes hardware and starts OS

Boot:
  di

  ld sp, 0
  ; Memory mode 0
  ; Timers 1&2 mode slowest
  ld a, 6
  out (4), a
  ; Set memory mapping
  ; Bank 0: Flash Page 00
  ; Bank 1: unset
  ; Bank 2: unset
  ; Bank 3: RAM Page 00

  ; Initialize hardware
  ld a, 3
  out ($E), a ; What does this do? (TIOS does it)
  xor a
  out ($F), a ; What does this do? (TIOS does it)

  call UnlockFlash
    ; Remove RAM Execution Protection
    xor a
    out ($25), a ; RAM Lower Limit ; out (25), 0
    dec a
    out ($26), a ; RAM Upper Limit ; out (26), $FF

    ; Remove Flash Execution Protection
    out ($23), a ; Flash Upper Limit ; out (23), $FF
    out ($22), a ; Flash Lower Limit ; out (22), $FF
  call LockFlash
  ; Set CPU speed to 15 MHz
  ld a, 1
  out ($20), a

  xor A
  out ($05), A
  ; Clear RAM
  ld hl, $C000
  ld (hl), 0
  ld de, $C001
  ld bc, $7FFF
  ldir

  ; Initialize LCD
  ld a, 05h
  call LCDDelay
  out (10h), a ; X-Increment Mode

  ld a, 01h
  call LCDDelay
  out (10h), a ; 8-bit mode

  ld a, 3
  call LCDDelay
  out (10h), a ; Enable screen

  ld a, $17 ; versus $13? TIOS uses $17, and that's the only value that works (the datasheet says go with $13)
  call LCDDelay
  out (10h), a ; Op-amp control (OPA1) set to max (with DB1 set for some reason)

  ld a, $B ; B
  call LCDDelay
  out (10h), a ; Op-amp control (OPA2) set to max

  ld a, $EF
  call LCDDelay
  out (10h), a ; Contrast

  ; Setup crystal timer 1 for scheduler
  ; https://wikiti.brandonw.net/index.php?title=83Plus:Ports:30
  ; 32768Hz, 256 loops, 15MHz
  ; = interrupt 128 times a second
  ; = 11k instructions per loop
  ; see interrupt.asm : IntHandleCrystal1
  ld A, $45
  out ($30), A
  ld A, %00000011
  out ($31), A
  ld A, $FF
  out ($32), A

  ; Set interrupt mode
  ld A, %00101001
  out ($03), A

  ; init process 1
  ; RAM has been cleared, so we just have to set non-zero values
  ld IX, $C000
  ; PID in ready queue
  ld (IX), $01
  ; code memory table
  ld (IX+$08), $02
;   ; SP low byte
;   ld (IX+$09), $E9
;   ; SP high byte
;   ld (IX+$0A), $FF
  ld SP, $FFEA

  ld A, $01
  out ($05), A
  ld HL, $4000
  ld ($FFFE), HL

  jp IntHandleCrystal1

SmileyFace0:
  .db %00000000
  .db %00000000
  .db %00000000
  .db %00000000
SmileyFace1:
  .db %01010000
  .db %00000000
  .db %10001000
  .db %01110000
SmileyFace2:
  .db %01010000
  .db %00000000
  .db %01110000
  .db %10001000
