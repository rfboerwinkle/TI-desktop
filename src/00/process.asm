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
  ld A, $80
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
; Input: D = PID
; NOTE: no protection against a process killing itself. that will do bad things!
; KillProcess:
;   in A, ($05) ; RAM page to return to
;   ld E, A
;   ld C, $80
;   out ($05), C ; kernel RAM page
;
;   ; calculate address of PCB
;   ld H, $C0
;   ld A, D
;   add A, $07
;   ld L, A
;
;   ; clear the PCB (yes it's 1 byte rn...)
;   ld (HL), $00
;
;   ; shift and search for PID from the end
;   ld IX, $0007
; _:
;   dec IX
;   ld A, (IX)
;   ld B, (IX+1)
;   ld (IX), B
;   xor D
;   jr NZ -_
;
;   out ($05), E
;   ret
