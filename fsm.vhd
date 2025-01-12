------------------------------------
-- Nama			: Ahmad Fatur Rohman
-- NIM			: 13223112
-- Rombongan	: F
-- Kelompok		: 07
-- Percobaan	: 3
-- Tanggal		: 12 November 2024 
-- Program		: FSM Control mesin modulo 4 bit
------------------------------------

-- Library 
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY fsm IS 
	PORT (
		Start, Clock, full_stream, chacha_done, reset, full_key : IN STD_LOGIC; 
		-- Start:mulai, Compare_flag:menunjukkan A<B
		flag_state : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
		En_stream, En_A, SelA, En_chacha, En_fibonacci, En_key : OUT STD_LOGIC);
END fsm; 

ARCHITECTURE behavior OF fsm IS 
	TYPE jenis_state IS (IDLE, FIBONCC, CHACHA20, XORPROCESS);
	SIGNAL state: jenis_state := IDLE;
	SIGNAL next_state : jenis_state;
BEGIN
	PROCESS (Clock)
	BEGIN
		IF RISING_EDGE(Clock) THEN state <= next_state;
		END IF;
	END PROCESS;
	
	PROCESS (Clock, state, Start) 
	BEGIN
		CASE state IS 
			WHEN IDLE =>
				En_chacha <= '0';
				En_A <= '1';
				En_Stream <= '0'; 
				SelA <= '0';
				flag_state <= "00";
				En_key <= '0';
				En_fibonacci <= '0';
				IF (Start = '1') THEN next_state <= FIBONCC;
				ELSE next_state <= IDLE;
				END IF;
			WHEN FIBONCC => 
				flag_state <= "01";
				En_fibonacci <= '1';
				En_key <= '1';
				IF full_key = '1' THEN
					next_state <= CHACHA20;
				END IF;
			WHEN CHACHA20 => 
				flag_state <= "10";
				En_chacha <= '1';
				En_fibonacci <= '0';
				En_key <= '0';
				IF chacha_done = '1' THEN
					En_Stream <= '1';
				END IF;
				IF full_stream = '1' THEN 
					next_state <= XORPROCESS; 
				ELSE next_state <= CHACHA20;
				END IF; 
			WHEN XORPROCESS => 
				flag_state <= "11";
				SelA <= '1'; 
				En_A <= '1';
				IF reset = '1' THEN next_state <= IDLE;
				END IF;
		END CASE;
	END PROCESS;
END behavior;