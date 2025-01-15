------------------------------------
-- Nama			: Ahmad Fatur Rohman
-- NIM			: 13223112
-- Rombongan	: F
-- Kelompok		: 07
-- Percobaan	: 3
-- Tanggal		: 12 November 2024 
-- Program		: Multiplexer
------------------------------------

-- Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity muxnbit is
	generic (n : integer := 512);
    port (
        -- Input
        data1, data2 : in  std_logic_vector(n-1 downto 0);  -- n-1 bit input data, 
        sel  : in  STD_LOGIC;   
        -- Output
        y    : out std_logic_vector(n-1 downto 0)     -- n-1 bit output
    );
end entity muxnbit;

architecture Behavioral of muxnbit is
begin
    -- Process to implement the multiplexer logic
    process(sel)
    begin
        case sel is
            when '0' => y <= data1; 
				when others => y <= data2;
        end case;
    end process;
end architecture Behavioral;
