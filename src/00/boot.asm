; OS Start-Up
; Initializes hardware and starts OS

Boot:
  di

  ld sp, $C000 + SP_AD
  ; Memory mode 0
  ; Timers 1&2 mode slowest
  ld A, $06
  out ($04), A
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
  ; 8-bit mode
  ld A, $01
  call LCDDelay
  out ($10), A

  ; X-Increment Mode (move down one row each time?)
  ld A, $05
  call LCDDelay
  out ($10), A

 ; Enable screen
  ld A, $03
  call LCDDelay
  out ($10), A

  ; Op-amp control (OPA1) set to max (with DB1 set for some reason)
  ld A, $17 ; versus $13? TIOS uses $17, and that's the only value that works (the datasheet says go with $13)
  call LCDDelay
  out ($10), A

  ; Op-amp control (OPA2) set to max
  ld A, $0B
  call LCDDelay
  out ($10), A

  ; Contrast
  ld A, $EF
  call LCDDelay
  out ($10), A

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

  ; init kernel pane info
  ld A, $BF
  ld HL, $C000 + KERNEL_PANE_AD
  ld B, $18
_:
  ld (HL), A
  inc HL
  djnz -_

  ; init placeholder pane
  ld IX, $C000 + PLACEHOLDER_PANE_AD + $0093
  ld (IX+$0), %00011001
  ld (IX+$1), %01100110
  ld (IX+$2), %01000110
  ld (IX+$3), %10001001
  ld (IX+$4), %10010001
  ld (IX+$5), %01100010
  ld (IX+$6), %01100110
  ld (IX+$7), %10011000

  ; init screen
  ld HL, $C000 + PLACEHOLDER_PANE_AD
  ld C, $00
  call UpdatePane
  ld HL, $C000 + PLACEHOLDER_PANE_AD
  ld C, $06
  call UpdatePane
  call UpdateKernelPane

  jp Idling
