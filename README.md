# GTXL
GTXL - CPU design with inspiration from the Gigatron

This is the second CPU that I am attempting that is inspired by the Gigatron.  The first design added a keyboard, audio in, and a cartridge slot.  I plan on incorporating those elements, but this time it will not be software compatible due to extra changes.

The Gigatron was a great project, but it had some things I didn't like.  It was more of a console than a computer (with the extra plug-in for the keyboard).  I'd like to make it more of a computer.  So this means a few changes:
1. It needs a vonNeumann architecture.  The original Gigatron got around this by having a virtual computer running on it.  I feel like that makes the ROM more like a microcode than a traditional computer.  So that means the the program counter must be able to access all of the ROM and RAM to be able to execute programs from either location.  It also means a slowdown of the accessing.  Now it will require 3 memory accesses per instruction - 1 to fetch the instruction, 1 to fetch the immediate data, and 1 to execute.  This should be possible with the new 15ns RAM.
2. The most difficult part of programming the Gigatron is keeping time for the video.  It must be manually tracked to make sure the video is drawn at the right time.  This is super annoying.  Instead, I'm going to add an interrupt alongside a timer.  Then when the timer goes off, it interrupts the processor, jumps to the drawing routine, and then returns.  This is fairly tricky and will probably take quite a few extra chips to implement.  However, the best part of making these projects is to make them fun to use.  I think this will make it much more fun to program.
3. I'd like to change from VGA to a digital output.  VGA is dead.  Plus it's analog.  I'm really digging the new [Lumacode](https://github.com/c0pperdragon/LumaCode) format - it uses a single wire to transmit data, it's digital, it's compatible with composite, and it handles many resolutions.  And I'd just like to try it out.  If I don't like it, I can always switch back to VGA.  Or maybe I could have support for both.

# Video notes

- Redesign gigatron into output with lumacode instead of VGA
 - lumacode encoded in composite - 63.5us per line, 525 lines
 - this can be configurable in the lumacode receiver to be either:
  - 160 pixels per row with 8-bit color
  - 320 pixels per row with 4-bit color
 - for design, use 160 pixels per line (200 with blanking) and 8-bit per pixel
 - 160 pixels per row + 40 for blanking, 6 color bits per pixel with 1 for sync
 - 63.5us / 200 = 317.5ns per pixel
 - Need to send 3 sets of color for 6-bit color, so divide that clock by 3
 - Need a subpixel clock of 105.83ns or 9.631 MHz
 - Need to do three memory accesses per pixel:
        - two for fetching a instruction and then constant
        - one for fetching a pixel
        - This enables a vonNeumann architecture
    - For a 55ns memory, need to setup the address within 105.83-55=50.83ns max delay
        - Assuming we enable write on second half of clock only
    - Back porch is 1.5 us, or 5 clocks, but I will add 5 extra (active drawing is normally 165 clocks)
    - Horizontal blanking is 4.7us or 15 clocks
    - Front porch is also 4.7us or 15 clocks
    - For every line, we have 200 instructions we can execute during active lines
        - 160 instructions must be for copying RAM to video output
        - 40 instructions for all other handling:
            - Storing and restoring AC and Y
            - check if reset
            - Load line address
            - branch to one of four routines - the last will increment Y.  
                - each will bump branch address to next routine.
            - turn on and off the horizontal sync at the right time
            - check if we can switch to blank lines
            - return from interrupt
            - optionally: we can service the audio output

    It might be possible to do VGA at the same time with only a software change
        VGA is 31.777us per line.  Almost exactly twice as fast as composite.
        still does 160 active pixels, 200 pixels total per line
        Maybe have a clock switch?
        Lumacode would need some kind of analog mux, but VGA would not.  
            could save a chip with just VGA if I can get it work that fast
        105.83ns/2 = 52.91ns  Seems maybe too fast even with 15ns SRAM.
        need to do a timing calculation once design is firmed up


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
  - $4000-$4FFF Audio
  - $5000-$5FFF Keyboard / Controller
  - $6000-$6FFF Expansion slot 1
  - $7000-$7FFF Expansion slot 2
- $8000-$FFFF RAM

Expansion slots will be for any bus access.  Maybe improved audio or better disk I/O.

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
  
  
        
vonNeumann architecture needs state machine to access memory
    state 1: fetch instruction
    state 2: fetch immediate data
    state 3: execute
    we need program counter on memory address MUX
    
Address MUX:
    Low byte - PC or X or 0
    High byte - PC or Y or 0 or 80
    [PC, PC] - for fetching instructions
    [Y,  X] - for fast video output
    [0,  0] - for interrupt vector
    [80, X] - zero page RAM addressing - this should point to RAM - use instead of zero page variables
    [80, 0] - zero page RAM, location zero 
    Y can be tristated, but add pull-ups to get the 80 for zero RAM page addresssing
    Lose immediate memory addressing.  Must write immediate to X and then access.
    No change to number of chips in memory address unit page
    jumps must have Y enabled, so no jumps to Y,[80,X]

Need an address decoder approach and memory map
    ROM needs to be at 0x0000 for the reset vector
    ROM should be either 8k or 16k
    Peripherals,timer,I/O from $4000-$7FFF
    RAM starts at $8000-$FFFF

