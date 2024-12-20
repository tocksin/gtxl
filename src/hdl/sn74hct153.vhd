/*
-- @file sn74hct153.vhd
-- @brief Dual 4:1 decoders
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

entity sn74hct153 is
    Port ( iEnAN    : in sl;
           iEnBN    : in sl;
           iSel     : in slv (1 downto 0);
           iA       : in slv (3 downto 0);
           iB       : in slv (3 downto 0);
           oA       : out sl;
           oB       : out sl);
end entity sn74hct153;

architecture rtl of sn74hct153 is

begin

    oA <=   '0' when (iEnAN='1') else 
            iA(0) when ((iSel(0)='0') and (iSel(1)='0')) else 
            iA(1) when ((iSel(0)='1') and (iSel(1)='0')) else
            iA(2) when ((iSel(0)='0') and (iSel(1)='1')) else
            iA(3) when ((iSel(0)='1') and (iSel(1)='1')) else
            '0';

    oB <=   '0' when (iEnBN='1') else
            iB(0) when ((iSel(0)='0') and (iSel(1)='0')) else 
            iB(1) when ((iSel(0)='1') and (iSel(1)='0')) else
            iB(2) when ((iSel(0)='0') and (iSel(1)='1')) else
            iB(3) when ((iSel(0)='1') and (iSel(1)='1')) else
            '0';

end architecture rtl;
