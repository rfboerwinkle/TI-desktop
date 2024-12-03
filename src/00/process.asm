; process management

; Brief: spawns a process from a page
; Input: H = page
; Output: L = PID
; Note: Assumes kernel memory space
SpawnProcess:
  ; DE = PCB_SIZE
  ld DE, PCB_SIZE

  ; search the code memory table for unused RAM page
  ; C = new PID
  ; IX = address of C in the pcb table
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
  ld C, $00
_:
  add IX, DE
  inc C
  ld B, (IX)
  inc B
  djnz -_

  ; if (C >= $08)
  ;   return 0
  ld L, $00
  ld A, C
  and %1111000
  ret NZ

  ; init PCB
  ld (IX), H
  ld (IX+$1), $08 ; these are here to be noticable
  ld (IX+$2), $08
  ld (IX+$3), $C0
  ld (IX+$4), $00

  ; init SP and PC
  ld A, C
  out ($05), A
  ld HL, $FFE8
  ld ($C000 + SP_AD), HL
  ld HL, $4000
  ld ($FFFC), HL
  ld A, $00
  out ($05), A

  ; go to end of ready queue
  ld HL, $BFFF
_:
  inc HL
  ld B, (HL)
  inc B
  djnz -_

  ; add new PID
  ld (HL), C

  ; return new PID
  ld L, C
  ret

; Brief: kills a process
; Input: C = PID
; Note: Assumes kernel memory space
; Note: Does not return, jumps to Idling
; Note: Clears the stack, just in case
KillProcess:
  ; clear stack (just in case)
  ld SP, ($C000 + SP_AD)

  ; if (C == 0 or C > 7)
  ;   return
  ld A, C
  and %00000111
  cp $00
  jp Z, Idling

  ; DE = PCB_SIZE
  ld DE, PCB_SIZE

  ; IX = PCB address
  ld B, C
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_

  ; clear the PCB
  ; This is dependent on PCB_SIZE
  ; (so you can search for that string)
  ld (IX), $00
  ld (IX+$01), $00
  ld (IX+$02), $00
  ld (IX+$03), $00
  ld (IX+$04), $00

  ; shift and search for PID from the end
  ld HL, $C007
  ld B, $00
_:
  dec HL
  ld A, (HL)
  ld (HL), B
  ld B, A
  cp C
  jr NZ, -_

  ; If the killed process was in the left pane, clear it and return
  ld A, ($C000 + PID_LEFT_PANE_AD)
  cp C
  jr NZ, _
  ld C, $00
  ld HL, $C000 + PLACEHOLDER_PANE_AD
  call UpdatePane
  jp Idling
_:

  ; If the killed process was in the right pane, clear it and return
  ld A, ($C000 + PID_RIGHT_PANE_AD)
  cp C
  jr NZ, _
  ld C, $06
  ld HL, $C000 + PLACEHOLDER_PANE_AD
  call UpdatePane
_:
  jp Idling

; Brief: returns the currently running PID
; Output: L = PID
; Note: Does not modify IX
GetPID:
  ; E = old RAM page
  ; load kernel RAM page
  in A, ($05)
  ld E, A
  ld A, $00
  out ($05), A

  ; L = current PID
  ld A, ($C000)
  ld L, A

  ; restore RAM page
  ld A, E
  out ($05), A

  ret

; Brief: sets the pane buffer address of the currently running PID
; Input: HL = pane buffer address
SetPaneBuffer:
  ; C = old RAM
  ; swap to kernel RAM
  in A, ($05)
  ld C, A
  ld A, $00
  out ($05), A

  ; set pane buffer address
  ld A, ($C000)
  ld DE, PCB_SIZE
  ld B, A
  ld IX, $C000 + PCB_TABLE_AD - PCB_SIZE
_:
  add IX, DE
  djnz -_
  ld (IX+$03), L
  ld (IX+$04), H

  ; swap to old RAM
  ld A, C
  out ($05), A

  ret
