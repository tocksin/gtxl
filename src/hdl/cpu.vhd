/*
-- @file cpu.vhd
-- @brief CPU design of the Gigatron XL
-- @author Justin Davis
--
    Copyright (C) 2024  Justin Davis

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
------------------------------------------------------------------------------*/
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;

library work;           use work.tools_pkg.all;
                        use work.sys_description_pkg.all;

entity cpu is
    port ( iClk     : in    sl;
           iRst     : in    sl;
           
           oVideo   :   out slv(7 downto 0));
end entity cpu;

architecture ttl of cpu is

    signal rstN         : sl;
    signal sysClk       : sl;
    signal wrClk        : sl;
    
    -- State signals
    signal stateN       : slv(7 downto 0);
    signal stateOp      : slv(1 downto 0);
    signal instFetch    : sl;
    signal immFetch     : sl;
    signal execute      : sl;
    
    -- Program counter signals
    signal PCReg        : slv(15 downto 0);
    signal pcClear      : sl;
    signal pcLoadLo     : sl;
    signal pcLoadHi     : sl;
    signal terminal0    : sl;
    signal terminal1    : sl;
    signal terminal2    : sl;
    signal PCHold       : slv(15 downto 0);
    signal retI         : sl;
    
    -- Memory MUX signals
    signal memAddr      : slv(15 downto 0);
    signal bankEn       : slv(7 downto 0);
    signal memDriveEn   : sl;
    signal xMemEn       : sl;
    signal immMemEn     : sl;
    
    -- Instruction/Immediate register signals
    signal instReg      : slv(7 downto 0);
    signal immEn        : sl;
    signal immDriveEn   : sl;
    signal immReg       : slv(7 downto 0);
    
    -- ALU and Accumulator signals
    signal aluOp        : slv(4 downto 0);
    signal aluData      : slv(7 downto 0);
    signal aluCarry     : sl;
    signal acReg        : slv(7 downto 0) := x"00";
    signal acLoad       : sl;
    signal acDriveEn    : sl;

    -- Y regsiter signals
    signal yReg         : slv(7 downto 0) := x"00";
    signal yLoad        : sl;
    signal yDriven      : sl;
    signal yBus         : slv(7 downto 0);
    signal yBusDriveEn  : sl;
    signal yBufDriveEn  : sl;

    -- X register signals
    signal xReg         : slv(7 downto 0) := x"00";
    signal xCount       : sl;
    signal xLoad        : sl;
    signal xTermLo      : sl;
    signal interrupt    : sl;
    
    -- Video register signals
    signal vidLoad      : sl;
    signal vidReg       : slv(7 downto 0) := x"00";
    
    -- Databus signals
    signal dataRom      : slv(7 downto 0);
    signal ramWrN       : sl;
    signal dataRam      : slv(7 downto 0);
    signal dataRamDef   : slv(7 downto 0);
    signal dataBus      : slv(7 downto 0);
    
    -- Peripheral signals
    signal keyArray     : slv(7 downto 0);
    signal audioReg     : slv(7 downto 0);
    
