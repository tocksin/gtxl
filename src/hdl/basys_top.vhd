/*
* @file basys_top.vhd
* @brief Top level design for the BASYS3 development board.
*        Experimental test platform for various ideas.
* @author Justin Davis
*
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
**************************************************************************/
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;

library unisim;         use unisim.vcomponents.all;

library work;           use work.sys_description_pkg.all;
                        use work.tools_pkg.all;

entity basys_top is
    port ( SW           : in  slv (15 downto 0);
           BTN          : in  slv (4 downto 0);
           CLK          : in  sl;
           LED          : out  slv (15 downto 0);
           SSEG_CA      : out  slv (7 downto 0);
           SSEG_AN      : out  slv (3 downto 0);
           uartTxOut    : out  sl;
           uartRxIn     : in   sl;
           VGA_RED      : out  slv (3 downto 0);
           VGA_BLUE     : out  slv (3 downto 0);
           VGA_GREEN    : out  slv (3 downto 0);
           VGA_VS       : out  sl;
           VGA_HS       : out  sl;
           PS2_CLK      : inout sl;
           PS2_DATA     : inout sl;
           JB           : out   slv(4 downto 0)
    );
end entity basys_top;

architecture Behavioral of basys_top is

    attribute IOB : string;
    attribute IOB of SW         : signal is "TRUE";
    attribute IOB of BTN        : signal is "TRUE";
    attribute IOB of LED        : signal is "TRUE";
    attribute IOB of SSEG_CA    : signal is "TRUE";
    attribute IOB of SSEG_AN    : signal is "TRUE";
    attribute IOB of uartTxOut  : signal is "TRUE";
    attribute IOB of uartRxIn   : signal is "TRUE";
    attribute IOB of VGA_RED    : signal is "TRUE";
    attribute IOB of VGA_BLUE   : signal is "TRUE";
    attribute IOB of VGA_GREEN  : signal is "TRUE";
    attribute IOB of VGA_VS     : signal is "TRUE";
    attribute IOB of VGA_HS     : signal is "TRUE";
    attribute IOB of PS2_CLK    : signal is "TRUE";
    attribute IOB of PS2_DATA   : signal is "TRUE";

    component clk_wiz_0
    port
     (-- Clock in ports
      clk_in1           : in     sl;
      -- Clock out ports
      clk_out1          : out    sl;
      reset             : in     sl;
      locked            : out    sl
     );
    end component;


    constant TMR_CNTR_INT   : integer := 100000000;
    constant TMR_CNTR_SIZE  : integer := log2(TMR_CNTR_INT,UP);
    constant TMR_CNTR_MAX   : slv(TMR_CNTR_SIZE-1 downto 0) := slv(to_unsigned(TMR_CNTR_INT, TMR_CNTR_SIZE));

    constant TMR_VAL_MAX    : slv(3 downto 0) := "1111"; --9

    constant DEBOUNCE_CLKS  : integer := 2**16
    -- synthesis translate_off
     -2**16 + 10              -- reduce debounce time to 10 clocks in simulation
    -- synthesis translate_on
    ;

    --Used to determine when a button press has occured
    signal btnReg    : slv (3 downto 0);
    signal btnPulse  : slv (3 downto 0);

    --Debounced btn signals used to prevent single button presses
    --from being interpreted as multiple button presses.
    signal btnDeBnc         : slv(4 downto 0);

    signal clkSys        : sl;

    signal rstSys        : sl;
    signal rstBtn           : sl;
    signal locked           : sl;

    signal dipR             : slv(15 downto 0);
    signal dipRR            : slv(15 downto 0);
    signal dipEn            : sl;

    signal ledR             : slv(15 downto 0);
    signal ledEn            : sl;

    signal ssegR            : slv(15 downto 0);

    signal bootEn           : sl;

    signal aluEn            : sl;
    signal dataFromALU      : slv(15 downto 0);
    signal shiftEn          : sl;

    signal graylevel        : slv(2 downto 0);
    signal sync             : sl;
    signal blank            : sl;
    
    signal pixel            : slv(7 downto 0);
begin

