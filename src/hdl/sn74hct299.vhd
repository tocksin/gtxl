/*
* @file sn74hct299.vhd
* @brief Model of the 74HCT299 shift register
* @author Justin Davis
*    Copyright (C) 2024  Justin Davis

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
**************************************************************************/
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;

library work;           use work.tools_pkg.all;

entity sn74hct299 is
    port(   clkIn           : in    sl;   -- clock
            rstNIn          : in    sl;   -- reset active low
            modeSIn         : in    slv(1 downto 0); -- mode control
            serial0In       : in    sl;   -- right shift data in
            serial7In       : in    sl;   -- left shift data in
            driverEn0NIn    : in    sl;   -- output driver enable active Low #0
            driverEn1NIn    : in    sl;   -- output driver enable active low #1
            dataInOut       : inout slv(7 downto 0) -- parallel data
        );
end entity sn74hct299;

architecture rtl of sn74hct299 is

    signal shifter    : slv(7 downto 0) := x"00";

begin

    shifterProc: process (clkIn, rstNIn)
    begin
        if (rstNIn='0') then
            shifter <= (others => '0');
        elsif rising_edge(clkIn) then
            if modeSIn="01" then                -- shift "right" from LSB to MSB
                shifter <= shifter(6 downto 0) & serial0In;
            elsif modeSIn="10" then             -- shift "left" from MSB to LSB
                shifter <= serial7In & shifter(7 downto 1);
            elsif modeSIn="11" then
                shifter <= to_X01(dataInOut);
            end if;
        end if;
    end process shifterProc;

    dataInOut <= shifter when driverEn0NIn='0' and driverEn1NIn='0' else x"ZZ";
    
end architecture rtl;