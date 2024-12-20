/*
-- @file sn74hct244.vhd
-- @brief Octal flip-flop with output enable
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

entity sn74hct244 is
    port (  iEnAN   : in sl;
            iEnBN   : in sl;
            iData   : in slv(7 downto 0);
            oData   : out slv(7 downto 0));

end entity sn74hct244;

architecture rtl of sn74hct244 is


begin

    oData(3 downto 0) <= iData(3 downto 0) when iEnAN='0' else "ZZZZ";
    oData(7 downto 4) <= iData(7 downto 4) when iEnBN='0' else "ZZZZ";
    
end architecture rtl;
