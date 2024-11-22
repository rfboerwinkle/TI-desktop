; OS Start-Up
; Initializes hardware and starts OS

Boot:
ShutDown:
  di
  ; Some of this appears redundant, but it has to be done so that ShutDown and Reboot can both be called regardless of the state of the calculator
  ld a, 6
  out (4), a ; Memory mode 0
  ; Set memory mapping
  ; Bank 0: Flash Page 00
  ; Bank 1: Flash Page *
  ; Bank 2: RAM Page 01
  ; Bank 3: RAM Page 00
  ; In this order for consistency with TI-83+ and TI-73 mapping
  ld a, $81
  out (7), a
  ld sp, 0
  call Sleep

Reboot:
  di

  ld sp, 0
  ld a, 6
  out (4), a ; Memory mode 0
  ; Set memory mapping
  ; Bank 0: Flash Page 00
  ; Bank 1: Flash Page *
  ; Bank 2: RAM Page 01
  ; Bank 3: RAM Page 00
  ; In this order for consistency with TI-83+ and TI-73 mapping
  ld a, $81
  out (7), a

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

  ; Set interrupt mode
  ld a, %0001011
  out (3), a

  ; Clear RAM
  ld hl, $8000
  ld (hl), 0
  ld de, $8001
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

  ; Congrats!  You've booted up your calculator.  Now do something interesting.


  ld iy, $8100
  ld hl, SmileyFace
  ld b, 4
  ld de, 0
  call PutSpriteOR

  call BufferToLCD

  call FlushKeys
  call WaitKey
  jp ShutDown

SmileyFace:
  .db %01110000
  .db %00000000
  .db %10001000
  .db %01110000
