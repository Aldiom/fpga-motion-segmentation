
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
-- Create Date:    22:11:55 12/28/2006 
-- Design Name:    NCM basic
-- Module Name:    auto_receiver - Behavioral 
-- Project Name:   NCM
-- Target Devices: 
-- Tool versions: 
-- Description:    receives packets from EMAC & decodes variables into receive channels
--                 en is used to turn on/off receivers
--                 receive channels are reset automatically
--                 sync packet is decoded and shown as pulse
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

library UNISIM;
use UNISIM.VComponents.all;

use work.ncm_package.all;

entity auto_receiver is
    Port ( clk 						: in  STD_LOGIC;
           rst 						: in  STD_LOGIC;
           busy 						: out std_logic;               
           start 						: in  std_logic;
			  
			  reset_rx_fifo			: out std_logic;
			  -- emac interface
           rx_fifo_data 			: in  STD_LOGIC_VECTOR (35 downto 0);
           rx_fifo_en 				: out STD_LOGIC;
           rx_valid 					: in  STD_LOGIC;            
           rx_fifo_empty			: in  std_logic;

           NCSync_type 			: in  STD_LOGIC_VECTOR (15 downto 0);
           NCData_type 			: in  STD_LOGIC_VECTOR (15 downto 0);			  

			  -- ncm interface to rcv_fifo
           ncm_sync 					: out STD_LOGIC;
           ncm_rcv_channel 		: out STD_LOGIC_VECTOR (3 downto 0);
           ncm_rcv_en 				: out STD_LOGIC;
           ncm_rcv_data 			: out STD_LOGIC_VECTOR (31 downto 0);
           ncm_rcv_reset 			: out STD_LOGIC;
           -- statistics interface
           goodcnt_sync 			: out std_logic_vector(31 downto 0);
			  goodcnt_data 			: out std_logic_vector(31 downto 0);
			  badcnt_data				: out std_logic_vector(31 downto 0);
           nobroadcst 				: out std_logic_vector(31 downto 0);
           badcnt 					: out std_logic_vector(31 downto 0);
			  debugstate				: out std_logic_vector(3 downto 0)		  
           );
end auto_receiver;

architecture Behavioral of auto_receiver is

   type states is (s_init, s_idle, s_wait, s_dest1, s_dest2, s_src, s_type_length, s_wait_rst, s_channel, s_reset_rcv_fifo, s_data, s_rest, s_rdy);
   
--	attribute ENUM_ENCODING: STRING; 
--	attribute ENUM_ENCODING of states: type is 
--	"0000000000001 0000000000010 0000000000100 0000000001000 0000000010000 0000000100000 0000001000000 0000010000000 0000100000000 0001000000000 0010000000000 0100000000000 1000000000000";

	signal currentstate 		: states := s_init;
   signal sendsync 			: std_logic := '0';
   signal goodcnt_sync_i 	: std_logic_vector(31 downto 0) := (others => '0');
   signal goodcnt_data_i 	: std_logic_vector(31 downto 0) := (others => '0');
   signal badcnt_data_i 	: std_logic_vector(31 downto 0) := (others => '0');
	signal nobroadcst_i 		: std_logic_vector(31 downto 0) := (others => '0');
  -- signal badcnt_i 			: std_logic_vector(31 downto 0) := (others => '0');
   signal rx_data 			: std_logic_vector(31 downto 0) := (others => '0');
	signal eop					: std_logic := '0';
   signal debugstate_i 		: std_logic_vector(3 downto 0) := (others => '0');
	signal rx_fifo_en_i		: std_logic;
	signal rx_fifo_en_lock	: std_logic;

	signal reset_rx_fifo_i		: std_logic;
	
