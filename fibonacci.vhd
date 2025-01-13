library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity fibonacci is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC; 
           random_byte : out UNSIGNED(15 downto 0));
end fibonacci;

architecture Behavioral of fibonacci is
    signal fbn_xor : STD_LOGIC_VECTOR(15 downto 0) := "1010010011110101";
    signal feedback : STD_LOGIC := '0';
begin

process(clk, rst)
begin
    if rst = '1' then
        fbn_xor <= "1010010011110101";
    else
        if rising_edge(clk) then
        -- x^15 + x^13 + x^10 + x^7 + x^4 + x^3 + x^2 + 1
            feedback <= fbn_xor(14) xor fbn_xor(12) xor fbn_xor(9) xor fbn_xor(6) xor fbn_xor(3) xor fbn_xor(2) xor fbn_xor(1);
            fbn_xor <= feedback & fbn_xor(15 downto 1);
        end if;
    end if;
end process;
    random_byte <= UNSIGNED(fbn_xor);
end Behavioral;