/*
-- @file sn74hct157.vhd
-- @brief Models the HCT157 - quad 2:1 multiplexer 
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

entity sn74hct157 is
    port(   iA       : in slv(3 downto 0);
            iB       : in slv(3 downto 0);
            iEnableN : in sl;
            iSelect  : in sl;
            oY       : out slv(3 downto 0));

end entity sn74hct157;

architecture rtl of sn74hct157 is

begin

    process(all)
    begin
        oY <= "ZZZZ";
        if std_match(iEnableN,'1') then
            oY <= "0000";
        elsif std_match(iSelect,'0') then
            oY <= iA;
        elsif std_match(iSelect,'1') then
            oY <= iB;
        end if;
    end process;

end rtl;
