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
    
    signal stateN       : slv(7 downto 0);
    signal stateOp      : slv(1 downto 0);
    signal instFetch    : sl;
    signal immFetch     : sl;
    signal execute      : sl;
    signal pcClear      : sl;
    signal loadPC       : sl;
    signal pcCount      : sl;
    signal pcLoadLo     : sl;
    signal pcLoadHi     : sl;
    
    signal terminal0    : sl;
    signal terminal1    : sl;
    signal terminal2    : sl;
    
    signal instReg      : slv(7 downto 0);
    signal immEn        : sl;
    signal immDriveEn   : sl;
    
    signal aluOp        : slv(4 downto 0);
    signal aluData      : slv(7 downto 0);
    signal aluCarry     : sl;
    signal acReg        : slv(7 downto 0) := x"00";
    signal acLoad       : sl;
    signal acDriveEn    : sl;

    signal yReg         : slv(7 downto 0) := x"00";
    signal yLoad        : sl;
    signal yDriven      : sl;
    signal yBus         : slv(7 downto 0);
    signal yBusDriveEn  : sl;
    signal yBufDriveEn  : sl;

    signal xReg         : slv(7 downto 0) := x"00";
    signal xCount       : sl;
    signal xLoad        : sl;
    signal xTermLo      : sl;
    
    signal vidLoad      : sl;
    signal vidReg       : slv(7 downto 0) := x"00";
    
    signal PCReg        : slv(15 downto 0);
    signal mauEnLo      : sl;
    signal mauEnHi      : sl;
    signal mauSel       : sl;
    signal mauDisableLo : sl;
    signal memAddr      : slv(15 downto 0);
    signal bankEn       : slv(7 downto 0);
    signal memDriveEn   : sl;
    
    signal dataRom      : slv(7 downto 0);
    signal ramWrN       : sl;
    signal dataRam      : slv(7 downto 0);
    signal dataRamDef   : slv(7 downto 0);
    signal dataBus      : slv(7 downto 0);

    signal timerLoad    : sl;
    signal timerTermLo  : sl;
    signal timerReg     : slv(7 downto 0) := x"00";
    signal timerTC      : sl;
    signal interrupt    : sl;
    signal intEn        : sl := '1';
    signal intClear     : sl;
    signal intEnClk     : sl;
    signal intEnNext    : sl;
    
    signal PCHold       : slv(15 downto 0);

    signal retI         : sl;
    
