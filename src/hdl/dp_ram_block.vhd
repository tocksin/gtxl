-- @file dp_ram_block.vhd
-- @brief Dual-port ram - will synthesize to block RAM
-- @author Justin Davis
--
-- Date: 06/01/2023
-- LastEditedBy: Justin Davis
--
-- Copyright: 2023 Southwest Research Institute
-------------------------------------------------------------------------------

library ieee;       use ieee.std_logic_1164.all;
                    use ieee.numeric_std.all;
                    
library work;       use work.tools_pkg.all;

entity dp_ram_block is
   port(iClkA      : in    std_logic;
        iEnA       : in    std_logic;
        iWrEnA     : in    std_logic;
        iAddrA     : in    std_logic_vector;
        iDataA     : in    std_logic_vector;
        oDataA     :   out std_logic_vector; -- must match iDataA size

        iClkB      : in    std_logic;
        iEnB       : in    std_logic;
        iWrEnB     : in    std_logic;
        iAddrB     : in    std_logic_vector;
        iDataB     : in    std_logic_vector;
        oDataB     :   out std_logic_vector -- must match iDataB size
    );
end entity dp_ram_block;

architecture rtl of dp_ram_block is
    type ramType is array ((2**iAddrA'length)-1 downto 0) of std_logic_vector(iDataA'range);
    
        -- function to initialize memory content
    function initMemory(dataLength : in integer) return ramType is
    
    constant FLIGHT_NUM_STR     : string(1 to 20)  := "    FLIGHT NUMBER   ";
    constant SIX_DIGITS_STR     : string(1 to 20)  := "   ENTER 6 DIGITS   ";
    constant POUNDS_STR         : string(1 to 20)  := "      (######)      ";
    constant INPUT_STR          : string(1 to 20)  := "   I :      123     ";
    constant ENTER_STR          : string(1 to 20)  := "  THEN PRESS ENTER  ";
    constant BLANK_STR          : string(1 to 20)  := "                    ";

    constant FLT_STR            : string(1 to 20)  := " FLT   000123/000   ";
    constant TIME_STR           : string(1 to 20)  := " TIME    00:00:00   ";
    constant LAT_STR            : string(1 to 20)  := " LAT   N 00:00:00   ";
    constant LONG_STR           : string(1 to 20)  := " LONG  W000:00:00   ";
    constant AZ_STR             : string(1 to 20)  := " AZ           012   ";
    constant RANGE_STR          : string(1 to 20)  := " RANGE     08280M   ";
    constant RH_STR             : string(1 to 20)  := " R/H    0000/0000   ";
    constant RDR_STR            : string(1 to 20)  := " RDR                ";

    constant FLIGHT_NUM_ARR     : charArray(0 to 19) := toCharArray(FLIGHT_NUM_STR);
    constant SIX_DIGITS_ARR     : charArray(0 to 19) := toCharArray(SIX_DIGITS_STR);
    constant POUNDS_ARR         : charArray(0 to 19) := toCharArray(POUNDS_STR);
    constant INPUT_ARR          : charArray(0 to 19) := toCharArray(INPUT_STR);
    constant ENTER_ARR          : charArray(0 to 19) := toCharArray(ENTER_STR);
    constant BLANK_ARR          : charArray(0 to 19) := toCharArray(BLANK_STR);
    
    constant FLT_ARR            : charArray(0 to 19) := toCharArray(FLT_STR);
    constant TIME_ARR           : charArray(0 to 19) := toCharArray(TIME_STR);
    constant LAT_ARR            : charArray(0 to 19) := toCharArray(LAT_STR);
    constant LONG_ARR           : charArray(0 to 19) := toCharArray(LONG_STR);
    constant AZ_ARR             : charArray(0 to 19) := toCharArray(AZ_STR);
    constant RANGE_ARR          : charArray(0 to 19) := toCharArray(RANGE_STR);
    constant RH_ARR             : charArray(0 to 19) := toCharArray(RH_STR);
    constant RDR_ARR            : charArray(0 to 19) := toCharArray(RDR_STR);
        
        variable temp_mem : ramType := (others => (others => '0'));
    begin
/*
        for i in ramType'range loop
            temp_mem(i) := std_logic_vector(to_unsigned(i,dataLength));
        end loop;
*/
        if (iDataA'length = 8) then
            -- Left window
            for i in FLIGHT_NUM_ARR'range loop
                temp_mem(i+(64*2)+2) := FLIGHT_NUM_ARR(i);
            end loop;

            for i in BLANK_ARR'range loop
                temp_mem(i+(64*3)+2) := BLANK_ARR(i);
            end loop;

            for i in SIX_DIGITS_ARR'range loop
                temp_mem(i+(64*4)+2) := SIX_DIGITS_ARR(i);
            end loop;

            for i in BLANK_ARR'range loop
                temp_mem(i+(64*5)+2) := BLANK_ARR(i);
            end loop;

            for i in POUNDS_ARR'range loop
                temp_mem(i+(64*6)+2) := POUNDS_ARR(i);
            end loop;
            
            for i in BLANK_ARR'range loop
                temp_mem(i+(64*7)+2) := BLANK_ARR(i);
            end loop;

            for i in INPUT_ARR'range loop
                temp_mem(i+(64*8)+2) := INPUT_ARR(i);
            end loop;

            for i in ENTER_ARR'range loop
                temp_mem(i+(64*9)+2) := ENTER_ARR(i);
            end loop;

            -- Right window
            for i in FLT_ARR'range loop
                temp_mem(i+(64*2)+30) := FLT_ARR(i);
            end loop;

            for i in TIME_ARR'range loop
                temp_mem(i+(64*3)+30) := TIME_ARR(i);
            end loop;

            for i in LAT_ARR'range loop
                temp_mem(i+(64*4)+30) := LAT_ARR(i);
            end loop;

            for i in LONG_ARR'range loop
                temp_mem(i+(64*5)+30) := LONG_ARR(i);
            end loop;

            for i in AZ_ARR'range loop
                temp_mem(i+(64*6)+30) := AZ_ARR(i);
            end loop;

            for i in RANGE_ARR'range loop
                temp_mem(i+(64*7)+30) := RANGE_ARR(i);
            end loop;

            for i in RH_ARR'range loop
                temp_mem(i+(64*8)+30) := RH_ARR(i);
            end loop;

            for i in RDR_ARR'range loop
                temp_mem(i+(64*9)+30) := RDR_ARR(i);
            end loop;
        end if;
        
        return temp_mem;
    end function;

    
    shared variable RAM : ramType := initMemory(iDataA'length);

begin
    process(iClkA)
    begin
        if rising_edge(iClkA) then
            if iEnA = '1' then
                oDataA <= RAM(to_integer(unsigned(iAddrA)));
                if iWrEnA = '1' then
                    RAM(to_integer(unsigned(iAddrA))) := iDataA;
                end if;
            end if;
        end if;
    end process;
 
    process(iClkB)
    begin
        if rising_edge(iClkB) then
            if iEnB = '1' then
                oDataB <= RAM(to_integer(unsigned(iAddrB)));
                if iWrEnB = '1' then
                    RAM(to_integer(unsigned(iAddrB))) := iDataB;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
