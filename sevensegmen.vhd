-- Library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Define entity
entity sevensegmen is
	port (
        mode: in std_logic;
        clk: in std_logic;
        dp: out std_logic_vector(3 downto 0);
		o: out std_logic_vector(0 to 6));
end sevensegmen;

-- Define architecture
architecture behaviorial of sevensegmen is
    type state is (dp1,dp2,dp3);

    signal curr_state : state;
    signal ctr : integer range 0 to 50001 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if curr_state = dp1 then
                dp <= "0111";

                if mode <= '0' then
                    o <= "0110000";
                elsif mode <= '1' then
                    o <= "1000010";
                end if;

                if (ctr = 50001) then
                    ctr <= 0;
                    curr_state <= dp2;
                else
                    ctr <= ctr + 1;
                end if;

            elsif curr_state = dp2 then
                dp <= "1011";

                if mode <= '0' then
                    o <= "1101010";
                elsif mode <= '1' then
                    o <= "0110000";
                end if;

                if (ctr = 50001) then
                    ctr <= 0;
                    curr_state <= dp3;
                else
                    ctr <= ctr + 1;
                end if;

            elsif curr_state = dp3 then
                dp <= "1101";
                o <= "1110010";
                if (ctr = 50001) then
                    ctr <= 0;
                    curr_state <= dp1;
                else
                    ctr <= ctr + 1;
                end if;
            end if;
        end if;
    end process;
end behaviorial;