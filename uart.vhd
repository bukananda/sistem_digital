library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART is
    generic (
        data_length : integer := 32;
        key_length  : integer := 8;
        nonce_length: integer := 3;
        text_length : integer := 128;
        upper_delay : integer := 160000
    );
    port (
    i_Clk       : in  std_logic;
    i_RX        : in  std_logic;
    i_Start     : in  std_logic;
    i_rst       : in  std_logic;
    o_TX        : out std_logic;
    o_TX_Active : out std_logic;
    o_TX_Done   : out std_logic
    );
end UART;

architecture rtl of UART is
    signal upper_bond  : integer := (key_length+nonce_length+text_length-1);

    type t_MEM_UART is array (0 to upper_bond) of std_logic_vector(7 downto 0);
    signal mem_uart : t_MEM_UART;

    type state is (idle, rx_mode, padding_mode, keystream_mode, tx_mode);
    signal curr_state: state := idle; 

    signal r_Byte, r_tx_from_array : std_logic_vector(7 downto 0);
    signal r_keystream : unsigned(7 downto 0);
    signal r_counter: integer range 0 to upper_bond := 0;
    signal delay_counter: integer range 0 to upper_delay := 0;
    signal r_start, r_rst, r_busy, out_keystream, from_idle_state ,r_rx_dv, r_active, r_done, activate_array, activate_tx : std_logic;

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

    component cipher_text is
        port (
            clk             : in std_logic;
            i_start         : in std_logic;
            i_rst           : in std_logic;
            -- en_out          : in std_logic;
            -- text_plain      : in unsigned(7 downto 0);
            key             : in unsigned(255 downto 0);
            nonce           : in unsigned(95 downto 0);
            keystream8bit   : out unsigned(7 downto 0);
            out_active      : out std_logic;
            out_done        : out std_logic     
        );
    end component;
begin
    -- r_start <= not (i_start);
	r_rst   <= not (i_rst);

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

    keystream_maker: cipher_text port map(
        clk             => i_Clk,
        i_start         => r_start,
        i_rst           => r_rst,
        key             => x"03020100070605040b0a09080f0e0d0c13121110171615141b1a19181f1e1d1c",
        nonce           => x"000000004a00000000000000",
        keystream8bit   => r_keystream,
        out_active      => r_busy,
        out_done        => out_keystream
    );

    process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if curr_state = idle then
                r_start <= '0';
                if (activate_array = '1') then
                    from_idle_state <= '1';
                    -- r_start <= '1';
                    r_counter <= 0;
                    curr_state <= rx_mode;
                end if;
            elsif curr_state = rx_mode then
                delay_counter <= delay_counter + 1;
                if (activate_array = '1' or from_idle_state = '1') then
                    delay_counter <= 0;
                    mem_uart(r_counter) <= r_Byte;
                    from_idle_state <= '0';
                    if (r_counter = upper_bond) then
                        r_counter <= 0;
                        r_start <= '1';
                        curr_state <= keystream_mode;
                    else
                        r_start <= '0';
                        r_counter <= r_counter + 1;
                    end if;
                elsif (delay_counter = upper_delay) then
                    curr_state <= padding_mode;
                end if;

            elsif curr_state = padding_mode then
                mem_uart(r_counter) <= "00000000";
                if (r_counter = upper_bond) then
                    r_counter <= 0;
                    r_start <= '1';
                    curr_state <= keystream_mode;
                else
                    r_counter <= r_counter + 1;
                    r_start <= '0';
                end if;

            elsif curr_state = keystream_mode then
                if (out_keystream = '1') then
                    mem_uart(r_counter) <= mem_uart(r_counter) xor std_logic_vector(r_keystream);
                    if (r_counter = text_length) then
                        r_start <= '0';
                        r_counter <= 0;
                        curr_state <= tx_mode;
                    else
                        r_counter <= r_counter + 1;
                    end if;
                end if;

            elsif curr_state = tx_mode then
                if (r_active = '0') then
                    r_tx_from_array <= mem_uart(r_counter);
                    activate_tx <= '1';
                elsif (r_done = '1') then
                    activate_tx <= '0';
                    if (r_counter = upper_bond) then
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