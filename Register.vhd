library IEEE;  
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.STD_LOGIC_ARITH.ALL;  
use IEEE.STD_LOGIC_UNSIGNED.ALL;  
  
entity Register64Byte is  
    Port (  
        clk     : in  STD_LOGIC;  
        reset   : in  STD_LOGIC;  
        enable  : in  STD_LOGIC;  
        data_in : in  STD_LOGIC_VECTOR(511 downto 0); -- 64 byte = 64 * 8 bits  
        data_out: out STD_LOGIC_VECTOR(511 downto 0)  -- 64 byte = 64 * 8 bits  
    );  
end Register64Byte;  
  
architecture Behavioral of Register64Byte is  
    signal reg_data : STD_LOGIC_VECTOR(511 downto 0);  
    signal bit_index : INTEGER := 0; -- Index untuk menyimpan bit  
begin  
    process(clk, reset)  
    begin  
        if reset = '1' then  
            reg_data <= (others => '0'); -- Reset register to 0  
            bit_index <= 0; -- Reset index  
        elsif rising_edge(clk) then  
            if enable = '1' then  
                reg_data(bit_index) <= data_in(bit_index); -- Simpan bit per bit  
                if bit_index < 511 then  
                    bit_index <= bit_index + 1; -- Increment index  
                end if;  
            end if;  
        end if;  
    end process;  
  
    data_out <= reg_data; -- Output the register data  
end Behavioral;  

--Bit Index: Ditambahkan sinyal bit_index untuk melacak posisi bit yang sedang disimpan.
--Penyimpanan Bit: Pada setiap tepi naik clock, jika enable aktif, hanya satu bit dari data_in yang disimpan ke dalam reg_data sesuai dengan bit_index.