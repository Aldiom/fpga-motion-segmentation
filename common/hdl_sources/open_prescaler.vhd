
--Copyright 2007-2010, Embedded Software Group at the University of
--Waterloo. All rights reserved.  By using this software the USER
--indicates that he or she has read, understood and will comply with the
--following:

--- Embedded Software Group at the University of Waterloo hereby
--grants USER nonexclusive permission to use, copy and/or modify this
--software for internal, noncommercial, research purposes only. Any
--distribution, including commercial sale or license, of this software,
--copies of the software, its associated documentation and/or
--modifications of either is strictly prohibited without the prior
--consent of the Embedded Software Group at the University of Waterloo.
--Title to copyright to this software and its associated documentation
--shall at all times remain with the Embedded Software Group at the
--University of Waterloo.  Appropriate copyright notice shall be placed
--on all software copies, and a complete copy of this notice shall be
--included in all copies of the associated documentation.  No right is
--granted to use in advertising, publicity or otherwise any trademark,
--service mark, or the name of the Embedded Software Group at the
--University of Waterloo.


--- This software and any associated documentation is provided "as is"

--THE EMBEDDED SOFTWARE GROUP AT THE UNIVERSITY OF WATERLOO MAKES NO
--REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, INCLUDING THOSE OF
--MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, OR THAT USE OF
--THE SOFTWARE, MODIFICATIONS, OR ASSOCIATED DOCUMENTATION WILL NOT
--INFRINGE ANY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER INTELLECTUAL
--PROPERTY RIGHTS OF A THIRD PARTY.

--The Embedded Software Group at the University of Waterloo shall not be
--liable under any circumstances for any direct, indirect, special,
--incidental, or consequential damages with respect to any claim by USER
--or any third party on account of or arising from the use, or inability
--to use, this software or its associated documentation, even if The
--Embedded Software Group at the University of Waterloo has been advised
--of the possibility of those damages.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity open_prescaler is
    Port ( clk : in std_logic;
           rst : in std_logic;
           en : in std_logic;
           pulse : out std_logic;
           divider : in std_logic_vector(10 downto 0));
end open_prescaler;

architecture Behavioral of open_prescaler is
begin

	-- create 1 MHz base clock - change this for other master clock frequencies
	MHz_clk : process (rst, clk)
		variable cnt : std_logic_vector(10 downto 0) := (others => '0');
	begin
		if (rst = '1') then
			cnt := (others => '0');
			pulse <= '0';
		elsif (clk'event and clk = '1') then
         if (en = '1') then
            cnt := cnt + 1;

            if (cnt = divider) then			 
               pulse <= '1';
               cnt := (others => '0');
            else
               pulse <= '0';
            end if;
         else
            pulse <= '0';
         end if;
		end if;
	end process;

end Behavioral;