begin

    rstN <= not iRst;

    pcClear <= '0' when (iRst='1') or ((interrupt='0') and (execute='0')) else '1';
    ----------------------------------------------------------
    ------          State Machine                      -------
    ----------------------------------------------------------
    -- First state: fetch Instruction
        -- enable PC counting, enable instruction register, set address MUX to PC
    -- Second state: fetch Immediate Data
        -- enable PC counting, enable immediate register, set address MUX to PC
    -- Third state: execute
        -- disable PC counting, set address MUX to execute

    -- stateOp is 11 when loading (only on reset), 01 when shifting LSB to MSB
    stateOp(0) <= '1';
    stateOp(1) <= iRst;
    stateN <= "HHHHHHHL";  -- value that gets loaded at startup

    -- State machine (shifter)
    stateComp : entity work.sn74hct299(rtl)
    port map(clkIn           => iClk,
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
    
    pcCount <= execute;
    loadPC <= '1';
    ----------------------------------------------------------
    ------          Program Counter                    -------
    ----------------------------------------------------------
    pc0: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadLo,    -- load PC when we jump or return from interrupt
                iCntEn      => pcCount,
                iTCntEn     => '1',
                iData       => dataBus(3 downto 0),
                oData       => pcReg(3 downto 0),
                oTerminal   => terminal0);

    pc1: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadLo,
                iCntEn      => pcCount,
                iTCntEn     => terminal0,
                iData       => dataBus(7 downto 4),
                oData       => pcReg(7 downto 4),
                oTerminal   => terminal1);

    pc2: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadHi,
                iCntEn      => pcCount,
                iTCntEn     => terminal1,
                iData       => yBus(3 downto 0),
                oData       => pcReg(11 downto 8),
                oTerminal   => terminal2);

    pc3: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => pcClear,
                iLoadN      => pcLoadHi,
                iCntEn      => pcCount,
                iTCntEn     => terminal2,
                iData       => yBus(7 downto 4),
                oData       => pcReg(15 downto 12),
                oTerminal   => open);

    ----------------------------------------------------------
    ------          Memory Address Selector            -------
    ----------------------------------------------------------
    -- En = 1 only for interrupt vector
    -- otherwise Sel  = 0 for execute, 1 for fetch
    -- The only user mode is [Y,X] , but Y can also tristate for [80,X]
    
    --      EnHi   EnLo   Sel    Memory access
    --      0      0      0      [ Y, X] -- normal memory access
    --      0      0      1      [PC,PC] -- fetch
    --      0      1      0      [ Y, 0] -- for restoring Y and AC
    --      1      1      X      [00,00] -- interrupt vector
    mauEnHi <= '0'; -- 1 during interrupt here
    mauEnLo <= mauDisableLo; -- need to force to 1 during interrupt and during specific mode
    mauSel <= execute; -- only 1 during program counter access
    
    mau0 : entity work.sn74hct157
    port map(   iA          => xReg(3 downto 0),
                iB          => pcReg(3 downto 0),
                iEnableN    => mauEnLo,
                iSelect     => mauSel,
                oY          => memAddr(3 downto 0));

    mau1 : entity work.sn74hct157
    port map(   iA          => xReg(7 downto 4),
                iB          => pcReg(7 downto 4),
                iEnableN    => mauEnLo,
                iSelect     => mauSel,
                oY          => memAddr(7 downto 4));

    mau2 : entity work.sn74hct157
    port map(   iA          => To_X01(yBus(3 downto 0)),
                iB          => pcReg(11 downto 8),
                iEnableN    => mauEnHi,
                iSelect     => mauSel,
                oY          => memAddr(11 downto 8));

    mau3 : entity work.sn74hct157
    port map(   iA          => To_X01(yBus(7 downto 4)),
                iB          => pcReg(15 downto 12),
                iEnableN    => mauEnHi,
                iSelect     => mauSel,
                oY          => memAddr(15 downto 12));

    ----------------------------------------------------------
    ------          Memory Address Decoder             -------
    ----------------------------------------------------------
    -- $0000-$3FFF  ROM  (16k)
    -- $4000-$7FFF  Peripherals
    -- $8000-$FFFF  RAM  (32k)

    -- decoder divider addresses into:
    -- $0000-$1FFF ROM
    -- $1000-$2FFF ROM
    -- $2000-$3FFF ROM
    -- $3000-$4FFF ROM
    -- $4000-$4FFF Timer
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
    ------                ROM                          -------
    ----------------------------------------------------------
    romComp : entity work.rom_synth
    port map(   iAddr      => memAddr(13 downto 0),
                oData      => dataRom);
    dataBus <= dataRom when (and(bankEn(3 downto 0)) = '0') and ((memDriveEn='0') or (execute='1')) else "ZZZZZZZZ";

    ----------------------------------------------------------
    ------                RAM                          -------
    ----------------------------------------------------------
    ramComp : entity work.sp_ram_async
    port map(   iWrEnN   => ramWrN,
                iRamEnN  => '0',
                iAddr   => memAddr(14 downto 0),
                iData   => dataBus,
                oData   => dataRam);
    dataRamDef <= "00000000" when dataRam="UUUUUUUU" else dataRam; -- fix for uninitialized RAM behavior
    dataBus <= dataRamDef when (memAddr(15) = '1') and ((memDriveEn='0') or (execute='1')) else "ZZZZZZZZ";

    ----------------------------------------------------------
    ------         Instruction Register                -------
    ----------------------------------------------------------
    instComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => iClk,
                iLoadN  => instFetch,
                iData   => dataBus,
                oData   => instReg);

    ----------------------------------------------------------
    ------         Instruction Decoder                 -------
    ----------------------------------------------------------
    controlComp: entity work.control
    port map(   iClk   => iClk,
                iInst  => instReg,
                iCarry => aluCarry,
                iSign  => acReg(7),
                iExecute => execute,
                iInterrupt => interrupt,
                oAluOp => aluOp,
                oXLoad => xLoad,
                oYLoad => yLoad,
                oIncX  => xCount,
                oPCLoadLo => pcLoadLo,
                oPCLoadHi => pcLoadHi,
                oacLoad   => acLoad,
                oVidLoad => vidLoad,
                oMemDrive => memDriveEn,
                oImmDrive => immDriveEn,
                oAccDrive => acDriveEn,
                oYBusDrive => yBusDriveEn,
                oYBufDrive => yBufDriveEn,
                oRamWrN => ramWrN,
                oMauLoDis => mauDisableLo,
                oRetI   => retI);

    ----------------------------------------------------------
    ------         Immediate Data Register             -------
    ----------------------------------------------------------
    immeComp : entity work.sn74hct574  -- FF with tristate output
    port map(   iClk    => immFetch,
                iEnN    => immDriveEn,
                iData   => dataBus,
                oData   => dataBus);

    ----------------------------------------------------------
    ------         Arithmetic Logic Unit               -------
    ----------------------------------------------------------
    aluComp : entity work.alu
    port map(   iDataA      => dataBus,
                iDataB      => acReg,
                iOp         => aluOp,
                oData       => aluData,
                oCarry      => aluCarry);

    ----------------------------------------------------------
    ------         Accumulator Register and Buffer     -------
    ----------------------------------------------------------
    accComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => iClk,
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
    port map(   iClk        => iClk,
                iRstN       => rstN,
                iLoadN      => xLoad,
                iCntEn      => xCount,
                iTCntEn     => '1',
                iData       => aluData(3 downto 0),
                oData       => xReg(3 downto 0),
                oTerminal   => xTermLo);

    xHiComp: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => rstN,
                iLoadN      => xLoad,
                iCntEn      => xCount,
                iTCntEn     => xTermLo,
                iData       => aluData(7 downto 4),
                oData       => xReg(7 downto 4),
                oTerminal   => open);


    ----------------------------------------------------------
    ------        Video Register                       -------
    ----------------------------------------------------------
    vidComp : entity work.sn74hct377  -- FF with load enable
    port map(   iClk    => iClk,
                iLoadN  => vidLoad,
                iData   => aluData,
                oData   => vidReg);
    
    ----------------------------------------------------------
    ------        Timer                                -------
    ----------------------------------------------------------
    timerLoad <= '0' when (execute='0') and (bankEn(4)='0') and (ramWrN='0') else '1';
    
    timerLoComp: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => rstN,
                iLoadN      => timerLoad,
                iCntEn      => (not execute),
                iTCntEn     => '1',
                iData       => dataBus(3 downto 0),
                oData       => timerReg(3 downto 0),
                oTerminal   => timerTermLo);

    timerHiComp: entity work.sn74hct161
    port map(   iClk        => iClk,
                iRstN       => rstN,
                iLoadN      => timerLoad,
                iCntEn      => (not execute),
                iTCntEn     => timerTermLo,
                iData       => dataBus(7 downto 4),
                oData       => timerReg(7 downto 4),
                oTerminal   => timerTC);

    interrupt <= not timerTC;
    dataBus <= timerReg when ((bankEn(4)='0') and (memDriveEn='0')) else "ZZZZZZZZ";
    
    ----------------------------------------------------------
    ------        Interrupt Enable Register            -------
    ----------------------------------------------------------
    -- intStateProc: process (iClk)
    -- begin
        -- if (rising_edge(iClk)) then
            -- if (interrupt='0') then
                -- intEn <= '1';       -- after reset, interrupts disabled
            -- elsif (retI='0') then
                -- intEn <= '0';       -- after reti, interrupts enabled
            -- end if;
        -- end if;
    -- end process intStateProc;

    intEnNext <= '1' when (interrupt='0') or ((intEn='1') and (retI='1')) else '0';
    
    intStateComp : entity work.sn74hct74
    port map(   iClk    => iClk,
                iRstN   => '1',
                iSetN   => rstN,
                iD      => intEnNext,
                oQ      => intEn,
                oQN     => open);

    ----------------------------------------------------------
    ------        Program Counter Hold Register        -------
    ----------------------------------------------------------
    intEnClk <= iClk or intEn;

    pcHoldHiComp : entity work.sn74hct574  -- FF with tristate output
    port map(   iClk    => intEnClk,  -- can't just be intEn.  won't clock every clock.  maybe OR with clock?
                iEnN    => retI,
                iData   => pcReg(15 downto 8),
                oData   => yBus);

    pcHoldLoComp : entity work.sn74hct574  -- FF with tristate output
    port map(   iClk    => intEnClk,  -- can't just be intEn.  won't clock every clock.  maybe OR with clock?
                iEnN    => retI,
                iData   => pcReg(7 downto 0),
                oData   => dataBus);

end architecture ttl;