begin
   debugstate <= debugstate_i;
	rx_fifo_en <= rx_fifo_en_i and (not eop) and (not rx_fifo_empty); -- or (not rx_fifo_empty));
	reset_rx_fifo <= reset_rx_fifo_i;
	
	rx_data (31 downto 24) 	<= rx_fifo_data (34 downto 27);
   rx_data (23 downto 16) 	<= rx_fifo_data (25 downto 18);
   rx_data (15 downto 8) 	<= rx_fifo_data (16 downto 9);
   rx_data (7 downto 0) 	<=	rx_fifo_data (7 downto 0);
	
	ncm_rcv_data <= rx_data;
	
	eop <= (rx_fifo_data(35) or rx_fifo_data(26) or rx_fifo_data(17) or rx_fifo_data(8)) and not start;
	
   goodcnt_sync 	<= goodcnt_sync_i;
	goodcnt_data 	<= goodcnt_data_i;
	badcnt_data 	<= badcnt_data_i;
   nobroadcst 		<= nobroadcst_i;

   FSM : process(clk, rst)
      variable nextstate : states := s_init;
      variable cnt : integer range 0 to 1500 := 0;
		variable wait_rst : integer range 0 to 4 := 0;
   begin
      if (rst = '1') then
         currentstate <= s_init;
         nextstate := s_init;
      
      elsif (rising_edge(clk)) then
			rx_fifo_en_i 			<= '1';
         ncm_rcv_reset 		<= '0'; 
         ncm_rcv_en 			<= '0';
         busy			 		<= '1';
			nextstate := currentstate;
         goodcnt_sync_i 	<= goodcnt_sync_i + 0;
         goodcnt_data_i 	<= goodcnt_data_i + 0;
         badcnt_data_i 		<= badcnt_data_i + 0;
         
			case currentstate is
         
            when s_init => 
					wait_rst				:= 4;
					rx_fifo_en_i 			<= '0';
               goodcnt_sync_i 	<= (others => '0');
               goodcnt_data_i 	<= (others => '0');
               badcnt_data_i 			<= (others => '0');
               nobroadcst_i 		<= (others => '0');
               sendsync 			<= '0';
               nextstate := s_idle;
            
            when s_idle =>
					wait_rst := 4;
					reset_rx_fifo_i <= '0';
					ncm_sync <= '0';
					sendsync <= '0';
					busy <= '0';
					if (start = '1' and rx_fifo_empty = '0') then    -- good data available on the MAC_RX_Buffer    
						rx_fifo_en_i 	<= '1';
                  nextstate 	:= s_wait;       -- wait one cycle to get data
               else 
						rx_fifo_en_i 	<=	'0';
						nextstate 	:= s_idle;
					end if;
					debugstate_i		<= X"0";
					
            when s_wait =>
               nextstate := s_dest1;
					debugstate_i		<= X"1";
            
            when s_dest1 =>       -- dest must be broadcast - otherwise discard packet            
					if (eop = '1' or rx_fifo_empty = '1') then
						rx_fifo_en_i <= '0';
                  nextstate := s_rest;
					else
						if (rx_data = X"FFFFFFFF") then
							nextstate := s_dest2;
                  else                                -- no broadcast - abort packet
							nobroadcst_i <= nobroadcst_i + 1;
							nextstate := s_rest;
                  end if;                  
					end if;
            	debugstate_i		<= X"2";
									
            when s_dest2 =>       -- dest must be broadcast - otherwise discard packet            
					if (eop = '1' or rx_fifo_empty = '1') then						
						rx_fifo_en_i <= '0';
                  nextstate := s_rest;
					else
						if (rx_data(31 downto 16) = X"FFFF") then
							nextstate := s_src;
                  else                                -- no broadcast - abort packet
                     nobroadcst_i <= nobroadcst_i + 1;
                     nextstate := s_rest;
                  end if;                  
					end if;
					debugstate_i		<= X"3";
					
            when s_src =>        -- simply read src address
					if (eop = '1' or rx_fifo_empty = '1') then
						rx_fifo_en_i <= '0';
                  nextstate := s_rest;
					else
						nextstate := s_type_length;
					end if;
					debugstate_i		<= X"4";
					
            when s_type_length =>                               
					if (eop = '1' or rx_fifo_empty = '1') then
						rx_fifo_en_i <= '0';
                  nextstate := s_rest;
					else
						if (rx_data (31 downto 16) = NCSync_Type) then
							sendsync <= '1';							
							nextstate := s_rest;
						elsif (rx_data (31 downto 16) = NCData_Type) then
							cnt := CONV_INTEGER(rx_data(7 downto 0))+1;
							if (cnt = 1) then
								nextstate := s_rest;
							else
								ncm_rcv_reset <= '1';
								nextstate := s_channel;
							end if;
						else
								nextstate := s_rest;
						end if;
					end if;
					debugstate_i		<= X"5";
               
            when s_channel =>
					if (eop = '1' or rx_fifo_empty = '1') then
						rx_fifo_en_i <= '0';
                  nextstate := s_rest;
					else
						ncm_rcv_channel <= rx_data(31 downto 28); 
						nextstate := s_wait_rst;
						rx_fifo_en_i <= '0';
					end if;
					debugstate_i		<= X"7";

--valid data from fifo will be available in the next cycle
				when s_wait_rst =>
					rx_fifo_en_i <= '0';
					wait_rst := wait_rst - 1;
					
					if (wait_rst = 1) then
						rx_fifo_en_i <= '1';
						cnt := cnt - 1;
						ncm_rcv_en	<= '1';
						nextstate := s_wait_rst;

					elsif (wait_rst = 0) then
						rx_fifo_en_i <= '1';
						cnt := cnt - 1;
						ncm_rcv_en	<= '1';
						nextstate := s_data;
						if (cnt = 0) then    -- all got
							ncm_rcv_en <= '0';
							rx_fifo_en_i <= '0';
							goodcnt_data_i <= goodcnt_data_i + 1;
							nextstate := s_rest;
						end if;
					else
						nextstate := s_wait_rst;
					end if;

            when s_data =>       -- read data 
					if (eop = '1' or rx_fifo_empty = '1') then
						rx_fifo_en_i <= '0';
						ncm_rcv_en <= '0';
						if (cnt > 1) then
							badcnt_data_i <= badcnt_data_i + 1;
						elsif (cnt = 1) then
							goodcnt_data_i <= goodcnt_data_i + 1;
						end if;
                  nextstate := s_rest;
					else
						ncm_rcv_en <= '1';
						cnt := cnt - 1;
						if (cnt = 0) then    -- all got
							ncm_rcv_en <= '0';
							rx_fifo_en_i <= '0';
							goodcnt_data_i <= goodcnt_data_i + 1;
							nextstate := s_rest;
						else nextstate := s_data;
						end if;
					end if;
					debugstate_i		<= X"9";
            
            when s_rest =>       -- read out rest of packet until empty = 1
					if (eop = '1' or rx_fifo_empty = '1') then
						rx_fifo_en_i <= '0';
						reset_rx_fifo_i <= '1';
						nextstate := s_rdy;
					else
						nextstate := s_rest;
					end if;
					debugstate_i		<= X"A";
            
            when s_rdy =>        -- we made it
				 	if(sendsync = '1') then
						goodcnt_sync_i <= goodcnt_sync_i + 1;
					end if;
					reset_rx_fifo_i <= '0';
					rx_fifo_en_i <= '0';
               ncm_sync <= sendsync;
               busy <= '0';
               nextstate := s_idle;
					debugstate_i		<= X"B";

            when others =>
               nextstate := s_idle;       -- to be safe
					debugstate_i		<= X"C";            
			end case;
         currentstate <= nextstate;
      end if;
   end process;	
end Behavioral;