/*
-- @file sn74hct138.vhd
-- @brief Models the HCT138 chip - 8:1 decoder with three enables
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

entity sn74hct138 is
    port(   iEn     : in    sl;  -- enable active high
            iEnLo0  : in    sl;  -- enable active low
            iEnLo1  : in    sl;  -- enable active low
            iA      : in    sl;
            iB      : in    sl;
            iC      : in    sl;
            oY      : out   slv(7 downto 0));
end entity sn74hct138;

architecture rtl of sn74hct138 is

    signal enabled  : sl;

begin

    enabled <= '1' when (iEn='1') and (iEnLo0 = '0') and (iEnLo1 = '0') else '0';

    oY(0) <= '0' when (enabled='1') and (iA='0') and (iB='0') and (iC='0') else '1';
    oY(1) <= '0' when (enabled='1') and (iA='1') and (iB='0') and (iC='0') else '1';
    oY(2) <= '0' when (enabled='1') and (iA='0') and (iB='1') and (iC='0') else '1';
    oY(3) <= '0' when (enabled='1') and (iA='1') and (iB='1') and (iC='0') else '1';
    oY(4) <= '0' when (enabled='1') and (iA='0') and (iB='0') and (iC='1') else '1';
    oY(5) <= '0' when (enabled='1') and (iA='1') and (iB='0') and (iC='1') else '1';
    oY(6) <= '0' when (enabled='1') and (iA='0') and (iB='1') and (iC='1') else '1';
    oY(7) <= '0' when (enabled='1') and (iA='1') and (iB='1') and (iC='1') else '1';

end architecture rtl;
