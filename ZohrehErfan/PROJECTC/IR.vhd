library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

ENTITY IR IS
PORT(clock_50 : IN std_logic;
     KEY : IN std_logic_vector(0 downto 0);
	  IRDA_RXD : IN std_logic;
	  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : OUT std_logic_vector(0 to 6)
	  );

END IR;

Architecture structure of IR IS

component bcd7seg IS   -- Definition of the other ENTITY
	PORT (C	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			H	: OUT	STD_LOGIC_VECTOR(0 TO 6));
END component bcd7seg;

signal iclk, iRST, iIRDA : std_logic;
signal oDATA, data, data_buf : std_logic_vector(31 downto 0);
signal IDLE_HIGH_DUR : integer range 0 to 262143 := 262143;--data_count 262143*0.02us=5.24ms, threshold for DATAREAD->IDLE
signal GUIDE_LOW_DUR : integer range 0 to 230000 := 230000;--idle_count 230000*0.02us=4.60ms, threshold for IDLE->GUIDANCE
signal GUIDE_HIGH_DUR : integer range 0 to 210000 := 210000;--state_count 210000*0.02us=4.20ms, 
                                      -- 4.5-4.2=0.3ms<BIT_AVAILABLE_DUR=0.4ms, threshold for GUIDANCE->DATAREAD
signal DATA_HIGH_DUR : integer range 0 to 41500 := 41500; -- data_count 41500*0.02us=0.83ms, 
                                      -- sample time from the positive_edge of iIRDA
signal BIT_AVAILABLE_DUR : integer range 0 to 20000 := 20000; -- data_count 20000*0.02us=0.4ms, 
                                      -- the sample bit pointer, can inhibit the interference from iIRDA signal
signal idle_count: integer range 0 to 230000; -- to be comparedto GUIDE_LOW_DUR
signal state_count : integer range 0 to 210000; -- to be compared to GUIDE_HIGH_DUR
signal data_count : integer range 0 to 262143; -- to be compared to IDLE_HIGH_DUR
signal HEX_idle_count, HEX_state_count, HEX_data_count : std_logic_vector(17 downto 0);
signal HEX_bitcount : std_logic_vector(5 downto 0);
signal idle_count_flag, state_count_flag, data_count_flag, data_ready : std_logic;
signal bitcount: integer range 0 to 33;
signal digit0, digit1, digit2, digit3, digit4, digit5, digit6, digit7 : std_logic_vector(3 downto 0);

-- declare (state-machine) enumerated type
type FSM_STATES IS (IDLE, GUIDANCE, DATAREAD);
-- Attribute to declare a specific encoding for the states
attribute syn_encoding : string;
attribute syn_encoding of FSM_STATES:type IS "00 01 10";

-- declare signals of FSM_STATES type
signal Present_State, Next_State : FSM_STATES;

begin
iCLK <= Clock_50;
iRST <= KEY(0);
iIRDA <= IRDA_RXD;


process (iCLK, iRST, idle_count_flag)
begin
if (rising_edge(iCLK)) then
  if (iRST = '0') then
    idle_count <= 0;
  elsif (idle_count_flag = '1') then   -- the counter works when the flag is 1
    idle_count <= idle_count + 1;  -- increment how many times the FSM has gone into the IDLE state
  else 
    idle_count <=0;              -- the counter resets if flag is 0
  end if;
end if;
end process;

process(iCLK, iRST, present_state, iIRDA)
begin
if (rising_edge(iCLK)) then
  if (iRST = '0') then
     idle_count_flag <= '0';
  elsif ((Present_State = IDLE) AND (iIRDA = '0')) then
     idle_count_flag <= '1';
  else
     idle_count_flag <= '0';
  end if;
end if;
end process;

process(iCLK, iRST, state_count_flag)
begin 
if (rising_edge(iCLK)) then
   if (iRST= '0') then
	   state_count <= 0;
	elsif (state_count_flag = '1') then
	   state_count <= state_count + 1;   -- the counter works when the flag is 1
	else
	   state_count <= 0;    -- the counter resets if flag is 0
	end if;
