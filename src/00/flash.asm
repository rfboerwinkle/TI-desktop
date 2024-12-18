; OS Flash Control Routines
; These routines are used to manipulate flash.

; Inputs:    A: Value to write
;            HL: Address to write to
; Outputs:   None
; Comments:  Flash must be unlocked
WriteFlashByte:
  push bc
  ld b, a
  push af
  ld a, i
  push af
  di
  ld a, b

  push hl
  push de
  push bc
    push hl
    push de
    push bc
      ld hl, WriteFlashByte_RAM
      ld de, FLASH_EXECUTABLE_RAM
      ld bc, WriteFlashByte_RAM_End - WriteFlashByte_RAM
      ldir
    pop bc
    pop de
    pop hl
    call FLASH_EXECUTABLE_RAM
  pop bc
  pop de
  pop hl

  pop af
  jp po, _
  ei
_:
  pop af
  pop bc
  ret

; Flash operations must be done from RAM
WriteFlashByte_RAM:
  and (hl) ; Ensure that no bits are set
  ld b, a
    ld a, $AA
    ld ($0AAA), a  ; Unlock
    ld a, $55
    ld ($0555), a  ; Unlock
    ld a, $A0
    ld ($0AAA), a  ; Write command
  ld (hl), b       ; Data

  ; Wait for chip
_:
  ld a, b
  xor (hl)
  bit 7, a
  jr z, WriteFlashByte_Done
  bit 5, (hl)
  jr z, -_
  ; Error, abort
WriteFlashByte_Done:
  ld (hl), $F0
  ret
WriteFlashByte_RAM_End:

; Inputs:    DE: Address to write to
;            HL: Address to read from (must be in RAM)
;            BC: Size of data to be written
; Outputs:   None
; Comments:  Flash must be unlocked
WriteFlashBuffer:
  push af
  ld a, i
  push af
  di

  push hl
  push de
  push bc
    push hl
    push de
    push bc
      ld hl, WriteFlashBuffer_RAM
      ld de, FLASH_EXECUTABLE_RAM
      ld bc, WriteFlashBuffer_RAM_End - WriteFlashBuffer_RAM
      ldir
    pop bc
    pop de
    pop hl
    call FLASH_EXECUTABLE_RAM
  pop bc
  pop de
  pop hl

  pop af
  jp po, _
  ei
_:
  pop af
  ret

WriteFlashBuffer_RAM:
WriteFlashBuffer_Loop:
  ld a, $AA
  ld ($0AAA), a  ; Unlock
  ld a, $55
  ld ($0555), a  ; Unlock
  ld a, $A0
  ld ($0AAA), a  ; Write command
  ld a, (hl)
  ld (de), a     ; Data

  inc de
  dec bc

_:
  xor (hl)
  bit 7, a
  jr z, _
  bit 5, a
  jr z, -_
  ; Error, abort
  ld a, $F0
  ld (0), a
  ret
_:
  inc hl
  ld a, b
  or a
  jr nz, WriteFlashBuffer_Loop
  ld a, c
  or a
  jr nz, WriteFlashBuffer_Loop
  ret
WriteFlashBuffer_RAM_End:

; Inputs:    A: Any page within the sector to be erased
; Outputs:   None
; Comments:  Flash must be unlocked
EraseFlashSector:
  push bc
  ld b, a
  push af
  ld a, i
  ld a, i
  push af
  di
  ld a, b

  push hl
  push de
  push bc
    push hl
    push de
    push bc
      ld hl, EraseFlashSector_RAM
      ld de, FLASH_EXECUTABLE_RAM
      ld bc, EraseFlashSector_RAM_End - EraseFlashSector_RAM
      ldir
    pop bc
    pop de
    pop hl
    call FLASH_EXECUTABLE_RAM
  pop bc
  pop de
  pop hl

  pop af
  jp po, _
  ei
_:
  pop af
  pop bc
  ret

EraseFlashSector_RAM:
  out (6), a
  ld a, $AA
  ld ($0AAA), a ; Unlock
  ld a, $55
  ld ($0555), a ; Unlock
  ld a, $80
  ld ($0AAA), a ; Write command
  ld a, $AA
  ld ($0AAA), a ; Unlock
  ld a, $55
  ld ($0555), a ; Unlock
  ld a, $30
  ld ($4000), a ; Erase
  ; Wait for chip

_:
  ld a, ($4000)
  bit 7, a
  ret nz
  bit 5, a
  jr z, -_

  ; Error, abort
  ld a, $F0
  ld ($4000), a
  ret
EraseFlashSector_RAM_End:

; Inputs:  A: Page to erase
; Erases a single flash page
EraseFlashPage:
  push af
  push bc
    push af
      call CopySectorToSwap
    pop af
    push af
      call EraseFlashSector
    pop af

    ld c, a
    and %11111100
    ld b, SWAP_SECTOR

