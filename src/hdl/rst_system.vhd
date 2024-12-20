-- @file rst_system.vhd
-- @brief Reset synchronization
-- @author Justin Davis
--
-- $Revision: -
-- $Date: 07/06/2023
-- $LastEditedBy: Justin Davis
--
-- $Copyright: 2023 Southwest Research Institute
-------------------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;

library work;           use work.tools_pkg.all;

entity rst_system is
    generic(ACTIVE_IN   : sl := '1';
            ACTIVE_OUT  : sl := '1');
    port( clkIn         : in    sl;
          rstIn         : in    sl;
          rstOut        :   out sl);
end entity rst_system;

architecture rtl of rst_system is

    signal rstR         : sl;
    signal rstRR        : sl;

begin

    rstProc : process (clkIn, rstIn)
    begin
        if (rstIn = ACTIVE_IN) then  -- asynchronously reset all signals
            rstOut <= ACTIVE_OUT;
            rstR   <= ACTIVE_OUT;
            rstRR  <= ACTIVE_OUT;
        elsif rising_edge(clkIn) then  -- synchronously release reset
            rstR <= not ACTIVE_OUT;
            rstRR <= rstR;
            rstOut <= rstRR;         
        end if;
    end process rstProc;
    
end architecture rtl;
