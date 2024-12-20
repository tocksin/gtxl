/*
-- @file tb_basys_demo.vhd
-- @brief Top level testbench for the basys_demo
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
                        

entity tb_basys_demo is
end tb_basys_demo;

architecture Behavioral of tb_basys_demo is

    signal switches         : slv(15 downto 0)  := x"ABCD";
    signal buttons          : slv(4 downto 0);
    signal clkSys           : sl                := '0';
    signal rstSys           : sl                := '1';
    signal leds             : slv(15 downto 0);
    signal sevensegCA       : slv(7 downto 0);
    signal sevensegAN       : slv(3 downto 0);
    signal uartFromDut      : sl;
    signal uartToDut        : sl;
    signal vgaRed           : slv(3 downto 0);
    signal vgaBlue          : slv(3 downto 0);
    signal vgaGreen         : slv(3 downto 0);
    signal vgaVertSync      : sl;
    signal vgaHorSync       : sl;
    signal ps2Clk           : sl;
    signal ps2Data          : sl;
    
    signal recvByte         : slv(7 downto 0);
    signal uartStrb         : sl;
    signal recvFifoData     : slv(7 downto 0);
    signal readFifo         : sl := '0';
    signal emptyFifo        : sl;
    
    signal uartFull         : sl;
    signal sendEn           : sl;
    signal sendByte         : slv(7 downto 0);
    
    signal testHexChar      : character := 'A';
    signal testHexStr       : string(1 to 4) := "A-HL";
    signal testslv          : slv(3 downto 0) := "000-";
    
    signal pmodB            : slv(4 downto 0);
    signal sync             : sl;
    signal blank            : sl;
    signal grayLevel        : slv(2 downto 0);
    signal analogLevel      : signed(8 downto 0);

begin

    clkSys <= not clkSys after INPUT_CLOCK_PERIOD/2;
    rstSys <= '1', '0' after 1us;
    ps2Clk <= 'H';
    ps2Data <= 'H';

    dut: entity work.basys_top(Behavioral)
    port map( 
            SW          => switches,
            BTN         => buttons,
            CLK         => clkSys,
            LED         => leds,
            SSEG_CA     => sevensegCA,
            SSEG_AN     => sevensegAN,
            uartTxOut   => uartFromDut,
            uartRxIn    => uartToDut,
            VGA_RED     => vgaRed,
            VGA_BLUE    => vgaBlue,
            VGA_GREEN   => vgaGreen,
            VGA_VS      => vgaVertSync,
            VGA_HS      => vgaHorSync,
            PS2_CLK     => ps2Clk,
            PS2_DATA    => ps2Data,
            JB          => pmodB
        );

    sync <= pmodB(0);
    blank <= pmodB(1);
    grayLevel(0) <= pmodB(2);
    grayLevel(1) <= pmodB(3);
    grayLevel(2) <= pmodB(4);
    
    grayLevel <= "LLL";
    
    initializeProc: process
    begin
        buttons <= "00000";
        wait for 1ms;
        buttons <= "00001";
        wait for 1ms;
        buttons <= "00000";
        wait for 1ms;
        buttons <= "01111";
        wait for 1ms;
        buttons <= "00000";
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
