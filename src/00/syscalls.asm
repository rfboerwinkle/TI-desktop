; Called via "rst $08". Arguments should be at IX

SysCall:
  di ; TODO: The problem is, some system calls require switching to kernel memory.
     ; If you change to kernel memory, and then you get swapped off and back on
     ; by the scheduler, you're back to user memory without realizing it.
  push AF
  push BC
  push DE
  push HL
  push IX
  push IY
  exx
  ex AF, AF'
  push AF
  push BC
  push DE
  push HL
  ld ($C000 + SP_AD), SP

  ld B, 0
  ld C, (IX)
  ld HL, sysCallTable
  add HL, BC
  jp (HL)
sysCallTable:
  jr sysCallShutdown
  jr sysCallSpawn
  jr sysCallKill
  jr sysCallGetPID
  jr sysCallSetPaneBuffer
  jr sysCallDrawText

sysCallShutdown:
  jp Shutdown

sysCallSpawn:
  in A, ($05)
  ld B, A
  ld A, $00
  out ($05), A
  ld SP, ($C000 + SP_AD)
  push BC
  ld H, (IX+1)
  push IX
  call SpawnProcess
  pop IX
  pop BC
  ld A, B
  ld ($C000 + SP_AD), SP
  out ($05), A
  ld D, (IX+2)
  ld E, (IX+3)
  ld IY, $0000
  add IY, DE
  ld (IY), L
  jr endSysCall

sysCallKill:
  ld C, (IX+1)
  ld A, $00
  out ($05), A
  ld SP, ($C000 + SP_AD)
  jp KillProcess

; UNTESTED
sysCallGetPID:
  call GetPID
  ld D, (IX+1)
  ld E, (IX+2)
  ld IY, $0000
  add IY, DE
  ld (IY), L
  jr endSysCall

sysCallSetPaneBuffer:
  ld L, (IX+1)
  ld H, (IX+2)
  call SetPaneBuffer
  jr endSysCall

sysCallDrawText:
  ld C, (IX+1)
  ld B, (IX+2)
  ld IY, $0000
  add IY, BC
  call DrawText
  jr endSysCall

endSysCall:
  ld SP, ($C000 + SP_AD)
  pop HL
  pop DE
  pop BC
  pop AF
  exx
  ex AF, AF'
  pop IY
  pop IX
  pop HL
  pop DE
  pop BC
  pop AF
  ei
  ret