Instruction Decoder
    IR7,6,5 decode ALU operation same as original gigatron
    IR4,3,2 decode memory source and ALU destination
        000- [80,X]   , AC
        001- [ Y,X]   , AC
        010- [80,00]  , AC *needed to restore AC after interrupt
        011- [80,X]   , X  *needed to restore X after interrupt
        100- [80,X]   , Y
        101- [ Y,00]  , Y  *needed to restore Y after interrupt
        110- [80,X]   , VID
        111- [ Y,X++] , VID
    IR1,0   decode databus driver
        00- Immediate register
        01- Memory bus
        10- Accumulator
        11- Y register
    When SToring to memory, if X or Y mode is chosen, then it will also copy AC to X or Y.

Interrupt
    Add a way to save and restore all internal registers
        X, Y, AC, PC
        VID register is not stored (the purpose is to update the VID register)
        Add register to store PC (74HCT573)
        Need a FF to hold state interrupt state - interrupts enable/disabled
            Interrupt disables, return instruction enables
        AC can be read directly
        X can be read indirectly if Y is already stored.  Could have a ROM page with each data byte equal to the address.
            Set the Y register to that ROM page and reading [Y,X] will give X
        Y cannot be read easily.  May have to add a way to put Y on the databus.
            Can't store Y straight to memory because we have to use Y to specify an address.  (Can't store Y to [80,00] because Y would need to be disabled.)
            Saving register procedure:
            Store AC to memory at [80,00].
            Then move Y to AC.
            Move immediate to Y (perhaps 0x81)
            Then store AC (which holds Y) to [Y,0] [81,00] in this case
            Then load immediate to Y with ROM lookup table page (say 0x7F).  
            Then load [Y,X] (here [7F,X]) to AC which will now hold X.
            Then store AC to any other memory location.  (ld 05,x then st [80,x]?)
            AC is in [80,00],  Y is in [81,00],  X is in [80,05].
            
            Restoring register procedure:
            Load Y with 81
            Load Y with [Y,00]   (Y is restored)
            Load X with 05
            Load X with [80,X]   (X is restored)
            Load AC with [80,00] (AC is restored)
            This means we must have memory operations for [80,00] and [Y,0]

            If [80,D] memory addressing mode is available, then saving is:
            Store AC to memory at [80,D]
            Store Y to memory at [80,D]
            Load Y with ROM lookup table page (7F for example)
            Load [Y,X] to AC
            Store AC to [80,D]
            AC,Y,X are in any [80,D] locations

            Restoring is:
            Load Y with [80,D]
            Load X with [80,D]
            Load AC with [80,D]
            [80,00], [Y,0], [80,X]  is not needed then

            -- just like the original gigatron, but zero page is page 0x80
            000- [80,D]   , AC
            001- [80,X]   , AC
            010- [ Y,D]   , AC
            011- [ Y,X]   , AC 
            100- [80,D]   , X
            101- [80,D]   , Y
            110- [80,D]   , VID
            111- [ Y,X++] , VID
            Memory modes [PC, PC] and [0,0] are also needed, but not available to instructions

            
    Add a way to load the program counter with the interrupt vector
        Use the reset line - always have interrupt vector at 0x0000
        add software detection to determine the difference
    Add an instruction to return from the interrupt vector (reti)
        Could use a redundant NOP - don't want it to do anything else - 0x0002 (ld ac,ac), 
        or STore to and from memory instruction
        maybe replace a jump instruction
    Add a way to load the program counter with the return vector
        Need to MUX the input to the PC with the Y and databus registers
            Can use the output enable on Y and databus to disable those
            the ld ac,ac instruction disables those by default, so no extra logic is needed
        the PL,PH signals load the PC - need to pull both low during the reti instruction
        
Timer   
    Add a timer which will generate an interrupt on finishing
        2-3 counter chips?
    Add a way to reset it / load it
        can stop the counting on terminal count.
        return from interrupt could restart it.
        OR just have it reload/reset as soon as it reaches terminal count
            (as long as the interrupt is caught)
        
Pipelining?
    PC, IR, D, WE operate on first clock
    AC, X, Y, OUT operate on second clock

Interrupt handler
    cpu start with interrupts disabled.  must return from interrupt to enable it.
    first store registers to memory (assume not a cold boot)
    next load counter to ensure timing - time sensitive!!
    next determine type of interrupt - cold boot or timer.
        have a variable stored in specific location to determine if cold boot (BOOTCNT)
        The only problem is that there's a 1 in 256 chance it will boot with this value in ram already
        could go to two variables bringing random chance to 1 in 64k or three for 1 in 16M
    read BOOTCNT.  If it is 0x55 (arbitrary) then it's a normal interrupt (branch to video handler)
    if it is 0x01 then branch to cold boot vector
    else write 0x01 to BOOTCNT and return from interrupt (should jump back to 0x0000)
      this sets the interrupt enable.  program should branch to cold boot vector after this
    cold boot vector:
      write 0x55 to BOOTCNT.  future interrupts will now be handled by video handler.
    continue with booting (setting up variables, etc)
    do not return from interrupt after this
    
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
    