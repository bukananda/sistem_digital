LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

ENTITY fill_regist IS 
	GENERIC (n : INTEGER := 512; byte : INTEGER := 64);
	PORT (
		data_in : IN unsigned(15 DOWNTO 0); -- Input yang akan di regist
		Reset, Enable, Clock : IN STD_LOGIC; 
		Q : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (OTHERS => '0');
		done_flag : OUT STD_LOGIC := '0');
END ENTITY; 

ARCHITECTURE behav OF fill_regist IS 
	SIGNAL data_temp : unsigned (n-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL count : INTEGER := 0;
BEGIN 
	PROCESS (Clock) 
	BEGIN 
		IF RISING_EDGE (Clock) THEN 
			IF Reset = '1' THEN 
				data_temp <= (OTHERS => '0');
				count <= 0;
				done_flag <= '0';	
			ELSE 
				IF Enable = '1' THEN 
					IF count < byte THEN 
						data_temp <= data_temp(n-17 DOWNTO 0)&data_in; 
						count <= count + 1; 
					ELSE 
						done_flag <= '1';
					END IF; 
				END IF;
			END IF; 
			Q <= std_logic_vector(data_temp);
		END IF; 
	END PROCESS;
END behav;
			