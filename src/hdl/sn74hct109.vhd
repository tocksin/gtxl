/*
-- @file sn74hct109.vhd
-- @brief Models the HCT109 chip - J/K FF
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

entity sn74hct109 is
    port(   iClk    : in    sl;
            iRstN   : in    sl;
            iSetN   : in    sl;
            iJ      : in    sl;
            iKN     : in    sl;
            oQ      :   out sl;
            oQN     :   out sl);
end entity sn74hct109;

architecture rtl of sn74hct109 is

    signal state : sl := '0';

begin

    --  J       K       Next state
    --  0       0       Reset
    --  0       1       Hold
    --  1       0       Toggle
    --  1       1       Set

    FFproc : process (iClk,iRstN,iSetN)
    begin
        if (iRstN='0') then
            state <= '0';
        elsif (iSetN='0') then
            state <= '1';
        elsif rising_edge(iClk) then
            if (iJ='1') and (iKN='0') then
                state <= not state;
            elsif (iJ='1') then
                state <= '1';
            elsif (iKN = '0') then
                state <= '0';
            end if;
        end if;
    end process FFproc;

    oQ <= state;
    oQN <= not state;

end architecture rtl;