end if;
end process;

process(iCLK, iRST, Present_State, iIRDA)
begin
if (rising_edge(iCLK)) then
   if (iRST= '0') then
	   state_count_flag <= '0';
	elsif ((Present_State = GUIDANCE) AND (iIRDA = '1')) then
	   state_count_flag <= '1';
	else
	   state_count_flag <= '0';
	end if;
end if;
end process;

process(iCLK, iRST, data_count_flag)
begin 
if (rising_edge(iCLK)) then
   if (iRST = '0') then
	   data_count <= 0;
	elsif (data_count_flag= '1') then
	   data_count <= data_count + 1;   -- the counter works when the flag is 1
	else
	   data_count <= 0;    -- the counter resets if flag is 0
	end if;
end if;
end process;

process(iCLK, iRST, Present_State, iIRDA)
begin
if (rising_edge(iCLK)) then
   if (iRST = '0') then
	   data_count_flag <= '0';
	elsif ((Present_State = DATAREAD) AND (iIRDA = '1')) then
	   data_count_flag <= '1';
	else
	   data_count_flag <= '0';
	end if;
end if;
end process;

process(iCLK, iRST, Present_State, data_count)
begin 
if (rising_edge(iCLK)) then
   if (iRST = '0') then
	   bitcount <= 0;
   elsif (Present_State = DATAREAD) then
	   if (data_count = 20000) then
		   bitcount <= bitcount + 1;
		end if;
	else
	   bitcount <= 0;
	end if;
end if;
end process;

--- change states
process (iCLK, iRST, Present_State, idle_count, state_count, data_count, bitcount)
begin
if (rising_edge(iCLK)) then
   if (iRST = '0') then
	   Present_State <= IDLE;
		
	else
	
	   case Present_State IS
	  
	      when IDLE => 
			    if (idle_count > GUIDE_LOW_DUR) then -- State change form IDLE to GUIDANCE
			       Next_State <= GUIDANCE;
				 end if;
				 
			when GUIDANCE =>
			    if (state_count > GUIDE_HIGH_DUR) then  -- State change from GUIDANCE to DATAREAD
				    Next_State <= DATAREAD;
				 end if;
				
			when DATAREAD =>
			    if ((data_count >= IDLE_HIGH_DUR) OR (bitcount >= 33)) then 
				    Next_State <= IDLE;
				 end if;
				 
			when OTHERS => 
			    Next_State <= IDLE;   -- default
				 
			END case;
			present_state <= next_state;
    end if;
 end if;
end process;

process (iCLK, iRST, Present_State, data_count)
begin
if (rising_edge(iCLK)) then
  if (iRST = '0') then  
     data <= "00000000000000000000000000000000";
  elsif (Present_State = DATAREAD) then
     if (data_count >= DATA_HIGH_DUR) then  -- 2^15 = 32767*0.02us = 0.64ms
	     data(bitcount-1) <= '1';              
     end if;
  else
     data <= "00000000000000000000000000000000";
  end if;
end if;
end process;

process (iCLK,iRST, bitcount, data)
begin
if (rising_edge(iCLK)) then
if (iRST = '0') then  
   data_ready <= '0';
elsif (bitcount = 32) then
    if (data(31 downto 24) = NOT(data(23 downto 16))) then
	   data_buf <= data;  -- fetch the value from the databuf from the data register
		data_ready <= '1';  -- set the data_ready flag 
    else
      data_ready <= '0';      -- data error
	 end if;
else
   data_ready <= '0';
end if;
end if;
end process;

process (iCLK, iRST, data_ready)
begin
if (rising_edge(iCLK)) then
 if (iRST = '0') then 
   oDATA <= "00000000000000000000000000000000";
 elsif (data_ready = '1') then
   oDATA <= data_buf;  -- output the data
 end if;
end if;
end process;

