# GTXL
GTXL - CPU design with inspiration from the Gigatron

This is the second CPU that I am attempting that is inspired by the Gigatron.  The first design added a keyboard, audio in, and a cartridge slot.  I plan on incorporating those elements, but this time it will not be software compatible due to extra changes.

The Gigatron was a great project, but it had some things I didn't like.  It was more of a console than a computer (with the extra plug-in for the keyboard).  I'd like to make it more of a computer.  So this means a few changes:
1. It needs a vonNeumann architecture.  The original Gigatron got around this by having a virtual computer running on it.  I feel like that makes the ROM more like a microcode than a traditional computer.  So that means the the program counter must be able to access all of the ROM and RAM to be able to execute programs from either location.  It also means a slowdown of the accessing.  Now it will require 3 memory accesses per instruction - 1 to fetch the instruction, 1 to fetch the immediate data, and 1 to execute.  This should be possible with the new 15ns RAM.
2. The most difficult part of programming the Gigatron is keeping time for the video.  It must be manually tracked to make sure the video is drawn at the right time.  This is super annoying.  Instead, I'm going to add an interrupt alongside a timer.  Then when the timer goes off, it interrupts the processor, jumps to the drawing routine, and then returns.  This is fairly tricky and will probably take quite a few extra chips to implement.  However, the best part of making these projects is to make them fun to use.  I think this will make it much more fun to program.
3. I'd like to change from VGA to a digital output.  VGA is dead.  Plus it's analog.  I'm really digging the new [Lumacode](https://github.com/c0pperdragon/LumaCode) format - it uses a single wire to transmit data, it's digital, it's compatible with composite, and it handles many resolutions.  And I'd just like to try it out.  If I don't like it, I can always switch back to VGA.  Or maybe I could have support for both.

# State machine
    vonNeumann architecture needs state machine to access memory
      state 1: fetch instruction
      state 2: fetch immediate data
      state 3: execute
      we need program counter on memory address MUX


# Video notes

    Redesign gigatron into output with lumacode instead of VGA
      lumacode encoded in composite - 63.5us per line, 525 lines
      this can be configurable in the lumacode receiver to be either:
        160 pixels per row with 8-bit color
        320 pixels per row with 4-bit color
      for design, use 160 pixels per line (200 with blanking) and 8-bit per pixel
      160 pixels per row + 40 for blanking, 6 color bits per pixel with 1 for sync
      63.5us / 200 = 317.5ns per pixel
      Need to send 3 sets of color for 6-bit color, so divide that clock by 3
      Need a subpixel clock of 105.83ns or 9.631 MHz
      Need to do three memory accesses per pixel:
        two for fetching a instruction and then constant
        one for fetching a pixel
        This enables a vonNeumann architecture

    For a 55ns memory, need to setup the address within 105.83-55=50.83ns max delay
      Assuming we enable write on second half of clock only
      Back porch is 1.5 us, or 5 clocks, but I will add 5 extra (active drawing is normally 165 clocks)
        Horizontal blanking is 4.7us or 15 clocks
        Front porch is also 4.7us or 15 clocks
      For every line, we have 200 instructions we can execute during active lines
        160 instructions must be for copying RAM to video output
        40 instructions for all other handling:
      Storing and restoring AC and Y
        check if reset
        Load line address
        branch to one of four routines - the last will increment Y.  
          each will bump branch address to next routine.
        turn on and off the horizontal sync at the right time
        check if we can switch to blank lines
        return from interrupt
        optionally: we can service the audio output

    It might be possible to do VGA at the same time with only a software change
        VGA is 31.777us per line.  Almost exactly twice as fast as composite.
        still does 160 active pixels, 200 pixels total per line
        Maybe have a clock switch?
        Lumacode would need some kind of analog mux, but VGA would not.  
            could save a chip with just VGA if I can get it work that fast
        105.83ns/2 = 52.91ns  Seems maybe too fast even with 15ns SRAM.
        need to do a timing calculation once design is firmed up

