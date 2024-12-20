-- @file sys_description_pkg.vhd
-- @brief 
-- @author Justin Davis
--
-- Revision: -
-- Date: 05/05/2023
-- LastEditedBy: 
--
-- Copyright: 2023 Southwest Research Institute
-------------------------------------------------------------------------------
--
-- $Log: $
-------------------------------------------------------------------------------

library ieee;       use ieee.std_logic_1164.all;
                    use ieee.numeric_std.all;
                    
library work;       use work.tools_pkg.all;

package sys_description_pkg is

    -- Clock periods
    constant INPUT_CLOCK_PERIOD           : time    :=   10 ns; -- 100 MHz
    constant SYS_CLOCK_PERIOD             : time    :=   INPUT_CLOCK_PERIOD/2;
    constant COMP_CLOCK_PERIOD            : time    :=   103.83 ns; -- 9.631 MHz
    constant HEARTBEAT_PERIOD             : time    :=  1000 ms; -- 1 Hz
    constant HEARTBEAT_CNTS               : integer := HEARTBEAT_PERIOD / COMP_CLOCK_PERIOD;
    constant HEARTBEAT_CNT_SIZE           : natural := log2(HEARTBEAT_CNTS,UP);
    constant UART_BAUD                    : integer := 9600;
    
    constant MEM_MAP_GBL : memMapRecArrayType := (
        memRec("BOOT VECTOR"         , x"0000",             RO, x"0300"),
        memRec("PROGRAM COUNTER"     , x"0001",             RW),
        memRec("POINTER ADDR"        , x"0005",             RW),
        memRec("BREAK"               , x"0008",             WO), -- writing here stops CPU
        memRec("POINTER DATA"        , x"0010",             RW),
        memRec("GIT HASH LO"         , x"0011",             RO),
        memRec("GIT HASH HI"         , x"0012",             RO),
        memRec("DATE CODE LO"        , x"0013",             RO),
        memRec("DATE CODE HI"        , x"0014",             RO),

        memRec("DIP SWITCHES"        , x"0020",             RO),
        memRec("LEDS"                , x"0022",             WO),
        memRec("SSEG"                , x"0024",             WO),
        memRec("UART DATA"           , x"0030",             RW),
        memRec("UART TX FULL"        , x"0038",             RO),
        memRec("UART RX EMPTY"       , x"0039",             RO),

        memRec("PRNG"                , x"0040",             RO),

        memRec("MATH"                , x"005-",             RW), -- Group: Math
        memRec("A REGISTER"          , x"0050",             RW), -- Storage for first math operand
        memRec("INC"                 , x"0051",             RO), -- A+1
        memRec("DEC"                 , x"0052",             RO), -- A-1
        memRec("ADD"                 , x"0053",             RW), -- A+B
        memRec("SUB"                 , x"0054",             RW), -- A-B
        memRec("EQUAL"               , x"0055",             RW), -- ? A=B (1 for true, 0 for false)
        memRec("NOT EQUAL"           , x"0056",             RW), -- ? A!=B (1 for true, 0 for false)
        memRec("GREATER THAN"        , x"0057",             RW), -- ? A>B (1 for true, 0 for false)
        memRec("LESS THAN"           , x"0058",             RW), -- ? A<B (1 for true, 0 for false)
        memRec("IS ZERO"             , x"0059",             RO), -- ? A=0 (1 for true, 0 for false)
        memRec("IS ONE"              , x"005A",             RO), -- ? A=1 (1 for true, 0 for false)
        memRec("IS NOT ZERO"         , x"005B",             RO), -- ? A=0 (1 for true, 0 for false)
        memRec("IS NOT ONE"          , x"005C",             RO), -- ? A=1 (1 for true, 0 for false)
        memRec("SUM1"                , x"005D",             RO), -- Counts all 1s in A
        memRec("SUM0"                , x"005E",             RO), -- Counts all 0s in A

        memRec("LOGIC"               , x"006-",             RW), -- Group: Logic (bitwise)
        memRec("NOT"                 , x"0060",             RO), -- Invert of A
        memRec("AND"                 , x"0061",             RW), -- A and B
        memRec("NAND"                , x"0062",             RW), -- A nand B
        memRec("OR"                  , x"0063",             RW), -- A or B
        memRec("NOR"                 , x"0064",             RW), -- A nor B
        memRec("XOR"                 , x"0065",             RW), -- A xor B
        memRec("XNOR"                , x"0066",             RW), -- A xnor B

        -- Write value to shift to register.  Read from register the shifted value
        memRec("SHIFT"               , x"007-",             RW), -- Group: Shift
        memRec("SHIFT LEFT 0"        , x"0070",             RO),
        memRec("SHIFT LEFT 1"        , x"0071",             RO),
        memRec("SHIFT RIGHT 0"       , x"0072",             RO),
        memRec("SHIFT RIGHT 1"       , x"0073",             RO),
        memRec("ROTATE LEFT"         , x"0074",             RO),
        memRec("ROTATE RIGHT"        , x"0075",             RO),
        memRec("SWAP HI LO"          , x"0076",             RO),

        memRec("VERSION"             , x"008-",             RW),
                
        memRec("ROM"                 , "0---------------",  RO),
        memRec("RAM"                 , "1---------------",  RW)
    );
    

   
end sys_description_pkg;

package body sys_description_pkg is


end sys_description_pkg;