HEX_idle_count <= std_logic_vector(to_unsigned(idle_count, HEX_idle_count'length));
HEX_state_count <= std_logic_vector(to_unsigned(state_count, HEX_state_count'length));
HEX_data_count <= std_logic_vector(to_unsigned(data_count, HEX_data_count'length));
HEX_bitcount <= std_logic_vector(to_unsigned(bitcount, HEX_bitcount'length));


--digit7 <= "00" & HEX_idle_count(17 downto 16);
--digit6 <= HEX_idle_count(15 downto 12);
--digit5 <= HEX_idle_count(11 downto 8);
--digit4 <= HEX_idle_count(7 downto 4);
--digit3 <= HEX_idle_count(3 downto 0);

--digit7 <= "00" & HEX_state_count(17 downto 16);
--digit6 <= HEX_state_count(15 downto 12);
--digit5 <= HEX_state_count(11 downto 8);
--digit4 <= HEX_state_count(7 downto 4);
--digit3 <= HEX_state_count(3 downto 0);

--digit7 <= "00" & HEX_data_count(17 downto 16);
--digit6 <= HEX_data_count(15 downto 12);
--digit5 <= HEX_data_count(11 downto 8);
--digit4 <= HEX_data_count(7 downto 4);
--digit3 <= HEX_data_count(3 downto 0);

--digit2 <= "00" & HEX_bitcount(5 downto 4);
--digit1 <= HEX_bitcount(3 downto 0);
--digit0 <= "000" & iIRDA;

--digit2 <= "000" & idle_count_flag;
--digit1 <= "000" & state_count_flag;
--igit0 <= "000" & data_count_flag;



digit7 <= oData(31 downto 28);
digit6 <= oData(27 downto 24);
digit5 <= oData(23 downto 20);
digit4 <= oData(19 downto 16);
digit3 <= oData(15 downto 12);
digit2 <= oData(11 downto 8);
digit1 <= oData(7 downto 4);
digit0 <= oData(3 downto 0);

display7 : bcd7seg PORT MAP (digit7, HEX7); -- PORT MAP the 4 most significant digits in oData onto HEX7
display6 : bcd7seg PORT MAP (digit6, HEX6);
display5 : bcd7seg PORT MAP (digit5, HEX5);
display4 : bcd7seg PORT MAP (digit4, HEX4);
display3 : bcd7seg PORT MAP (digit3, HEX3);
display2 : bcd7seg PORT MAP (digit2, HEX2);
display1 : bcd7seg PORT MAP (digit1, HEX1);
display0 : bcd7seg PORT MAP (digit0, HEX0); -- PORT MAP the least 4 significant digits in oData onto HEX0

END structure;
	
	

library ieee;
USE ieee.STD_LOGIC_1164.all;

ENTITY bcd7seg IS   -- Definition of the other ENTITY
	PORT (C	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			H	: OUT	STD_LOGIC_VECTOR(0 TO 6));
END bcd7seg;
 
ARCHITECTURE Structure5 OF bcd7seg IS
BEGIN
	
	--       0  
	--      ---  
	--     |   |
	--    5|   |1
	--     | 6 |
	--      ---  
	--     |   |
	--    4|   |2
	--     |   |
	--      ---  
	--       3  
	--
	 PROCESS (C)
	 BEGIN
		-- Create a switch case based on the intermediate signal C
		-- Should have 16 possible outcomes
		case C is
		  when "0000" =>   H <= "0000001";
		  when "0001" =>   H <= "1001111";
		  when "0010" =>   H <= "0010010";
		  when "0011" =>   H <= "0000110";
		  when "0100" =>   H <= "1001100";
		  when "0101" =>   H <= "0100100";
		  when "0110" =>   H <= "0100000";
		  when "0111" =>   H <= "0001111";
		  when "1000" =>   H <= "0000000";
		  when "1001" =>   H <= "0001100";
		  when "1010" =>   H <= "0001000";
		  when "1011" =>   H <= "1100000";
		  when "1100" =>   H <= "0110001";
		  when "1101" =>   H <= "1000010";
		  when "1110" =>   H <= "0110000";
		  when "1111" =>   H <= "0111000";
		end case;
	 END PROCESS;
END Structure5;
	  