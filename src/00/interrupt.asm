; Knight Kernel System Interrupt
; 9/5/2011
; Manages context switching, timed threads, and the USB interrupt handler

SysInterrupt:
  di
  push af
  push bc
  push de
  push hl
  push ix
  push iy
  exx
  ex af, af'
  push af
  push bc
  push de
  push hl

  jp USBInterrupt


InterruptResume:
  in a, (04h)
  bit 0, a
  jp nz, IntHandleON
  bit 1, a
  jp nz, IntHandleTimer1
  bit 2, a
  jp nz, IntHandleTimer2
  bit 4, a
  jp nz, IntHandleLink
  bit 5, a
  jp nz, IntHandleCrystal1
  bit 6, a
  jp nz, IntHandleCrystal2
  bit 7, a
  jp nz, IntHandleCrystal3
  jp SysInterruptDone ; Special case - RST $38
; TODO: these really should be cleared with port 2....
IntHandleON:
  in a, (03h)
  res 0, a
  out (03h), a
  set 0, a
  out (03h), a
  ; ON interrupt
  jp SysInterruptDone
IntHandleTimer1:
  in a, (03h)
  res 1, a
  out (03h), a
  set 1, a
  out (03h), a
  ; Timer 1 interrupt
  jp SysInterruptDone
IntHandleTimer2:
  in a, (03h)
  res 2, a
  out (03h), a
  set 2, a
  out (03h), a
  ; Timer 2 interrupt
  jp SysInterruptDone
IntHandleLink:
  in a, (03h)
  res 4, a
  out (03h), a
  set 4, a
  out (03h), a
  ; Link interrupt
  jp SysInterruptDone
IntHandleCrystal1:
  in A, ($04)
  res 5, A
  out ($04), A
  ; The documentation is a little confusing here, see:
  ; https://wikiti.brandonw.net/index.php?title=83Plus:Ports:30
  ; Do we have to write to port 31 again?
  ; see boot.asm
  ld A, %00000011
  out ($31), A
  ; Crystal timer 1 interrupt
  ; This is the scheduler

  call UpdatePane

  ; load kernel memory space
  ld A, $00
  out ($05), A

  ; DE = PCB_SIZE
  ld DE, PCB_SIZE

  ; IX = first byte of old PCB
  ; A = PID
  ld A, ($C000)
  ld B, A
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_

  ; write SP to table
  ld ($C000 + SP_LOADING_AD), SP
  ld HL, ($C000 + SP_LOADING_AD)
  ld (IX+1), L
  ld (IX+2), H

  ; cycle the ready queue
  ld IX, $BFFF
_:
  inc IX
  ld B, (IX+1)
  ld (IX), B
  inc B
  djnz -_
  ld (IX), A

schedulerLoad:
  ; should be set already, unless you jump directly to this label ^
  ; DE = PCB_SIZE
  ld DE, PCB_SIZE

  ; IX = first byte of new PCB
  ld A, ($C000)
  ld B, A
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_

  ; load new code page
  ld A, (IX)
  out ($06), A

  ; read new SP
  ld H, (IX+$02)
  ld L, (IX+$01)
  ld SP, HL

  ; load new memory page
  ld A, ($C000)
  out ($05), A

  jr SysInterruptDone
IntHandleCrystal2:
  in a, (03h)
  res 6, a
  out (03h), a
  set 6, a
  out (03h), a
  ; Crystal timer 2 interrupt
  jr SysInterruptDone
IntHandleCrystal3:
  in a, (03h)
  res 7, a
  out (03h), a
  set 7, a
  out (03h), a
  ; Crystal timer 3 interrupt
SysInterruptDone:
  pop hl
  pop de
  pop bc
  pop af
  exx
  ex af, af'
  pop iy
  pop ix
  pop hl
  pop de
  pop bc
  pop af
  ei
  ret

USBInterrupt:
  in a, ($55) ; USB Interrupt status
  bit 0, a
  jr z, USBUnknownEvent
  bit 2, a
  jr z, USBLineEvent
  bit 4, a
  jr z, USBProtocolEvent
  jp InterruptResume

USBUnknownEvent:
  jp InterruptResume ; Placeholder

USBLineEvent:
  in a, ($56) ; USB Line Events
  xor $FF
  out ($57), a ; Acknowledge interrupt and disable further interrupts
  jp InterruptResume

USBProtocolEvent:
  in a, ($82)
  in a, ($83)
  in a, ($84)
  in a, ($85)
  in a, ($86) ; Merely reading from these will acknowledge the interrupt
  jp InterruptResume
