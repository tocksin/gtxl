/*
-- @file sn74hct161.vhd
-- @brief Models the HCT161 chip - 4-bit counter
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

entity sn74hct161 is
    port(   iClk        : in sl;               -- clock
            iRstN       : in sl;               -- (/MR)master reset (active low)
            iLoadN      : in sl;               -- (/SPE) parallel load (active low) 
            iCntEn      : in sl;               -- (PE) count enable
            iTCntEn     : in sl;               -- (TE) count enable 
            iData       : in slv (3 downto 0);
            oData       : out slv (3 downto 0);
            oTerminal   : out sl);             -- (TC) output high when Q=1111 and TC=1
end sn74hct161;

architecture rtl of sn74hct161 is

    signal count : unsigned (3 downto 0) := x"0";

begin

    process(iClk,iRstN)
    begin
        if (iRstN='0') then
            count  <= (others => '0');
        elsif (rising_edge(iClk)) then
            if (iLoadN='0') then
                count <= unsigned(iData);
            elsif ((iCntEn='1') and (iTCntEn='1')) then
                count <= count + 1;
            end if;
        end if;
    end process;

    oTerminal <= '1' when ((iTCntEn='1') and (count="1111")) else '0';
    
    oData <= slv(count);

end rtl;
