; OS Header
; Provides RSTs for the OS

; $0000
  ; RST $00
  jp Boot
  .db 0, 0, 0, 0, 0

; $0008
  ; RST $08
  ret
  .db 0, 0, 0, 0, 0, 0, 0

; $0010
  ; RST $10
  ret
  .db 0, 0, 0, 0, 0, 0, 0

; $0018
  ; RST $18
  ret
  .db 0, 0, 0, 0, 0, 0, 0

; $0020
  ; RST $20
  ret
  .db 0, 0, 0, 0, 0, 0, 0

; $0028
  ; RST $28
  ret
  .db 0, 0, 0, 0, 0, 0, 0

; $0030
  ; RST $30
  ret
  .db 0, 0, 0, 0, 0, 0, 0

; $0038
  ; RST $38
  ; SYSTEM INTERRUPT
  jp SysInterrupt

  .db 0, 0, 0, 0, 0, 0
  .db 0, 0, 0, 0, 0, 0
  .db 0, 0, 0, 0, 0, 0
  .db 0, 0, 0, 0, 0, 0
; $0053
  jp Boot
; $0056
  .db $FF, $A5, $FF