_:
    cp c
    jr z, _
    call CopyFlashPage
_:
    inc b
    inc a
    push af
    ld a, b
    and %11111100
    or a
    jr z, _
    pop af
    jr --_
_:
    pop af

  pop bc
  pop af
  ret

EraseFlashPage_RAM:

; Inputs:    A: Any page within the sector to be copied
; Outputs:   None
; Comments:  Flash must be unlocked
CopySectorToSwap:
  push af
  ld a, SWAP_SECTOR
  call EraseFlashSector
  pop af

  push bc
  ld b, a
  push af
  ld a, i
  ld a, i
  push af
  di
  ld a, b

  and %11111100 ; Get the sector for the specified page

  push hl
  push de
    ld hl, CopySectorToSwap_RAM

  push af
    ld a, 1
    out (5), a

    ld de, FLASH_EXECUTABLE_RAM + $4000 ; By rearranging memory, we can make the routine perform better
    ld bc, CopySectorToSwap_RAM_End - CopySectorToSwap_RAM
    ldir
  pop af

  ld hl, $4000
  add hl, sp
  ld sp, hl
  call FLASH_EXECUTABLE_RAM + $4000
  xor a
  out (5), a ; Restore correct memory mapping
  ld hl, 0
  add hl, sp
  ld bc, $4000
  or a
  sbc hl, bc
  ld sp, hl

  pop de
  pop hl

  pop af

  jp po, _
  ei
_:
  pop af

  pop bc
  ret

CopySectorToSwap_RAM:
  out (7), a
  ld a, SWAP_SECTOR
  out (6), a

CopySectorToSwap_PreLoop:
  ld hl, $8000
  ld de, $4000
  ld bc, $4000
CopySectorToSwap_Loop:
  ld a, $AA
  ld ($0AAA), a ; Unlock
  ld a, $55
  ld ($0555), a ; Unlock
  ld a, $A0
  ld ($0AAA), a ; Write command
  ld a, (hl)
  ld (de), a    ; Data
  inc de
  dec bc

_:
  xor (hl)
  bit 7, a
  jr z, _
  bit 5, a
  jr z, -_
  ; Error, abort
  ld a, $F0
  ld (0), a
  ld a, $81
  out (7), a
  ret
_:
  inc hl
  ld a, b
  or a
  jr nz, CopySectorToSwap_Loop
  ld a, c
  or a
  jr nz, CopySectorToSwap_Loop

  in a, (7)
  inc a
  out (7), a

  in a, (6)
  inc a
  out (6), a
  and %00000011
  or a
  jr nz, CopySectorToSwap_PreLoop

  ld a, $81
  out (7), a
  ret
CopySectorToSwap_RAM_End:

; Brief: Copies the contents of one page to another.  The destination should be cleared to $FF first.
; Input:   A: Destination page
;           B: Source page
; Output:  None
CopyFlashPage:
  push de
  ld d, a
  push af
  ld a, i
  ld a, i
  push af
  di
  ld a, d

  push hl
  push de
    push af
    push bc
    ld hl, CopyFlashPage_RAM

      ld a, 1
      out (5), a

      ld de, FLASH_EXECUTABLE_RAM + $4000 ; By rearranging memory, we can make the routine perform better
      ld bc, CopyFlashPage_RAM_End - CopyFlashPage_RAM
      ldir

    pop bc
    pop af

    ld hl, $4000
    add hl, sp
    ld sp, hl
    call FLASH_EXECUTABLE_RAM + $4000
    xor a
    out (5), a ; Restore correct memory mapping
    ld hl, 0
    add hl, sp
    ld bc, $4000
    or a
    sbc hl, bc
    ld sp, hl

  pop de
  pop hl

  pop bc
  pop af
  jp po, _
  ei
_:
  pop af
  ret

CopyFlashPage_RAM:
  out (6), a ; Destination
  ld a, b
  out (7), a ; Source

CopyFlashPage_PreLoop:
  ld hl, $8000
  ld de, $4000
  ld bc, $4000
CopyFlashPage_Loop:
  ld a, $AA
  ld ($0AAA), a ; Unlock
  ld a, $55
  ld ($0555), a ; Unlock
  ld a, $A0
  ld ($0AAA), a ; Write command
  ld a, (hl)
  ld (de), a    ; Data
  inc de
  dec bc

_:
  xor (hl)
  bit 7, a
  jr z, _
  bit 5, a
  jr z, -_
  ; Error, abort
  ld a, $F0
  ld (0), a
  ld a, $81
  out (7), a
  ret
_:
  inc hl
  ld a, b
  or a
  jr nz, CopyFlashPage_Loop
  ld a, c
  or a
  jr nz, CopyFlashPage_Loop

  ld a, $81
  out (7), a
  ret
CopyFlashPage_RAM_End:
