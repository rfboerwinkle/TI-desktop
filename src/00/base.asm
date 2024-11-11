; OS Base
; Contains no executable code, but rather, this includes other code.

; Needed defines, feel free to change these
clip_mask				.equ $8000 ; one byte of free RAM
FlashExecutableRAM		.equ $8000 ; Flash code is loaded here for execution
FlashExecutableRAMSize	.equ 100   ; This is the amount of space you leave for flash RAM (KnightOS uses this RAM for other stuff, so it's really like temp RAM)
SwapSector				.equ $78

; Boot up and special sections
#include "header.asm"
#include "boot.asm"
#include "interrupt.asm"
#include "flash.asm"
#include "util.asm"
#include "display.asm"
#include "keyboard.asm"