--    rstBtn <= '0';
    rstBtn <= BTN(4);

    -- 160 pixels per line (200 with blanking) and 3-bits per subpixel (4 lum levels+sync)
    -- 63.5us per line / 200 pixels = 317.5ns per pixel
    -- could have 3 subpixels and 1 sync bit as well assuming if sync is set, then it overrides all other subpixels
    -- 160 pixels with 6-bit rgb color then same as previous gigatron
    -- subpixel rate is 3x pixel rate, so 600 pixels would be possible at 2-bit color (480 visible) or 4 grayscale levels
    -- need a new pixel every 317.5ns.  new pixels come out every third clock. so clock is 317.5ns/3 = 105.83ns or 9.448MHz
    -- it might still be possible to use the 55ns SRAM, but the 15ns SRAM would be safer
    
    clk_wiz_0_inst : clk_wiz_0
    port map (
        clk_in1  => CLK,        -- expecting 100 MHz
        clk_out1 => clkSys,     -- requesting 9.448  MHz
        locked   => locked,
        reset    => rstBtn
     );

    rstSystemComp: entity work.rst_system
     generic map(ACTIVE_IN  => '0')
        port map(rstIn      => locked,
                 clkIn      => clkSys,
                 rstOut     => rstSys);

    ----------------------------------------------------------
    ------                DIP Input                    -------
    ----------------------------------------------------------
    dipProcess : process (clkSys)
    begin
        if rising_edge(clkSys) then
            dipR <= SW;
            dipRR <= dipR;
        end if;
    end process dipProcess;

    ----------------------------------------------------------
    ------                LED Control                  -------
    ----------------------------------------------------------
    ledProcess : process (clkSys, rstSys)
    begin
        if (rstSys = '1') then
            ledR <= (others => '0');
        elsif (rising_edge(clkSys)) then
            if (ledEn='1') then
--                ledR <= dataFromCpu;
            end if;
        end if;
    end process ledProcess;

    LED <= ledR;

    ----------------------------------------------------------
    ------           7-Seg Display Control             -------
    ----------------------------------------------------------
    --Digits are incremented every second, and are blanked in
    --response to button presses.
    ssegDecoderComp : entity work.sseg_decoder
        generic map(DELAY_CNTS => 100000)
        port map (
            clkIn => clkSys,
            rstIn => rstSys,
            digitsIn => ssegR,
            cathodeOut => SSEG_CA,
            anodeOut => SSEG_AN);

    ssegRegProc : process (clkSys, rstSys)
    begin
        if (rstSys = '1') then
            ssegR <= (others => '0');
        elsif (rising_edge(clkSys)) then
  --              ssegR <= dataFromCPU;
        end if;
    end process ssegRegProc;

    ----------------------------------------------------------
    ------              Button Control                 -------
    ----------------------------------------------------------
    --Buttons are debounced and their rising edges are detected
    --to trigger UART messages

    debounceComp: entity work.debouncer
        generic map(
            DEBNC_CLOCKS => DEBOUNCE_CLKS,
            PORT_WIDTH => 5)
        port map(
            clkIn => clkSys,
            rstIn => rstSys,
            rawIn => BTN,
            debouncedOut => btnDeBnc
        );

    onePulse(clkSys, rstSys, btnDeBnc(0), btnReg(0), btnPulse(0));
    onePulse(clkSys, rstSys, btnDeBnc(1), btnReg(1), btnPulse(1));
    onePulse(clkSys, rstSys, btnDeBnc(2), btnReg(2), btnPulse(2));
    onePulse(clkSys, rstSys, btnDeBnc(3), btnReg(3), btnPulse(3));


    ----------------------------------------------------------
    ------                CPU                          -------
    ----------------------------------------------------------
    cpuComp : entity work.cpu
    port map (iClk          => clkSys,
              iRst          => rstSys,
              
              oVideo        => pixel);

    ----------------------------------------------------------
    ------                RS-170                       -------
    ----------------------------------------------------------
    rs170Comp: process (clkSys, rstSys)
    begin
        if (rstSys = '1') then
        elsif (rising_edge(clkSys)) then
        end if;
    end process rs170Comp;

    -- 3.3V outputs, 75 Ohm input resistance to receiver
    -- parallel 180 Ohm resistor with component output
    JB(0) <= sync;          -- series 390 ohm
    JB(1) <= graylevel(0);  -- series 560 ohm
    JB(2) <= graylevel(1);  -- series 270 ohm

end architecture Behavioral;
