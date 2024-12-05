# Building

You should run `assemble.sh` and then `pack.sh` and then you should have a `trial.8xu` (assuming your file tree is exactly the same as mine lol).

I know it's really messy, at least it works.

To put the calculator into boot mode:
1) Remove 1 AAA battery
2) Hold the [DEL] key
3) Re-insert the AAA battery while continuing to hold [DEL]
(from https://www.cemetech.net/forum/viewtopic.php?t=11390&start=0)

# Usage Guide

 - Run TilEm: `tilem2 --rom=custom-files/TI84PSE_v253_custom.rom --normal-speed --skin=custom-files/ti84p.skn`

 - Select 'TI-84 Plus Silver Edition'

 - Right click on the calculator and select "Send File..."

 - select your 8XU

 - when the file finishes uploading, it should boot into ti-desktop

 - to start a process (say, the process loaded to page $06) press the key sequence:

 - ALPHA (switches to numeric mode)

 - 0 (inputs a 0)

 - 6 (inputs a 6)

 - 2ND (starts the process)

 - That process was started as PID 1. To view it, press the key sequence:

 - 1 (inputs a 1)

 - MODE (puts the process on the currently selected pane (left pane))

 - Then, to kill it:

 - 1 (inputs a 1)

 - DEL (kills the process)

 - Congrats! More details are in the report.

# User Program Guide

You should have ".org $4000" at the beginning of every program. Your code space will always be $4000-$7FFF. Your memory space will always be $C000-$FFFF. These are in the same address space. Addresses $0000-3FFF are reserved for the operating system. It should not be jumped to except through the use of "rst $08" (for system calls). Addresses $8000-$BFFF can be used to open files.

You should keep at least 22 bytes open at the top of your stack at all times for storing CPU state when an interrupt occurs (plus some more for syscalls, if you use them). Never overwrite the final 2 bytes of memory - lest your program develop a race condition!!
