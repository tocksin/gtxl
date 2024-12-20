/*
-- @file tb_alm.vhd
-- @brief testbench for the alu
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
library std;            use std.env.all;

library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;
                        
library work;           use work.tools_pkg.all;
                        use work.sys_description_pkg.all;
                        

entity tb_alu is
end entity tb_alu;

architecture Behavioral of tb_alu is

    signal leftData     : slv(7 downto 0);
    signal rightData    : slv(7 downto 0);
    signal resultData   : slv(7 downto 0);
    signal carry        : sl;
    signal operation    : slv(4 downto 0);
    signal inst         : slv(2 downto 0);
    signal expectData   : slv(7 downto 0);
    signal opName       : string(1 to 3);
    
begin

    dut: entity work.alu
    port map(   iDataA      => rightData,
                iDataB      => leftData,
                iOp         => operation,
                oData       => resultData,
                oCarry      => carry);

    -- Instruction  Left    Right       CIN     Result
    -- 000     LD      0       B           0       B
    -- 001     AND     0       A AND B     0       A AND B 
    -- 010     OR      0       A OR B      0       A OR B
    -- 011     XOR     0       A XOR B     0       A XOR B 
    -- 100     ADD     A       B           0       A + B 
    -- 101     SUB     A       NOT B       1       A - B
    -- 110     ST      A       0           0       A
    -- 111     Bcc     0       NOT A       1       -A
    
    operation(0) <= '1' when inst="101" or inst="111" else '0';

    operation(1) <= '1' when inst="010" or inst="011" or inst="101" else '0';

    operation(2) <= '1' when inst="000" or inst="010" or inst="011" or
                             inst="100" or inst="111" else '0';
    
    operation(3) <= '1' when inst="000" or inst="001" or inst="010" or 
                             inst="100" else '0';
                             
    operation(4) <= '1' when inst="000" or inst="001" or inst="010" or
                             inst="011" or inst="111" else '0';
    
    initializeProc: process
    begin
        leftData <= x"46";
        rightData <= x"BD";
        wait for 10ps; 
        
        inst <= "000"; -- LD
        opName <= " LD";
        expectData <= rightData;
        wait for 10ns;
        assert resultData = expectData
            report "result for LD incorrect";
        
        inst <= "001"; -- AND
        opName <= "AND";
        expectData <= (leftData and rightData);
        wait for 10ns;
        assert resultData = expectData
            report "result for AND incorrect";

        inst <= "010"; -- OR
        opName <= " OR";
        expectData <= (leftData or rightData);
        wait for 10ns;
        assert resultData = expectData
            report "result for OR incorrect";

        inst <= "011"; -- XOR
        opName <= "XOR";
        expectData <= (leftData xor rightData);
        wait for 10ns;
        assert resultData = expectData
            report "result for XOR incorrect";

        inst <= "100"; -- ADD
        opName <= "ADD";
        expectData <= slv(unsigned(leftData) + unsigned(rightData));
        wait for 10ns;
        assert resultData = expectData
            report "result for ADD incorrect";

        inst <= "101"; -- SUB
        opName <= "SUB";
        expectData <= slv(unsigned(leftData) - unsigned(rightData));
        wait for 10ns;
        assert resultData = expectData
            report "result for SUB incorrect";

        inst <= "110"; -- ST
        opName <= " ST";
        expectData <= leftData;
        wait for 10ns;
        assert resultData = expectData
            report "result for ST incorrect";

        inst <= "111"; -- Bcc
        opName <= "Bcc";
        expectData <= slv(0 - unsigned(leftData));
        wait for 10ns;
        assert resultData = expectData
            report "result for Bcc incorrect";
            
        wait;
    end process initializeProc;
    
    -------------------------------------------------------------------------------
    -- initialize
    -------------------------------------------------------------------------------
    Initialize: process
    begin
        if (now = 0 ps) then
        end if;
        --stop;
        wait;
    end process Initialize;
        
end Behavioral;
