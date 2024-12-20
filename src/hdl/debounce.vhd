/*
* @file debounce.vhd
* @brief Filter for noisy signals.  Input signal change will pass through to
*        output immediately, but any other change in signal must wait for 
*        a specified time.  
* @author Justin Davis
*
* Copyright: ©2023 by Southwest Research Institute®; all rights reserved
**************************************************************************/
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;
                        
library work;           use work.tools_pkg.all;

entity debounce is
    generic(CLK_PERIOD      : time;  -- Clock Period
            CONTACT_BOUNCE  : time;  -- Minumum time for assert   
            ACTIVE_LEVEL    : std_logic := '1';  
            INIT_VAL        : std_logic := '0';  -- Initial value for all regs
            );
    port(   clkIn           : in    std_logic;
            rstIn           : in    std_logic;
            rawIn           : in    std_logic;
            debouncedOut    :   out std_logic);
end entity debounce;

architecture rtl of debounce is

    constant MIN_ASSERT : unsigned := to_unsigned(CONTACT_BOUNCE/CLK_PERIOD,32);

    constant CNTR_WIDTH : integer := log2(DEBNC_CLOCKS);
    constant CNTR_MAX   : std_logic_vector((CNTR_WIDTH - 1) downto 0) := std_logic_vector(to_unsigned((DEBNC_CLOCKS - 1), CNTR_WIDTH));
    type VECTOR_ARRAY_TYPE is array (integer range <>) of std_logic_vector((CNTR_WIDTH - 1) downto 0);

    signal sig_cntrs_ary : VECTOR_ARRAY_TYPE (0 to (rawIn'length - 1));

    signal sig_out_reg   : std_logic_vector((rawIn'length - 1) downto 0);

    signal inR           : std_logic_vector(rawIn'range);
    signal inRR          : std_logic_vector(rawIn'range);

begin

    inRegProc: process (clkIn, rstIn)
    begin
        if (rstIn = '1') then
            inR <= (others => '0');
            inRR <= (others => '0');
        elsif rising_edge(clkIn) then
            inR <= rawIn;
            inRR <= inR;
        end if;
    end process inRegProc;

    debounce_process : process (clkIn, rstIn)
    begin
        if (rstIn = '1') then
            sig_out_reg <= (others => '0');
        elsif (rising_edge(clkIn)) then
            for index in 0 to (rawIn'length - 1) loop
                if (sig_cntrs_ary(index) = CNTR_MAX) then
                    sig_out_reg(index) <= not(sig_out_reg(index));
                end if;
            end loop;
        end if;
    end process debounce_process;

    counter_process : process (clkIn, rstIn)
    begin
        if (rstIn = '1') then
            for index in 0 to (rawIn'length - 1) loop
                sig_cntrs_ary(index) <= (others => '0');
            end loop;
        elsif (rising_edge(clkIn)) then
            for index in 0 to (rawIn'length - 1) loop
                if ((sig_out_reg(index) = '1') xor (inRR(index) = '1')) then
                    if (sig_cntrs_ary(index) = CNTR_MAX) then
                        sig_cntrs_ary(index) <= (others => '0');
                    else
                        sig_cntrs_ary(index) <= std_logic_vector(unsigned(sig_cntrs_ary(index)) + 1);
                    end if;
                else
                    sig_cntrs_ary(index) <= (others => '0');
                end if;
            end loop;
        end if;
    end process;

    debouncedOut <= sig_out_reg;

end architecture rtl;

