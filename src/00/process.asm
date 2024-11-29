; process management

; Brief: spawns a process from a page
; Input: H = page
; Output: L = PID
SpawnProcess:
  ; E' = old RAM page
  ; load kernel RAM page
  in A, ($05)
  ld E, A
  exx
  ld A, $00
  out ($05), A

  ; DE = PCB_SIZE
  ld DE, PCB_SIZE

  ; search the code memory table for unused RAM page
  ; C = new PID
  ; IX = address of C in the pcb table
  ld IX, $C008 - PCB_SIZE
  ld C, $00
_:
  add IX, DE
  inc C
  ld B, (IX)
  inc B
  djnz -_

  ; if (C >= $08)
  ;   return 0
  ld A, C
  and %1111000
  jr Z, _
    exx
    ld C, $00
    ld A, E
    out ($05), A
    ret
_:

  ; populate PCB
  exx
  ld (IX), H
  exx
  ld (IX+1), $EA
  ld (IX+2), $FF

  ; go to end of ready queue
  ld HL, $BFFF
_:
  inc HL
  ld B, (HL)
  inc B
  djnz -_

  ; add new PID
  ld (HL), C

  ; add new PC to user space
  ld A, C
  out ($05), A
  ld HL, $4000
  ld ($FFFE), HL

  ; restore RAM page
  exx
  ld A, E
  out ($05), A
  ; return new PID
  ld L, C
  ret

; Brief: kills a process
; Input: L = PID
KillProcess:
  ; C = RAM page to return to
  in A, ($05)
  ld C, A

  ; load kernel RAM page
  ld A, $00
  out ($05), A

  ; DE = PCB_SIZE
  ld DE, PCB_SIZE

  ; IX = PCB address
  ld B, L
  ld IX, $C008 - PCB_SIZE
_:
  add IX, DE
  djnz -_

  ; clear the PCB
  ; This is dependent on PCB_SIZE
  ; (so you can search for that string)
  ld (IX), $00
  ld (IX+$01), $00
  ld (IX+$02), $00

  ; H = currently running PID
  ; i.e. calling PID
  ld A, ($C000)
  ld H, A

  ; shift and search for PID from the end
  ld IX, $C007
  ld B, $00
_:
  dec IX
  ld A, (IX)
  ld (IX), B
  ld B, A
  cp L
  jr NZ, -_

  ; if (H == L)
  ;   load next process as if normally scheduled context switch
  ; else
  ;   regular exit
  ld A, L
  cp H
  jr NZ, _
  ; You might think that there would be an extra PC on the stack that is being
  ; mangled, but fear not, the "call KillProcess" in "interrupt.asm" was on the
  ; user stack, so it gets thrown out.
  jp schedulerLoad
_:

  ; restore RAM page
  ld A, C
  out ($05), A
  ret

; Brief: returns the currently running PID
; Output: L = PID
; Note: Does not modify IX
GetPID:
  ; E = old RAM page
  ; load kernel RAM page
  in A, ($05)
  ld E, A
  ld A, $80
  out ($05), A

  ; L = current PID
  ld A, ($C000)
  ld L, A

  ; restore RAM page
  ld A, E
  out ($05), A

  ret
