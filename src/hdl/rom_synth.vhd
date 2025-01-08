/*
-- @file rom_synth.vhd
-- @brief ROM containing instructions
-- @author Justin Davis
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

entity rom_synth is 
    port (  iAddr   : in    slv;
            oData   :   out slv(7 downto 0));
end entity rom_synth;

architecture rtl of rom_synth is
    type rom_type is array (0 to (2**iAddr'length)-1) of std_logic_vector(oData'range);
    signal rom : rom_type := ( 

 0 =>x"C2",  1=>x"00", -- st [80,D] AC-- store AC to 0x8000-- save register states
 2 =>x"C3",  3=>x"01", -- st [80,D] Y-- store Y  to 0x8001
 4 =>x"10",  5=>x"38", -- ld X D-- Set X to 0x55--reload timer
 6 =>x"01",  7=>x"03", -- ld [80,D] MEM-- Load BOOTCNT--check if booting finished
 8 =>x"60",  9=>x"37", -- xor AC D--XOR compare 55 with BOOTCNT
 10 =>x"EC",  11=>x"2E", -- bne 0 D-- branch to BOOT_VECTOR if not equal
 12 =>x"00",  13=>x"00", -- ld AC D-- clear registers-- VIDEO_HANDLER
 14 =>x"14",  15=>x"00", -- ld y D
 16 =>x"01",  17=>x"00", -- ld [80,D],AC MEM--load AC--restore registers
 18 =>x"15",  19=>x"01", -- ld [80,D],Y MEM-- load Y
 20 =>x"E3",  21=>x"00", -- reti 0 0-- return from interrupt
 22 =>x"02",  23=>x"00", -- nop 0 0
 24 =>x"02",  25=>x"00", -- nop 0 0
 26 =>x"02",  27=>x"00", -- nop 0 0
 28 =>x"02",  29=>x"00", -- nop 0 0
 30 =>x"02",  31=>x"00", -- nop 0 0
 32 =>x"02",  33=>x"00", -- nop 0 0
 34 =>x"02",  35=>x"00", -- nop 0 0
 36 =>x"02",  37=>x"00", -- nop 0 0
 38 =>x"02",  39=>x"00", -- nop 0 0
 40 =>x"02",  41=>x"00", -- nop 0 0
 42 =>x"02",  43=>x"00", -- nop 0 0
 44 =>x"02",  45=>x"00", -- nop 0 0
 46 =>x"00",  47=>x"37", -- ld AC D-- BOOT_VECTOR
 48 =>x"C2",  49=>x"03", -- st [80,D] AC-- store 55 to  BOOTCNT
 50 =>x"00",  51=>x"00", -- ld AC D--initialize AC with 0-- main test program:store value to memory, load it back, add to it, repeat
 52 =>x"C2",  53=>x"04", -- st [80,D] AC--store value-- MAIN_LOOP
 54 =>x"01",  55=>x"04", -- ld [80,D] MEM--load value
 56 =>x"80",  57=>x"01", -- add AC D--add 1
 58 =>x"1A",  59=>x"00", -- ld VID AC-- copy result to VID output incrementing X for testing
 60 =>x"FC",  61=>x"34", -- bra 0 D-- branch back to MAIN_LOOP

    ----------------------------------------------------------
    ------        X Lookup Table                       -------
    ----------------------------------------------------------

    16128 =>x"00", --3F00
    16129 =>x"01", --3F01
    16130 =>x"02", --3F02
    16131 =>x"03", --3F03
    16132 =>x"04", --3F04
    16133 =>x"05", --3F05
    16134 =>x"06", --3F06
    16135 =>x"07", --3F07
    16136 =>x"08", --3F08
    16137 =>x"09", --3F09
    16138 =>x"0A", --3F0A
    16139 =>x"0B", --3F0B
    16140 =>x"0C", --3F0C
    16141 =>x"0D", --3F0D
    16142 =>x"0E", --3F0E
    16143 =>x"0F", --3F0F
    16144 =>x"10", --3F10
    16145 =>x"11", --3F11
    16146 =>x"12", --3F12
    16147 =>x"13", --3F13
    16148 =>x"14", --3F14
    16149 =>x"15", --3F15
    16150 =>x"16", --3F16
    16151 =>x"17", --3F17
    16152 =>x"18", --3F18
    16153 =>x"19", --3F19
    16154 =>x"1A", --3F1A
    16155 =>x"1B", --3F1B
    16156 =>x"1C", --3F1C
    16157 =>x"1D", --3F1D
    16158 =>x"1E", --3F1E
    16159 =>x"1F", --3F1F
    16160 =>x"20", --3F20
    16161 =>x"21", --3F21
    16162 =>x"22", --3F22
    16163 =>x"23", --3F23
    16164 =>x"24", --3F24
    16165 =>x"25", --3F25
    16166 =>x"26", --3F26
    16167 =>x"27", --3F27
    16168 =>x"28", --3F28
    16169 =>x"29", --3F29
    16170 =>x"2A", --3F2A
    16171 =>x"2B", --3F2B
    16172 =>x"2C", --3F2C
    16173 =>x"2D", --3F2D
    16174 =>x"2E", --3F2E
    16175 =>x"2F", --3F2F
    16176 =>x"30", --3F30
    16177 =>x"31", --3F31
    16178 =>x"32", --3F32
    16179 =>x"33", --3F33
    16180 =>x"34", --3F34
    16181 =>x"35", --3F35
    16182 =>x"36", --3F36
    16183 =>x"37", --3F37
    16184 =>x"38", --3F38
    16185 =>x"39", --3F39
    16186 =>x"3A", --3F3A
    16187 =>x"3B", --3F3B
    16188 =>x"3C", --3F3C
    16189 =>x"3D", --3F3D
    16190 =>x"3E", --3F3E
    16191 =>x"3F", --3F3F
    16192 =>x"40", --3F40
    16193 =>x"41", --3F41
    16194 =>x"42", --3F42
    16195 =>x"43", --3F43
    16196 =>x"44", --3F44
    16197 =>x"45", --3F45
    16198 =>x"46", --3F46
    16199 =>x"47", --3F47
    16200 =>x"48", --3F48
    16201 =>x"49", --3F49
    16202 =>x"4A", --3F4A
    16203 =>x"4B", --3F4B
    16204 =>x"4C", --3F4C
    16205 =>x"4D", --3F4D
    16206 =>x"4E", --3F4E
    16207 =>x"4F", --3F4F
    16208 =>x"50", --3F50
    16209 =>x"51", --3F51
    16210 =>x"52", --3F52
    16211 =>x"53", --3F53
    16212 =>x"54", --3F54
    16213 =>x"55", --3F55
    16214 =>x"56", --3F56
    16215 =>x"57", --3F57
    16216 =>x"58", --3F58
    16217 =>x"59", --3F59
    16218 =>x"5A", --3F5A
    16219 =>x"5B", --3F5B
    16220 =>x"5C", --3F5C
    16221 =>x"5D", --3F5D
    16222 =>x"5E", --3F5E
    16223 =>x"5F", --3F5F
    16224 =>x"60", --3F60
    16225 =>x"61", --3F61
    16226 =>x"62", --3F62
    16227 =>x"63", --3F63
    16228 =>x"64", --3F64
    16229 =>x"65", --3F65
    16230 =>x"66", --3F66
    16231 =>x"67", --3F67
    16232 =>x"68", --3F68
    16233 =>x"69", --3F69
    16234 =>x"6A", --3F6A
    16235 =>x"6B", --3F6B
    16236 =>x"6C", --3F6C
    16237 =>x"6D", --3F6D
    16238 =>x"6E", --3F6E
    16239 =>x"6F", --3F6F
    16240 =>x"70", --3F70
    16241 =>x"71", --3F71
    16242 =>x"72", --3F72
    16243 =>x"73", --3F73
    16244 =>x"74", --3F74
    16245 =>x"75", --3F75
    16246 =>x"76", --3F76
    16247 =>x"77", --3F77
    16248 =>x"78", --3F78
    16249 =>x"79", --3F79
    16250 =>x"7A", --3F7A
    16251 =>x"7B", --3F7B
    16252 =>x"7C", --3F7C
    16253 =>x"7D", --3F7D
    16254 =>x"7E", --3F7E
    16255 =>x"7F", --3F7F
    16256 =>x"80", --3F80
    16257 =>x"81", --3F81
    16258 =>x"82", --3F82
    16259 =>x"83", --3F83
    16260 =>x"84", --3F84
    16261 =>x"85", --3F85
    16262 =>x"86", --3F86
    16263 =>x"87", --3F87
    16264 =>x"88", --3F88
    16265 =>x"89", --3F89
    16266 =>x"8A", --3F8A
    16267 =>x"8B", --3F8B
    16268 =>x"8C", --3F8C
    16269 =>x"8D", --3F8D
    16270 =>x"8E", --3F8E
    16271 =>x"8F", --3F8F
    16272 =>x"90", --3F90
    16273 =>x"91", --3F91
    16274 =>x"92", --3F92
    16275 =>x"93", --3F93
    16276 =>x"94", --3F94
    16277 =>x"95", --3F95
    16278 =>x"96", --3F96
    16279 =>x"97", --3F97
    16280 =>x"98", --3F98
    16281 =>x"99", --3F99
    16282 =>x"9A", --3F9A
    16283 =>x"9B", --3F9B
    16284 =>x"9C", --3F9C
    16285 =>x"9D", --3F9D
    16286 =>x"9E", --3F9E
    16287 =>x"9F", --3F9F
    16288 =>x"A0", --3FA0
    16289 =>x"A1", --3FA1
    16290 =>x"A2", --3FA2
    16291 =>x"A3", --3FA3
    16292 =>x"A4", --3FA4
    16293 =>x"A5", --3FA5
    16294 =>x"A6", --3FA6
    16295 =>x"A7", --3FA7
    16296 =>x"A8", --3FA8
    16297 =>x"A9", --3FA9
    16298 =>x"AA", --3FAA
    16299 =>x"AB", --3FAB
    16300 =>x"AC", --3FAC
    16301 =>x"AD", --3FAD
    16302 =>x"AE", --3FAE
    16303 =>x"AF", --3FAF
    16304 =>x"B0", --3FB0
    16305 =>x"B1", --3FB1
    16306 =>x"B2", --3FB2
    16307 =>x"B3", --3FB3
    16308 =>x"B4", --3FB4
    16309 =>x"B5", --3FB5
    16310 =>x"B6", --3FB6
    16311 =>x"B7", --3FB7
    16312 =>x"B8", --3FB8
    16313 =>x"B9", --3FB9
    16314 =>x"BA", --3FBA
    16315 =>x"BB", --3FBB
    16316 =>x"BC", --3FBC
    16317 =>x"BD", --3FBD
    16318 =>x"BE", --3FBE
    16319 =>x"BF", --3FBF
    16320 =>x"C0", --3FC0
    16321 =>x"C1", --3FC1
    16322 =>x"C2", --3FC2
    16323 =>x"C3", --3FC3
    16324 =>x"C4", --3FC4
    16325 =>x"C5", --3FC5
    16326 =>x"C6", --3FC6
    16327 =>x"C7", --3FC7
    16328 =>x"C8", --3FC8
    16329 =>x"C9", --3FC9
    16330 =>x"CA", --3FCA
    16331 =>x"CB", --3FCB
    16332 =>x"CC", --3FCC
    16333 =>x"CD", --3FCD
    16334 =>x"CE", --3FCE
    16335 =>x"CF", --3FCF
    16336 =>x"D0", --3FD0
    16337 =>x"D1", --3FD1
    16338 =>x"D2", --3FD2
    16339 =>x"D3", --3FD3
    16340 =>x"D4", --3FD4
    16341 =>x"D5", --3FD5
    16342 =>x"D6", --3FD6
    16343 =>x"D7", --3FD7
    16344 =>x"D8", --3FD8
    16345 =>x"D9", --3FD9
    16346 =>x"DA", --3FDA
    16347 =>x"DB", --3FDB
    16348 =>x"DC", --3FDC
    16349 =>x"DD", --3FDD
    16350 =>x"DE", --3FDE
    16351 =>x"DF", --3FDF
    16352 =>x"E0", --3FE0
    16353 =>x"E1", --3FE1
    16354 =>x"E2", --3FE2
    16355 =>x"E3", --3FE3
    16356 =>x"E4", --3FE4
    16357 =>x"E5", --3FE5
    16358 =>x"E6", --3FE6
    16359 =>x"E7", --3FE7
    16360 =>x"E8", --3FE8
    16361 =>x"E9", --3FE9
    16362 =>x"EA", --3FEA
    16363 =>x"EB", --3FEB
    16364 =>x"EC", --3FEC
    16365 =>x"ED", --3FED
    16366 =>x"EE", --3FEE
    16367 =>x"EF", --3FEF
    16368 =>x"F0", --3FF0
    16369 =>x"F1", --3FF1
    16370 =>x"F2", --3FF2
    16371 =>x"F3", --3FF3
    16372 =>x"F4", --3FF4
    16373 =>x"F5", --3FF5
    16374 =>x"F6", --3FF6
    16375 =>x"F7", --3FF7
    16376 =>x"F8", --3FF8
    16377 =>x"F9", --3FF9
    16378 =>x"FA", --3FFA
    16379 =>x"FB", --3FFB
    16380 =>x"FC", --3FFC
    16381 =>x"FD", --3FFD
    16382 =>x"FE", --3FFE
    16383 =>x"FF", --3FFF


    others => (others=>'0')
    );

begin
       oData <= rom(to_integer(unsigned(iAddr)));
end rtl;
