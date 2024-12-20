/*
-- @file sn74hct139.vhd
-- @brief Models the HCT139 chip - 4:1 decoder with enable
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


entity sn74hct139 is
    port ( iEnN     : in sl;  -- active low
           iData    : in slv(1 downto 0);
           oData    : out slv(3 downto 0));
end entity sn74hct139;

architecture rtl of sn74hct139 is

begin

    oData(0) <= '0' when ((iEnN = '0') and (iData(1)='0') and (iData(0)='0')) else '1';
    oData(1) <= '0' when ((iEnN = '0') and (iData(1)='0') and (iData(0)='1')) else '1';
    oData(2) <= '0' when ((iEnN = '0') and (iData(1)='1') and (iData(0)='0')) else '1';
    oData(3) <= '0' when ((iEnN = '0') and (iData(1)='1') and (iData(0)='1')) else '1';

end architecture rtl;
