/*
-- @file sn74hct273.vhd
-- @brief Octal flip-flop with master reset
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

entity sn74hct273 is
    port (  iClk    : in sl;
            iRstN   : in sl;
            iData   : in slv(7 downto 0);
            oData   : out slv(7 downto 0));

end entity sn74hct273;

architecture rtl of sn74hct273 is

begin

    FFProc: process (iClk,iRstN)
    begin
        if (iRstN='0') then
            oData  <= (others => '0');
        elsif (rising_edge(iClk)) then
            oData <= iData;
        end if;
    end process FFProc;


end architecture rtl;
