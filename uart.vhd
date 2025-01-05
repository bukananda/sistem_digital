library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART is
  port (
    i_Clk       : in  std_logic;
    i_RX        : in  std_logic;
    o_TX        : out std_logic;
    o_TX_Active : out std_logic;
    o_TX_Done   : out std_logic
    );
end UART;

architecture rtl of UART is
    type t_MEM_UART is array (0 to 255) of std_logic_vector(7 downto 0);
	signal mem_uart : t_MEM_UART := (others => (others => '0'));

    type state is (idle, rx_mode, padding_mode, tx_mode);
    signal curr_state: state := idle; 

    signal r_Byte, r_tx_from_array : std_logic_vector(7 downto 0);
    signal r_counter: integer range 0 to 255 := 0;
    signal delay_counter: integer range 0 to 6400000 := 0;
    signal from_idle_state ,r_rx_dv, r_active, r_done, activate_array, activate_tx : std_logic;

    component UART_RX is
        port (
            i_Clk       : in  std_logic;
            i_RX_Serial : in  std_logic;
            o_RX_DV     : out std_logic;
            o_RX_Byte   : out std_logic_vector(7 downto 0)
        );
    end component;

    component UART_TX is
        port (
            i_Clk       : in  std_logic;
            i_TX_DV     : in  std_logic;
            i_TX_Byte   : in  std_logic_vector(7 downto 0);
            o_TX_Active : out std_logic;
            o_TX_Serial : out std_logic;
            o_TX_Done   : out std_logic
        );
    end component;
begin

    u_RX : uart_rx port map(
        i_Clk       => i_Clk,
        i_RX_Serial => i_RX,
        o_RX_DV     => activate_array,
        o_RX_Byte   => r_Byte
    );

    u_TX : uart_tx port map(
        i_Clk       => i_Clk,
        i_TX_DV     => activate_tx,
        i_TX_Byte   => r_tx_from_array,
        o_TX_Active => r_active,
        o_TX_Serial => o_TX,
        o_TX_Done   => r_done
    );

    -- process(r_rx_dv, r_done)
    -- begin
    --     if (r_rx_dv = '1') then
    --         activate_tx <= '1';
    --     elsif (r_done = '1') then
    --         activate_tx <= '0';
	-- 	end if;
    -- end process;
				

    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if curr_state = idle then
                if (activate_array = '1') then
                    from_idle_state <= '1';
                    curr_state <= rx_mode;
                end if;
            end if;
            if curr_state = rx_mode then
                delay_counter <= delay_counter + 1;
                if (activate_array = '1' or from_idle_state = '1') then
                    delay_counter <= 0;
                    mem_uart(r_counter) <= r_Byte;
                    from_idle_state <= '0';
                    if (r_counter = 255) then
                        r_counter <= 0;
                        curr_state <= tx_mode;
                    else
                        r_counter <= r_counter + 1;
                    end if;
                elsif (delay_counter = 6400000) then
                    curr_state <= padding_mode;
                end if;

            elsif curr_state = padding_mode then
                mem_uart(r_counter) <= "00000000";
                if (r_counter = 255) then
                    r_counter <= 0;
                    curr_state <= tx_mode;
                else
                    r_counter <= r_counter + 1;
                end if;

            elsif curr_state = tx_mode then
                if (r_active = '0') then
                    r_tx_from_array <= mem_uart(r_counter);
                    activate_tx <= '1';
                elsif (r_done = '1') then
                    activate_tx <= '0';
                    if (r_counter = 255) then
                        r_counter <= 0;
                        curr_state <= idle;
                    else
                        r_counter <= r_counter + 1;
                    end if;
                end if;
            end if; 
        end if;
    end process;
end rtl;