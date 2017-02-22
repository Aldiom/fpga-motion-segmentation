
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

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:44:53 11/14/2006 
-- Design Name: 
-- Module Name:    RS_FF - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RS_FF is
    Port ( clk : in  STD_LOGIC;
           reset : in std_logic;
           R : in  STD_LOGIC;
           S : in  STD_LOGIC;
           Q : out  STD_LOGIC);
end RS_FF;

architecture Behavioral of RS_FF is

begin

   process(clk, reset,R,S)
      variable q_int : std_logic := '0';
   begin
      if (reset = '1') then
         q_int := '0';
         Q <= '0';
      elsif (rising_edge(clk)) then
         if (R='1') then
            q_int := '0';
         elsif (S='1') then
            q_int := '1';
         end if;
         
         Q <= q_int;
      end if;
   end process;

end Behavioral;

