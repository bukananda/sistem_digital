------------------------------------
-- Nama			: Ahmad Fatur Rohman
-- NIM			: 13223112
-- Rombongan	: F
-- Kelompok		: 07
-- Percobaan	: 3
-- Tanggal		: 12 November 2024 
-- Program		: Register dengan enable 
------------------------------------

-- Library
LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Define entity 
ENTITY reg_nbit IS
	GENERIC ( n: INTEGER := 512);
	PORT ( 
		R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- Input yang akan di regist
		Reset, Enable, Clock : IN STD_LOGIC; 
		Q : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)); -- Output
END reg_nbit;

ARCHITECTURE behavior OF reg_nbit IS 
-- Sinyal dataR dalam rangkaian
SIGNAL dataR : STD_LOGIC_VECTOR (n-1 DOWNTO 0); 
BEGIN
	PROCESS (Reset, Clock)
	BEGIN 
		-- Jika reset 1, maka akan bernilai 0000
		IF Reset = '1' THEN 
			dataR <= (OTHERS=>'0');
		ELSIF Clock'EVENT AND Clock = '1' THEN -- Membaca saat clock naik 
			IF Enable = '1' THEN dataR <= R; -- Jika enable 1, maka R akan di regist 
			END IF;
		END IF;
	END PROCESS;
	Q <= dataR; -- Ambil nilai dataR sebagai output
END behavior;