; OS Header
; Provides metadata and RSTs for the OS

; $0000
; Standard KnightOS-compliant header
	; RST $00
	jp Boot
	; Magic Number
	; $0003
	.db "SK"
	; $0005
	.db $00 ; Major Version
	.db $00 ; Minor Version
	; $0007
	; Build Type
	; Bits 0-2 determine model
	; Bit 3 is set on DEBUG builds
	; Bit 4 is set on USB models only
	; Bit 5 is set on 15 MHz models only
	; Bits 6-7 are unused


	.db %00110100

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
