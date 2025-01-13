# GTXL
GTXL - CPU design with inspiration from the Gigatron

This is the second CPU that I am attempting that is inspired by the Gigatron.  The first design added a keyboard, audio in, and a cartridge slot.  I plan on incorporating those elements, but this time it will not be software compatible due to extra changes.

The Gigatron was a great project, but it had some things I didn't like.  It was more of a console than a computer (with the extra plug-in for the keyboard).  I'd like to make it more of a computer.  So this means a few changes:
1. It needs a vonNeumann architecture.  The original Gigatron got around this by having a virtual computer running on it.  I feel like that makes the ROM more like a microcode than a traditional computer.  So that means the the program counter must be able to access all of the ROM and RAM to be able to execute programs from either location.  It also means a slowdown of the accessing.  Now it will require 3 memory accesses per instruction - 1 to fetch the instruction, 1 to fetch the immediate data, and 1 to execute.  This should be possible with the new 15ns RAM.
2. The most difficult part of programming the Gigatron is keeping time for the video.  It must be manually tracked to make sure the video is drawn at the right time.  This is super annoying.  Instead, I'm going to add an interrupt alongside a timer.  Then when the timer goes off, it interrupts the processor, jumps to the drawing routine, and then returns.  This is fairly tricky and will probably take quite a few extra chips to implement.  However, the best part of making these projects is to make them fun to use.  I think this will make it much more fun to program.
3. I'd like to change from VGA to a digital output.  VGA is dead.  Plus it's analog.  I'm really digging the new [Lumacode](https://github.com/c0pperdragon/LumaCode) format - it uses a single wire to transmit data, it's digital, it's compatible with composite, and it handles many resolutions.  And I'd just like to try it out.  If I don't like it, I can always switch back to VGA.  Or maybe I could have support for both.

# Memory access modes
I need to change the memory access modes now that everything is on the same address/data bus.  The program counter needs to set the address, so it must be included in the address MUX.  Unless I want to add more chips, I have to cut something.  I need both Y and X to do fast memory access for the video, so I'm going to drop the D access to memory.  This is probably the biggest drawback, but ultimately D can be moved to X, so instructions like LD [$dd] will be split into two instructions: LD $dd, x and LD [X]
1. [PCH, PCL] - program counter high and low to fetch instructions and immediate data
2. [0,0] - interrupt vector.  This was the reset vector, but it isn't unusual to treat the reset as an interrupt.
3. [Y,X] - for acccessing any memory location
4. [80, X] - instead of having zero page variables, we must access RAM instead.  So the Y bus must be tristated, and then have pull-ups.
5. [80,D] - zero page immediate access - it was just to valuable to leave out
6. [Y,D] - non-zero page immediate access

# Memory map
  - $0000-$3FFF ROM
  - $4000-$7FFF Periperals, I/O, Audio
  - $8000-$FFFF RAM

I haven't decided how to divide up the Peripherals section of memory, but I think it will be the simplest way.  I figure the ROM will only need to be 16k at most leaving room for other things.  I'd like to have expansion ports similar to the Apple 2 mapped to specific memory locations.

# Interrupt
TODOs:
1. Add a way to save and restore all registers
  -  X,Y,D,AC,PC
  -  D, AC can be stored directly to RAM
  -  PC - simplest is to have a second register to hold the address.  It may take as many chips to be able to store the PC into RAM instead.
  -  Y cannot be read easily.  I may have to add a way to write Y back to the databus.
  -  X can be read indirectly with [Y,X] read.  Have a page in ROM where the data is the same as the address.  Reading here will return the X value then.
2. A way to load the PC with the interrupt vector
  - I plan to use the reset on the PC.  Then treat the reset as an interrupt.  I may have to do a check to see if it's a cold boot, and if not start the video output.
3. Add an instruction to return from interrupt (RETI)
  - Could use a redundant NOP or maybe an unused jump instruction
4. A way to load the program counter with the return vector
  - Need to MUX the input to the PC with the databus and Y vectors.  Can use the output enables for the databus, but need to add an output enable on the Y register.

# Timers
  - Add a timer which will countdown for each video line.  2-3 counter chips?
  - Could have it automatically restart after the interrupt, but it would need to be fixed to a specific timing then.
  - It would be nice to have it manually set so it could be used for other things.  So maybe have it loadable by software.  As long as that timing is tightly controlled in the interrupt routine.
  
  
