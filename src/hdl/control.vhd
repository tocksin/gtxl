/*
-- @file control.vhd
-- @brief Control unit design
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

entity control is
    port(   iClk        : in sl;
            iInst       : in slv(7 downto 0);
            iCarry      : in sl;
            iSign       : in sl;
            iExecute    : in sl;
            iInterrupt  : in sl;
            oAluOp      : out slv(4 downto 0);
            oXLoad      : out sl;
            oYLoad      : out sl;
            oIncX       : out sl;
            oPCLoadLo   : out sl;
            oPCLoadHi   : out sl;
            oAcLoad     : out sl;
            oVidLoad    : out sl;
            oMemDrive   : out sl;
            oImmDrive   : out sl;
            oAccDrive   : out sl;
            oYBufDrive  : out sl;
            oYBusDrive  : out sl;
            oRamWrN     : out sl;
            oMauLoDis   : out sl;
            oRetI       : out sl);
end entity control;

architecture rtl of control is

    signal operation    : slv(7 downto 0);
    signal opName       : string(1 to 3);
    signal mode         : slv(7 downto 0);
    signal modeName     : string(1 to 12);
    signal busSrc       : slv(3 downto 0);
    signal busDriveName : string(1 to 8);
    signal fullName     : string(1 to 15);
    signal jumpBus      : slv(3 downto 0);
    signal branch       : sl;
    signal modeEn       : sl;
    
begin

    ----------------------------------------------------------
    ------          Operation decoding                 -------
    ----------------------------------------------------------
    operationDecoderComp : entity work.sn74hct138
    port map(   iEn     => iInterrupt,
                iEnLo0  => iExecute,
                iEnLo1  => '0',
                iA      => iInst(5),
                iB      => iInst(6),
                iC      => iInst(7),
                oY      => operation);
    
    opName <= " LD" when operation = "11111110" else
              "AND" when operation = "11111101" else
              " OR" when operation = "11111011" else
              "XOR" when operation = "11110111" else
              "ADD" when operation = "11101111" else
              "SUB" when operation = "11011111" else
              " ST" when operation = "10111111" else
              "Bcc" when operation = "01111111" else
              "off" when operation = "11111111" else
              "ERR";

    -- Operation didoe ROM 
    oAluOp(0) <= '1' when opName="SUB" or opName="Bcc" else '0';

    oAluOp(1) <= '1' when opName=" OR" or opName="XOR" or opName="SUB" else '0';

    oAluOp(2) <= '1' when opName=" LD" or opName=" OR" or opName="XOR" or
                          opName="ADD" or opName="Bcc" else '0';
    
    oAluOp(3) <= '1' when opName=" LD" or opName="AND" or opName=" OR" or 
                          opName="ADD" else '0';
                             
    oAluOp(4) <= '1' when opName=" LD" or opName="AND" or opName=" OR" or
                          opName="XOR" or opName="Bcc" else '0';

    ----------------------------------------------------------
    ------      Memory MUX and Destination decoder     -------
    ----------------------------------------------------------
    -- IR4,3,2
    -- 000- [ Y,X]   , AC
    -- 001- [80,X]   , AC
    -- 010  [80,00]  , AC
    -- 011- [80,X]   , X
    -- 100- [80,X]   , Y
    -- 101  [ Y,00]  , Y
    -- 110- [80,X]   , VID
    -- 111- [ Y,X++] , VID
    
    modeEn <= operation(7) and iInterrupt;
    
    modeDecoderComp : entity work.sn74hct138
    port map(   iEn     => modeEn, -- disable during Bcc iInterrupt
                iEnLo0  => iExecute,
                iEnLo1  => '0',
                iA      => iInst(2),
                iB      => iInst(3),
                iC      => iInst(4),
                oY      => mode);

    modeName <= "[80,X]  , AC" when mode="11111110" else  --Y Bus on
                "[ Y,X]  , AC" when mode="11111101" else  --Y Bus off
                "[80,00] , AC" when mode="11111011" else  --Y Bus off
                "[80,X]  ,  X" when mode="11110111" else  --Y Bus off
                "[80,X]  ,  Y" when mode="11101111" else  --Y Bus off
                "[ Y,00] ,  Y" when mode="11011111" else  --Y Bus on
                "[80,X]  ,VID" when mode="10111111" else  --Y Bus off
                "[ Y,X++],VID" when mode="01111111" else  --Y Bus on
                "Disabled,Bcc" when mode="11111111" else
                "ERROR   ,ERR";
    
    ----------------------------------------------------------
    ------          Data Bus Source Selector           -------
    ----------------------------------------------------------
    sourceBus : entity work.sn74hct139
    port map(   iEnN     => iExecute,
                iData    => iInst(1 downto 0),
                oData    => busSrc);

    oYBusDrive <= '0' when (modeName="[ Y,X]  , AC"
                         or modeName="[ Y,00] ,  Y"
                         or modeName="[ Y,X++],VID")
                        and oRetI='1'
                       else '1';

    oYBufDrive <= busSrc(3) when oPCLoadHi='1' else '1'; -- override during jump instruction
    oMemDrive  <= busSrc(2);
    oAccDrive  <= busSrc(1);
    oImmDrive  <= busSrc(0);

    busDriveName <= "       Y" when oYBufDrive='0' else
                    "     MEM" when oMemDrive='0' else
                    "      AC" when oAccDrive='0' else
                    "       D" when oImmDrive='0' else
                    "     off" when busSrc="0000" else
                    "     ERR";
    
    fullName <= opName & modeName(1 to 8) & modeName(9 to 12) when busDriveName = "     MEM" else
                opName & busDriveName & modeName(9 to 12);
    
    oXLoad    <= '0' when  modeName="[80,X]  ,  X" else '1';
    
    oYLoad    <= '0' when  modeName="[80,X]  ,  Y" or 
                           modeName="[ Y,00] ,  Y" else '1';

    oAcLoad   <= '0' when (modeName="[ Y,X]  , AC" or 
                           modeName="[80,X]  , AC" or
                           modeName="[80,00] , AC")  and opName/=" ST" else '1';

    oVidLoad  <= '0' when (modeName="[80,X]  ,VID" or 
                           modeName="[ Y,X++],VID") and opName/=" ST" else '1';
    
    oIncX     <= '1' when  modeName="[ Y,X++],VID" else '0';
    
    oMauLoDis <= '1' when  modeName="[80,00] , AC" or 
                           modeName="[ Y,00] ,  Y" else '0';
    
    oRamWrN <= '0' when (iClk='0') and (opName=" ST") and (oMemDrive='1') else '1';
    
    ----------------------------------------------------------
    ------          Branch/Jump detection              -------
    ----------------------------------------------------------
    jumpDetector : entity work.sn74hct139
    port map(   iEnN     => iInst(4),
                iData    => iInst(3 downto 2),
                oData    => jumpBus);  -- active low only on jump mode

    oPCLoadHi <= '0' when jumpBus(0)='0' and opName="Bcc" else '1';

    branchDecoder : entity work.sn74hct153
    port map(   iEnAN    => operation(7), -- Bcc instruction active
                iEnBN    => '1',
                iSel     => (iCarry & iSign),
                iA       => ('0' & iInst(4 downto 2)),
                iB       => "1111",
                oA       => branch,
                oB       => open);

    oPCLoadLo <= '0' when oPCLoadHI='0' or branch='1' else '1';

    -- return from interrupt instruction replaces jmp Y,Y
    oRetI <= '0' when (oPCLoadHi='0') and (busSrc(3)='0') else '1';

end architecture rtl;
