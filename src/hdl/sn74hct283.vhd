/*
-- @file sn74hct283.vhd
-- @brief 4-bit adder
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

entity sn74hct283 is
    port (  iDataA  : in slv(3 downto 0);
            iDataB  : in slv(3 downto 0);
            iCarry  : in sl;
            oCarry  : out sl;
            oSum    : out slv(3 downto 0));

end entity sn74hct283;

architecture rtl of sn74hct283 is

    signal sumA  : unsigned(4 downto 0) := "00000";
    signal sumB  : unsigned(4 downto 0) := "00000";
    
begin

    sumA <= ('0' & unsigned(iDataA)) + unsigned(iDataB);
    sumB <= unsigned(sumA) + iCarry;
    oCarry <= sumB(4);
    oSum <= slv(sumB(3 downto 0));
    
end architecture rtl;
