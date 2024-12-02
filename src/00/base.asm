; This is the main file that gets assembled

; one byte of free RAM
CLIP_MASK .equ $8000
; Flash code is loaded here for execution
FLASH_EXECUTABLE_RAM .equ $8000
; This is the amount of space you leave for flash RAM (KnightOS uses this RAM for other stuff, so it's really like temp RAM)
FLASH_EXECUTABLE_RAM_SIZE .equ 100
SWAP_SECTOR .equ $78
; Size of each PCB.
PCB_SIZE .equ $05 ; this needs hand-changes
PCB_TABLE_AD .equ $0008
SP_LOADING_AD .equ $0030
PID_LEFT_PANE_AD .equ $0032
PID_RIGHT_PANE_AD .equ $0033
PANE_FLAG_AD .equ $0034
KERNEL_PANE_AD .equ $0035

; Boot up and special sections
#include "header.asm"
#include "boot.asm"
#include "syscalls.asm"
#include "interrupt.asm"
#include "flash.asm"
#include "util.asm"
#include "display.asm"
#include "keyboard.asm"
#include "process.asm"
