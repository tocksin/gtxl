/*
-- @file sp_ram_async.vhd
-- @brief Single-port RAM - Asynchronous (no clock)
-- @author Justin Davis
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
library ieee;       use ieee.std_logic_1164.all;
                    use ieee.numeric_std.all;
                    
library work;       use work.tools_pkg.all;

entity sp_ram_async is
    port(   iWrEnN  : in    std_logic;
            iRamEnN : in    std_logic;
            iAddr   : in    std_logic_vector;
            iData   : in    std_logic_vector;
            oData   :   out std_logic_vector  -- must be same size as input data
    );
end entity sp_ram_async;

-- attribute ram_style of {signal_name | entity_name }: {signal | entity} is "{auto | block | distributed | pipe_distributed | block_power1 | block_power2}";

architecture rtl of sp_ram_async is

    type ramType is array ((2**iAddr'length)-1 downto 0) of std_logic_vector(iData'range);

    signal RAM : ramType;

    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";

begin
    process(all)
    begin
        if iRamEnN = '0' then
            if iWrEnN = '0' then
                RAM(to_integer(unsigned(iAddr))) <= iData;
                oData <= iData;
            else
                oData <= RAM(to_integer(unsigned(iAddr)));
            end if;
        end if;
    end process;
end architecture rtl;