begin

    rstN <= not iRst;
    sysClk <= iClk after 10 ns;
    wrClk <= iClk or sysClk;
    
    ----------------------------------------------------------
    ------          State Machine                      -------
    ----------------------------------------------------------
    -- First state: fetch Instruction
        -- enable PC counting, enable instruction register, set address MUX to PC
    -- Second state: fetch Immediate Data
        -- enable PC counting, enable immediate register, set address MUX to PC
    -- Third state: execute
        -- disable PC counting, set address MUX to instruction execution

    -- stateOp is 11 when loading (only on reset), 01 when shifting LSB to MSB
    stateOp(0) <= '1';
    stateOp(1) <= iRst;
    stateN <= "HHHHHHHL";  -- value that gets loaded at startup

    -- State machine (shifter)
    stateComp : entity work.sn74hct299(rtl)
    port map(clkIn           => sysClk,
             rstNIn          => '1',
             modeSIn         => stateOp,
             serial0In       => stateN(2),
             serial7In       => '0',
             driverEn0NIn    => iRst,  -- outputs off when in reset (loading)
             driverEn1NIn    => iRst,  -- outputs off when in reset (loading)
             dataInOut       => stateN);

    instFetch <= stateN(0);
    immFetch <= stateN(1);
    execute <= stateN(2);
    
    ----------------------------------------------------------
    ------          Program Counter                    -------
    ----------------------------------------------------------
    pcClear <= '0' when (rstN='0') or (((interrupt='1') and (execute='0') and sysClk='0')) else '1';

    pc0: entity work.sn74hct161
    port map(   iClk        => sysClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadLo,    -- load PC when we jump or return from interrupt
                iCntEn      => execute,
                iTCntEn     => '1',
                iData       => dataBus(3 downto 0),
                oData       => pcReg(3 downto 0),
                oTerminal   => terminal0);

    pc1: entity work.sn74hct161
    port map(   iClk        => sysClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadLo,
                iCntEn      => execute,
                iTCntEn     => terminal0,
                iData       => dataBus(7 downto 4),
                oData       => pcReg(7 downto 4),
                oTerminal   => terminal1);

    pc2: entity work.sn74hct161
    port map(   iClk        => sysClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadHi,
                iCntEn      => execute,
                iTCntEn     => terminal1,
                iData       => yBus(3 downto 0),
                oData       => pcReg(11 downto 8),
                oTerminal   => terminal2);

    pc3: entity work.sn74hct161
    port map(   iClk        => sysClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadHi,
                iCntEn      => execute,
                iTCntEn     => terminal2,
                iData       => yBus(7 downto 4),
                oData       => pcReg(15 downto 12),
                oTerminal   => open);

    ----------------------------------------------------------
    ------          Memory Address Selector            -------
    ----------------------------------------------------------
    --      Sel    Memory access
    --      0      [ Ybus, Xbus] -- normal memory access
    --      1      [PC,PC] -- fetch
    -- Ybus can be either Y register or 0x80
    -- Xbus can be either X register or D register
    
    mau0 : entity work.sn74hct244 -- tristate buffer
    port map(   iEnAN   => immMemEn,
                iEnBN   => immMemEn,
                iData   => immReg,
                oData   => memAddr(7 downto 0));

    mau1 : entity work.sn74hct244 -- tristate buffer
    port map(   iEnAN   => xMemEn,
                iEnBN   => xMemEn,
                iData   => xReg,
                oData   => memAddr(7 downto 0));

    mau2 : entity work.sn74hct244
    port map(   iEnAN   => (not execute),
                iEnBN   => (not execute),
                iData   => pcReg(7 downto 0),
                oData   => memAddr(7 downto 0));

    memAddr(7 downto 0) <= "LLLLLLLL";

    mau3 : entity work.sn74hct157
    port map(   iA          => To_X01(yBus(3 downto 0)),
                iB          => pcReg(11 downto 8),
                iEnableN    => '0',
                iSelect     => execute,
                oY          => memAddr(11 downto 8));

    mau4 : entity work.sn74hct157
    port map(   iA          => To_X01(yBus(7 downto 4)),
                iB          => pcReg(15 downto 12),
                iEnableN    => '0',
                iSelect     => execute,
                oY          => memAddr(15 downto 12));

    ----------------------------------------------------------
    ------          Memory Address Decoder             -------
    ----------------------------------------------------------
    -- $0000-$3FFF  ROM  (16k)
    -- $4000-$7FFF  Peripherals
    -- $8000-$FFFF  RAM  (32k)

    -- decoder divider addresses into:
    -- $0000-$0FFF ROM
    -- $1000-$1FFF ROM
    -- $2000-$2FFF ROM
    -- $3000-$3FFF ROM
    -- $4000-$4FFF 
    -- $5000-$5FFF I/O - shift register for controller? keyboard?
    -- $6000-$6FFF Expansion 1
    -- $7000-$7FFF Expansion 2
    -- $8000-$FFFF RAM
    memDecoder : entity work.sn74hct138
    port map(   iEn     => '1',
                iEnLo0  => '0',
                iEnLo1  => memAddr(15),
                iA      => memAddr(12),
                iB      => memAddr(13),
                iC      => memAddr(14),
                oY      => bankEn(7 downto 0));     -- active low outputs

    ----------------------------------------------------------
    ------                ROM $0000-$3FFF              -------
    ----------------------------------------------------------
    romComp : entity work.rom_synth
    port map(   iAddr      => memAddr(13 downto 0),
                oData      => dataRom);
                -- CEn => and(bankEn(3 downto 0)) with diode and
                -- OEn => memOn
    dataBus <= dataRom when (and(bankEn(3 downto 0)) = '0') and (memDriveEn='0') else "ZZZZZZZZ";

    ----------------------------------------------------------
    ------                RAM $8000-$FFFF              -------
    ----------------------------------------------------------
    ramComp : entity work.sp_ram_async
    port map(   iWrEnN   => ramWrN,
                iRamEnN  => (not memAddr(15)),
                iAddr   => memAddr(14 downto 0),
                iData   => dataBus,
                oData   => dataRam);
                -- OEn => memOn
    dataRamDef <= "00000000" when dataRam="UUUUUUUU" else dataRam; -- fix for uninitialized RAM behavior
    dataBus <= dataRamDef when (memAddr(15) = '1') and (memDriveEn='0') else "ZZZZZZZZ";

    ----------------------------------------------------------
    ------         Instruction Register                -------
    ----------------------------------------------------------
    instComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => sysClk,
                iLoadN  => instFetch,
                iData   => dataBus,
                oData   => instReg);

    ----------------------------------------------------------
    ------         Instruction Decoder                 -------
    ----------------------------------------------------------
    controlComp: entity work.control
    port map(   iClk        => sysClk,
                iWrClk      => wrClk,
                iInst       => instReg,
                iCarry      => aluCarry,
                iSign       => acReg(7),
                iExecute    => execute,
                iInterrupt  => interrupt,
                oAluOp      => aluOp,
                oXLoad      => xLoad,
                oYLoad      => yLoad,
                oIncX       => xCount,
                oPCLoadLo   => pcLoadLo,
                oPCLoadHi   => pcLoadHi,
                oacLoad     => acLoad,
                oVidLoad    => vidLoad,
                oMemDrive   => memDriveEn,
                oImmDrive   => immDriveEn,
                oAccDrive   => acDriveEn,
                oYBusDrive  => yBusDriveEn,
                oYBufDrive  => yBufDriveEn,
                oXmemEnN    => xMemEn,
                oImmMemEnN  => immMemEn,
                oRamWrN     => ramWrN,
                oRetI       => retI);

    ----------------------------------------------------------
    ------         Immediate Data Register             -------
    ----------------------------------------------------------
    immeComp : entity work.sn74hct377  -- FF with tristate output
    port map(   iClk    => sysClk,
                iLoadN  => immFetch,
                iData   => dataBus,
                oData   => immReg);

    immBufComp : entity work.sn74hct244 -- tristate buffer
    port map(   iEnAN   => immDriveEn,
                iEnBN   => immDriveEn,
                iData   => immReg,
                oData   => dataBus);

    ----------------------------------------------------------
    ------         Arithmetic Logic Unit               -------
    ----------------------------------------------------------
    aluComp : entity work.alu
    port map(   iDataA  => dataBus,
                iDataB  => acReg,
                iOp     => aluOp,
                oData   => aluData,
                oCarry  => aluCarry);

    ----------------------------------------------------------
    ------         Accumulator Register and Buffer     -------
    ----------------------------------------------------------
    accComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => sysClk,
                iLoadN  => acLoad,
                iData   => aluData,
                oData   => acReg);

    accBufComp : entity work.sn74hct244 -- tristate buffer
    port map(   iEnAN   => acDriveEn,
                iEnBN   => acDriveEn,
                iData   => acReg,
                oData   => dataBus);

    ----------------------------------------------------------
    ------        Y Register                           -------
    ----------------------------------------------------------
    yComp : entity work.sn74hct574  -- FF with tristate output
    port map(   iClk    => yLoad,
                iEnN    => yBusDriveEn,
                iData   => aluData,
                oData   => yBus);
    yBus <= "HLLLLLLL"; -- pull ups/downs

    yBufComp : entity work.sn74hct244 -- tristate buffer
    port map(   iEnAN   => yBufDriveEn,
                iEnBN   => yBufDriveEn,
                iData   => yBus,
                oData   => dataBus);

    ----------------------------------------------------------
    ------        X Register                           -------
    ----------------------------------------------------------
    xLoComp: entity work.sn74hct161
    port map(   iClk        => sysClk,
                iRstN       => rstN,
                iLoadN      => xLoad,
                iCntEn      => xCount,
                iTCntEn     => '1',
                iData       => aluData(3 downto 0),
                oData       => xReg(3 downto 0),
                oTerminal   => xTermLo);

    xHiComp: entity work.sn74hct161
    port map(   iClk        => sysClk,
                iRstN       => rstN,
                iLoadN      => xLoad,
                iCntEn      => xCount,
                iTCntEn     => xTermLo,
                iData       => aluData(7 downto 4),
                oData       => xReg(7 downto 4),
                oTerminal   => interrupt);

    ----------------------------------------------------------
    ------        Video Register                       -------
    ----------------------------------------------------------
    vidComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => sysClk,
                iLoadN  => vidLoad,
                iData   => aluData,
                oData   => vidReg);
    
    ----------------------------------------------------------
    ------        Program Counter Hold Register        -------
    ----------------------------------------------------------
    pcHoldHiComp : entity work.sn74hct574  -- FF with tristate output
    port map(   iClk    => interrupt,
                iEnN    => retI,
                iData   => pcReg(15 downto 8),
                oData   => yBus);

    pcHoldLoComp : entity work.sn74hct574  -- FF with tristate output
    port map(   iClk    => interrupt,
                iEnN    => retI,
                iData   => pcReg(7 downto 0),
                oData   => dataBus);

    ----------------------------------------------------------
    ------        Keyboard  $5000-$5FFF                -------
    ----------------------------------------------------------
    -- Address lines 10 downto 0 to keyboard array (11 downto 0 is available)
    --  keyArray 5 downto 0 from keyboard
    --  keyArray 6 from audio input
    --  keyArray 7 from serial port input
    keyArray <= "11111111";
    
    keyBufComp : entity work.sn74hct244 -- tristate buffer
    port map(   iEnAN   => bankEn(5),
                iEnBN   => bankEn(5),
                iData   => keyArray,
                oData   => dataBus);

    ----------------------------------------------------------
    ------        Audio Out $4000-$4FFF                -------
    ----------------------------------------------------------
    -- Keep writing access to XOUT with video output?
    --   or switch to memory bus access?
    -- Lower 4 bits is audio left (or mono) - goes to tip
    -- Upper 4 bits is audio right - goes to first ring
    -- Upper 4 bits can also go to LEDs
    -- Ground is second ring
    -- Mic is sleeve.  Maybe have jumpers to select second audio input connector, or from mic sleeve.
    audioComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => sysClk,
                iLoadN  => (bankEn(4) and ramWrN),
                iData   => acReg,
                oData   => audioReg);
    
end architecture ttl;