# Memory access modes
     I need to change the memory access modes now that everything is on the same address/data bus.  
     The program counter needs to set the address, so it must be included in the address MUX.  
     I need to have [0,0] for the interrupt vector.  Reset will now be an interrupt.  That means ROM must be at $0000.  
     Zero page variables need to be in RAM somewhere.  I could choose the zero page of the RAM which is $8000 for the bus.  
       So the upper RAM address must be $80 or 0b10000000.  
       The easiest way is to tri-state the Y bus and have only one pull-up and the others pull-downs.
       Alternately I could pull all of them up and have the "zero" page the FF page, but I like that less.
     Address MUX:
       Low byte - PC or X or 0 or D
       High byte - PC or Y or 0 or 80

1. [PCH, PCL] - program counter high and low to fetch instructions and immediate data
2. [0,0] - interrupt vector.  This was the reset vector, but it isn't unusual to treat the reset as an interrupt.
3. [Y,X] - for acccessing any memory location
4. [80, X] - instead of having zero page variables, we must access RAM instead.  So the Y bus must be tristated, and then have pull-ups.
5. [80, D] - zero page immediate access - it was just too valuable to leave out the immediate access modes
6. [Y,D] - non-zero page immediate access


# Memory map
- $0000-$3FFF ROM
- $4000-$7FFF Periperals, I/O, Audio
  - $4000-$4FFF Audio
  - $5000-$5FFF Keyboard / Controller
  - $6000-$6FFF Expansion slot 1
  - $7000-$7FFF Expansion slot 2
- $8000-$FFFF RAM

Need an address decoder for the ROM area to split the peripherals off.  Expansion slots will be for any bus access.  Maybe disk I/O.

# Timers
     Decided to try to use the X register for the timer.
       Tie it to continuously run, but still be loadable.
       Effectively lose the [Y,X] memory access mode except for video output.
       But we could use [Y,D] instead.  If we really need to, we could run in RAM, and self-modify the D value (naughty).
       The terminal count on the X will drive the interrupt line
       
# Interrupt
- Add a way to save and restore registers
  - Y, AC, PC
  - PC - simplest is to have a second register to hold the address.  It may take as many chips to be able to store the PC into RAM instead.
  - Since X is causing the interrupt, we'll know what that is.
  - Y cannot be read easily.  If the input register is moved to the memory map, then I can replace the IN data access mode with Y.
  - No need to store the VID register.  The whole point is to modify it...
- A way to load the PC with the interrupt vector
  - I plan to use the reset pin on the counters.  Then treat the reset as an interrupt.  I have to do a check to see if it's a cold boot, and if not start the video output.
- Add an instruction to return from interrupt (RETI)
  - Looking at what will take the fewest extra chips, I think the jmp (Y,Y) instruction is fairly useless, so I'll use that instead.
- A way to load the program counter with the return vector
  - Need to MUX the input to the PC with the databus and Y vectors.  Can use the output enables for the databus, but need to add an output enable on the Y register.
  - The Y register can be replaced with one that has an output enable.
  - I'll need to add an extra buffer chip so I can also drive Y to the databus.


# Interrupt handler
     first store registers to memory (assume not a cold boot)
     next load X counter to ensure timing - time sensitive
     next determine type of interrupt - cold boot or timer.
       have a variable stored in specific location to determine if cold boot (BOOTCNT)
       The only problem is that there's a 1 in 256 chance it will boot with this value in ram already
       could go to two variables bringing random chance to 1 in 64k or three for 1 in 16M
     
     so read BOOTCNT.  If it is NOT 0x55 (arbitrary) then it's a cold boot - branch to boot code
     cold boot:
       write 0x55 to BOOTCNT.  future interrupts will now be handled by video handler.
     continue with booting (setting up variables, etc)
     do not return from interrupt after this

     it's possible to simulate a cold boot then by clearing BOOTCNT and waiting for interrupt.
     interesting that real resets won't actually reset the computer then.  only software reboots.
     maybe tie a reset button into the power system instead  . (series push button with power).
    
# Fibonachi Benchmark program?
      fibonachi - n+1 = n + n-1
      n-1 is at 0x8010
      n is at 0x8011
      n+1 is at 0x8012
    init:
      load 0 to n-1
      load 1 to n
    start loop:
      load n-1 (0x8010) to AC
      add n (0x8011) to AC (now contains n+1)
      st AC to 0x8012
      load n (0x8011) to AC
      st AC to n-1 (0x8010)
      load n+1 (0x8012) to AC
      st AC to n (0x8011)
      ld AC to VID
      bra start loop
    
