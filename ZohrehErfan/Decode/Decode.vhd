--  Decode the output of the IR signal DATA which is a logic_vector of 32 bits

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



ENTITY Decode IS
PORT (DATA : IN std_logic_vector(31 downto 0);
      Forward, Backward, Turn_Right, Turn_Left, Rememberit, Playit : OUT std_logic
	);
END Decode;

Architecture structure of Decode IS
signal item : STD_LOGIC_VECTOR(7 DOWNTO 0);     --- TEST the "oDATA(15 downto 8)" outputted by the IR program

Begin
item <= DATA(15 downto 8);

process(item)
begin
CASE item IS

   when "00000001" =>    -- the remote buttom number 1
	   Forward <= '1';
	   Backward <= '0';
		Turn_Right <= '0';
		Turn_Left <= '0';
		Rememberit <= '0';
		Playit <= '0';
		
	when "00000010" =>    -- the remote button number 2
	   Forward <= '0';
	   Backward <= '1';
		Turn_Right <= '0';
		Turn_Left <= '0';
		Rememberit <= '0';
		Playit <= '0';
		
	when "00000011" =>    -- the remote button number 3
	   Forward <= '0';
	   Backward <= '0';
		Turn_Right <= '1';
		Turn_Left <= '0';
		Rememberit <= '0';
		Playit <= '0';
		
	when "00000100" =>    -- the remote button number 4
	   Forward <= '0';
	   Backward <= '0';
		Turn_Right <= '0';
		Turn_Left <= '1';
		Rememberit <= '0';
		Playit <= '0';
		
	when "00000101" =>    -- the remote button number 5
	   Forward <= '0';
	   Backward <= '0';
		Turn_Right <= '0';
		Turn_Left <= '0';
		Rememberit <= '1';
		Playit <= '0';
		
	when "00000110" =>    -- the remote button number 6
	   Forward <= '0';
	   Backward <= '0';
		Turn_Right <= '0';
		Turn_Left <= '0';
		Rememberit <= '0';
		Playit <= '1';
		
	when OTHERS =>        -- other remote buttons
	   Forward <= '0';
	   Backward <= '0';
		Turn_Right <= '0';
		Turn_Left <= '0';
		Rememberit <= '0';
		Playit <= '0';
		
END CASE;
END process;
END structure;

		
	   

	
