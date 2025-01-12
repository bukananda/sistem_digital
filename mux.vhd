library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity mux is
    Port (
        A     : in  std_logic_vector(511 downto 0); -- Input 1
        B     : in  std_logic_vector(511 downto 0); -- Input 2
        sel   : in  std_logic;                      -- Selector
        O     : out std_logic_vector(511 downto 0)  -- Output
    );
end mux;

architecture behavioral of mux is
begin
    process (A, B, sel)
    begin
        if sel = '0' then
            O <= A;
        else
            O <= B;
        end if;
    end process;
end behavioral;
