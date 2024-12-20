-- @file sseg_decoder.vhd
-- @brief Seven-segment decoder
-- @author Justin Davis
--
-- $Revision: -
-- $Date: 06/15/2023
-- $LastEditedBy: Justin Davis
--
-- $Copyright: 2023 Southwest Research Institute
-------------------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;

library work;           use work.tools_pkg.all;

entity sseg_decoder is
  generic( DELAY_CNTS   : integer := 100000);
    port ( clkIn        : in sl;
           rstIn        : in sl;
           digitsIn     : in slv(15 downto 0);
           anodeOut     : out slv(3 downto 0);
           cathodeOut   : out slv(7 downto 0)
           );
end sseg_decoder;

architecture rtl of sseg_decoder is

    constant DELAY_CNT_SIZE     : natural := log2(DELAY_CNTS,UP);

    signal digit            : slv(3 downto 0);
    signal currentAnode     : slv(3 downto 0);
    signal nextAnode        : slv(3 downto 0);
    signal delayCnt         : unsigned(DELAY_CNT_SIZE-1 downto 0);
    
begin

    -- Select the digit to decode and set that anode
    anodeProc : process (all)
    begin
        case currentAnode is
            when "1110" => 
                digit <= digitsIn(3 downto 0);
                nextAnode <= "1101";
            when "1101" =>
                digit <= digitsIn(7 downto 4);
                nextAnode <= "1011";
            when "1011" =>
                digit <= digitsIn(11 downto 8);
                nextAnode <= "0111";
            when "0111" =>
                digit <= digitsIn(15 downto 12);
                nextAnode <= "1110";
            when others =>
                digit <= digitsIn(15 downto 12);
                nextAnode <= "1110";
        end case;
    end process anodeProc;
    
    anodeRegProc : process (clkIn, rstIn)
    begin
        if (rstIn='1') then
            currentAnode <= "0001";
            delayCnt <= to_unsigned(DELAY_CNTS, DELAY_CNT_SIZE);
        elsif rising_edge(clkIn) then
            if (delayCnt = (delayCnt'range => '0')) then            
                currentAnode <= nextAnode;
                delayCnt <= to_unsigned(DELAY_CNTS, DELAY_CNT_SIZE);
            else
                delayCnt <= delayCnt-1;
            end if;
        end if;
    end process anodeRegProc;
    
    anodeOut <= currentAnode;
    
    cathodeProc : process (clkIn, rstIn)
    begin
        if (rstIn='1') then
            cathodeOut <= "11111111"; 
        elsif rising_edge(clkIn) then
            case digit is
                when "0000" => cathodeOut <= "01000000";
                when "0001" => cathodeOut <= "01111001";
                when "0010" => cathodeOut <= "00100100";
                when "0011" => cathodeOut <= "00110000"; 
                when "0100" => cathodeOut <= "00011001"; 
                when "0101" => cathodeOut <= "00010010"; 
                when "0110" => cathodeOut <= "00000010";
                when "0111" => cathodeOut <= "01111000";
                when "1000" => cathodeOut <= "00000000";
                when "1001" => cathodeOut <= "00010000";
                when "1010" => cathodeOut <= "00001000";
                when "1011" => cathodeOut <= "00000011";
                when "1100" => cathodeOut <= "01000110";
                when "1101" => cathodeOut <= "00100001";
                when "1110" => cathodeOut <= "00000110";
                when "1111" => cathodeOut <= "00001110";
                when others => cathodeOut <= "11111111";
            end case;
        end if;
    end process cathodeProc;
    

end rtl;
