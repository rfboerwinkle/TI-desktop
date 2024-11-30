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

  ; init process 1
  ; RAM has been cleared, so we just have to set non-zero values
  ld IX, $C000
  ; PID in ready queue
  ld (IX), $01
  ; code memory
  ld (IX+$08), $02
  ; high byte of pane buffer
  ld (IX+$0B), $C0
  ld A, $02
  ld ($C000 + PID_LEFT_PANE_AD), A
  ld A, $03
  ld ($C000 + PID_RIGHT_PANE_AD), A
  ld SP, $FFEA

  ld A, $01
  out ($05), A
  ld HL, $4000
  ld ($FFFE), HL

  jp IntHandleCrystal1
