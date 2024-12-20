/*
-- @file alu.vhd
-- @brief Arithmatic and logic unit
-- @author Justin Davis
--
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

entity alu is
    port(   iDataA      : in slv(7 downto 0); -- Bus
            iDataB      : in slv(7 downto 0); -- AC
            iOp         : in slv(4 downto 0); -- AL & AR(3 downto 0)
            oData       : out slv(7 downto 0);
            oCarry      : out sl);
end entity alu;

architecture rtl of alu is

    signal addA     : slv(7 downto 0);
    signal addB     : slv(7 downto 0);
    signal carryLo  : sl;

begin
    -- Original reference by Dieter Mueller : http://6502.org/users/dieter/a1/a1_4.htm
    -- More design notes: https://hackaday.io/project/20781-gigatron-ttl-microcomputer/log/56640-testing-a-bunch-of-diodes
    -- 0000 = 0x0 // Q=0x00  (use for ST)
    -- 0001 = 0x1 // Q=/A&/B 
    -- 0010 = 0x2 // Q= A&/B 
    -- 0011 = 0x3 // Q=/B    (use for SUB)

    -- 0100 = 0x4 // Q=/A& B 
    -- 0101 = 0x5 // Q=/A    (use for Bcc)
    -- 0110 = 0x6 // Q=  A^B (use for XOR)
    -- 0111 = 0x7 // Q=/A|/B 

    -- 1000 = 0x8 // Q= A& B (use for AND)
    -- 1001 = 0x9 // Q=/(A^B)
    -- 1010 = 0xa // Q=A     (use for passing A on left)
    -- 1011 = 0xb // Q= A|/B 

    -- 1100 = 0xc // Q=B     (use for passing B on left, LD, and ADD)
    -- 1101 = 0xd // Q=/A| B 
    -- 1110 = 0xe // Q= A| B (use for OR)
    -- 1111 = 0xf // Q=0xff  

    -- First is logic functions, then adding functions
    -- Logic functions are pass B, AND, OR, XOR, NOT B, NOT A, ZERO
    -- Logic functions happen first
    -- Adding stage is second.  Logic output is always on the right side.
    -- Left side of add is either ZERO or A.

    -- Instruction  Left    Right       CIN     Add Result
    --      LD      0       B           0       B
    --      AND     0       A AND B     0       A AND B 
    --      OR      0       A OR B      0       A OR B
    --      XOR     0       A XOR B     0       A XOR B 
    --      ADD     A       B           0       A + B 
    --      SUB     A       NOT B       1       A - B
    --      ST      A       0           0       A
    --      Bcc     0       NOT A       1       -A

    u21: entity work.sn74hct153
    port map(   iEnAN   => '0',
                iEnBN   => iOp(4),
                iSel    => (iDataA(0) & iDataB(0)),
                iA      => iOp(3 downto 0),
                iB      => "1010",
                oA      => addA(0),
                oB      => addB(0)
    );
    
    u22: entity work.sn74hct153
    port map(   iEnAN   => '0',
                iEnBN   => iOp(4),
                iSel    => (iDataA(1) & iDataB(1)),
                iA      => iOp(3 downto 0),
                iB      => "1010",
                oA      => addA(1),
                oB      => addB(1)
    );

    u23: entity work.sn74hct153
    port map(   iEnAN   => '0',
                iEnBN   => iOp(4),
                iSel    => (iDataA(2) & iDataB(2)),
                iA      => iOp(3 downto 0),
                iB      => "1010",
                oA      => addA(2),
                oB      => addB(2)
    );

    u24: entity work.sn74hct153
    port map(   iEnAN   => '0',
                iEnBN   => iOp(4),
                iSel    => (iDataA(3) & iDataB(3)),
                iA      => iOp(3 downto 0),
                iB      => "1010",
                oA      => addA(3),
                oB      => addB(3)
    );

    u17: entity work.sn74hct153
    port map(   iEnAN   => iOp(4),
                iEnBN   => '0',
                iSel    => (iDataB(4) & iDataA(4)),
                iA      => "1100",
                iB      => (iOp(3) & iOp(1) & iOp(2) & iOp(0)),
                oA      => addA(4),
                oB      => addB(4)
    );

    -- Upper bits are swapped around to make routing more efficient
    u18: entity work.sn74hct153
    port map(   iEnAN   => iOp(4),
                iEnBN   => '0',
                iSel    => (iDataB(5) & iDataA(5)),
                iA      => "1100",
                iB      => (iOp(3) & iOp(1) & iOp(2) & iOp(0)),
                oA      => addA(5),
                oB      => addB(5)
    );

    u19: entity work.sn74hct153
    port map(   iEnAN   => iOp(4),
                iEnBN   => '0',
                iSel    => (iDataB(6) & iDataA(6)),
                iA      => "1100",
                iB      => (iOp(3) & iOp(1) & iOp(2) & iOp(0)),
                oA      => addA(6),
                oB      => addB(6)
    );

    u20: entity work.sn74hct153
    port map(   iEnAN   => iOp(4),
                iEnBN   => '0',
                iSel    => (iDataB(7) & iDataA(7)),
                iA      => "1100",
                iB      => (iOp(3) & iOp(1) & iOp(2) & iOp(0)),
                oA      => addA(7),
                oB      => addB(7)
    );

    u26: entity work.sn74hct283
    port map(   iDataA  => addA(3 downto 0),
                iDataB  => addB(3 downto 0),
                iCarry  => iOp(0),
                oCarry  => carryLo,
                oSum    => oData(3 downto 0));

    u25: entity work.sn74hct283
    port map(   iDataA  => addA(7 downto 4),
                iDataB  => addB(7 downto 4),
                iCarry  => carryLo,
                oCarry  => oCarry,
                oSum    => oData(7 downto 4));

end architecture rtl;
