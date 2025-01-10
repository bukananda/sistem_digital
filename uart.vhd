library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART is
    generic (
        key_length  : integer := 32;
        nonce_length: integer := 12;
        text_char_length : integer := 128;
        upper_delay : integer := 160000
    );
    port (
    i_Clk       : in  std_logic;
    i_RX        : in  std_logic;
    i_Start     : in  std_logic;
    i_mode      : in  std_logic;
    o_TX        : out std_logic;
    o_mode      : out std_logic;
    o_TX_Done   : out std_logic
    );
end UART;

architecture rtl of UART is
    signal key  : unsigned(255 downto 0);
    signal nonce: unsigned(95 downto 0);

    signal upper_bond  : integer := (text_char_length-1);

    type t_MEM_UART is array (0 to upper_bond) of std_logic_vector(7 downto 0);
    signal mem_uart : t_MEM_UART;

    type state is (idle, encrypt_mode, decrypt_mode, key_nonce_maker_mode, padding_mode, insert_key, insert_nonce, keystream_mode, tx_mode);
    signal curr_state: state := idle; 

    signal r_Byte, r_tx_from_array : std_logic_vector(7 downto 0);
    signal r_keystream : unsigned(7 downto 0);
    signal r_counter: integer range 0 to upper_bond+44 := 0;
    signal delay_counter: integer range 0 to upper_delay := 0;
    signal r_start, r_rst, r_busy, out_keystream, from_idle_state ,r_rx_dv, r_active, r_done, activate_array, activate_tx : std_logic;

    signal ctr_chacha : integer range 0 to 63 := 0;

    signal mode : std_logic := '0';
    signal s_button_counter: integer range 0 to 8000000 := 0;
    signal s_allow_press: std_logic;

    signal random_byte: unsigned(15 downto 0);

    component UART_RX is
        port (
            clock       : in  std_logic;
            i_RX_Serial : in  std_logic;
            o_RX_valid  : out std_logic;
            o_RX_Byte   : out std_logic_vector(7 downto 0)
        );
    end component;

    component UART_TX is
        port (
            clock       : in  std_logic;
            i_TX_valid  : in  std_logic;
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
            key             : in unsigned(255 downto 0);
            nonce           : in unsigned(95 downto 0);
            keystream8bit   : out unsigned(7 downto 0);
            out_active      : out std_logic;
            out_done        : out std_logic     
        );
    end component;

    component fibonacci is
        port (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC; 
            random_byte : out UNSIGNED(15 downto 0)
        );
    end component;
begin
    o_mode <= not mode;
    -- r_start <= not (i_start);
	-- r_rst   <= not (i_rst);
    -- key <= x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
    -- nonce <= x"000000000000004a00000000";

    u_RX : uart_rx port map(
        clock       => i_Clk,
        i_RX_Serial => i_RX,
        o_RX_valid  => activate_array,
        o_RX_Byte   => r_Byte
    );

    u_TX : uart_tx port map(
        clock       => i_Clk,
        i_TX_valid  => activate_tx,
        i_TX_Byte   => r_tx_from_array,
        o_TX_Active => r_active,
        o_TX_Serial => o_TX,
        o_TX_Done   => r_done
    );

    keystream_maker: cipher_text port map(
        clk             => i_Clk,
        i_start         => r_start,
        i_rst           => r_rst,
        key             => key,
        nonce           => nonce,
        keystream8bit   => r_keystream,
        out_active      => r_busy,
        out_done        => out_keystream
    );

    fbcc_component: fibonacci port map(
        clk => i_clk,
        rst => r_rst,
        random_byte => random_byte
    );

    --- delay to handle debouncing of buttons
    p_button:	process(i_clk) begin
        if(rising_edge(i_clk)) then
            if(s_button_counter = 8000000) then
                s_button_counter <= 0;
                s_allow_press <= '1';
            else
                s_button_counter <= s_button_counter + 1;
                s_allow_press <= '0';
            end if;
        end if;
    end process p_button;
        
    fsm: process(i_Clk)
    begin
        if rising_edge(i_Clk) then
            if curr_state = idle then
                r_start <= '0';
                r_rst <= '1';
                if (s_allow_press = '1' and mode = '0' and i_mode = '0') then
                    mode <= '1';
                elsif (s_allow_press = '1' and mode = '1' and i_mode = '0') then
                    mode <= '0';
                end if;

                if (activate_array = '1') then
                    from_idle_state <= '1';
                    r_rst <= '0';
                    r_counter <= 0;
                    if (mode = '0') then
                        curr_state <= encrypt_mode;
                    else
                        curr_state <= decrypt_mode;
                    end if;
                end if;

            elsif curr_state = encrypt_mode then
                delay_counter <= delay_counter + 1;
                if (activate_array = '1' or from_idle_state = '1') then
                    delay_counter <= 0;
                    mem_uart(r_counter) <= r_Byte;
                    from_idle_state <= '0';
                    if (r_counter = upper_bond) then
                        r_counter <= 0;
                        curr_state <= key_nonce_maker_mode;
                    else
                        r_counter <= r_counter + 1;
                        r_start <= '0';
                    end if;
                elsif (delay_counter = upper_delay) then
                    curr_state <= padding_mode;
                end if;

            elsif curr_state = decrypt_mode then
                delay_counter <= delay_counter + 1;
                if (activate_array = '1' or from_idle_state = '1') then
                    delay_counter <= 0;
                    if (r_counter < 32) then
                        key(255-8*r_counter downto 248-8*r_counter) <= unsigned(r_Byte);
                    elsif ((r_counter > 31) and (r_counter < 44)) then
                        nonce(95-8*(r_counter-32) downto 88-8*(r_counter-32)) <= unsigned(r_Byte);
                    else
                        mem_uart(r_counter-44) <= r_Byte;
                    end if;
                    from_idle_state <= '0';
                    if (r_counter = upper_bond+44) then
                        r_counter <= 0;
                        r_start <= '1';
                        curr_state <= keystream_mode;
                    else
                        r_counter <= r_counter + 1;
                        r_start <= '0';
                    end if;
                elsif (delay_counter = upper_delay) then
                    curr_state <= padding_mode;
                end if;

            elsif curr_state = padding_mode then
                mem_uart(r_counter) <= "00000000";
                if (r_counter = upper_bond) then
                    r_counter <= 0;
                    if (mode = '0') then
                        curr_state <= key_nonce_maker_mode;
                    elsif (mode = '1') then
                        r_start <= '1';
                        curr_state <= keystream_mode;
                    end if;
                else
                    r_counter <= r_counter + 1;
                    r_start <= '0';
                end if;

            elsif curr_state = key_nonce_maker_mode then
                if (r_counter < 16) then
                    key(255-16*r_counter downto 240-16*r_counter) <= random_byte;
                    r_counter <= r_counter + 1;
                    r_start <= '0';
                elsif ((r_counter > 15) and (r_counter < 32)) then
                    nonce(95-16*(r_counter-16) downto 80-16*(r_counter-16)) <= random_byte;
                    r_counter <= r_counter + 1;
                    r_start <= '0';
                else
                    r_counter <= 0;
                    r_start <= '1';
                    curr_state <= keystream_mode;
                end if;

            elsif curr_state = keystream_mode then
                if (out_keystream = '1') then
                    mem_uart(r_counter) <= mem_uart(r_counter) xor std_logic_vector(r_keystream);
                    if (r_counter = upper_bond) then
                        r_start <= '0';
                        r_counter <= 0;
                        curr_state <= insert_key;
                    else
                        r_start <= '1';
                        r_counter <= r_counter + 1;
                        if (ctr_chacha = 63) then
                            ctr_chacha <= 0;
                        else
                            ctr_chacha <= ctr_chacha + 1;
                        end if; 
                    end if;
                end if;

            elsif curr_state = insert_key then
                r_start <= '0';
                if (r_active = '0') then
                    r_tx_from_array <= std_logic_vector(key(255-8*(r_counter) downto 248-8*(r_counter)));
                    activate_tx <= '1';
                elsif (r_done = '1') then
                    activate_tx <= '0';
                    if (r_counter = 31) then
                        r_counter <= 0;
                        curr_state <= insert_nonce;
                    else
                        r_counter <= r_counter + 1;
                    end if;
                end if;

            elsif curr_state = insert_nonce then
                r_start <= '0';
                if (r_active = '0') then
                    r_tx_from_array <= std_logic_vector(nonce(95-8*(r_counter) downto 88-8*(r_counter)));
                    activate_tx <= '1';
                elsif (r_done = '1') then
                    activate_tx <= '0';
                    if (r_counter = 11) then
                        r_counter <= 0;
                        curr_state <= tx_mode;
                    else
                        r_counter <= r_counter + 1;
                    end if;
                end if;

            elsif curr_state = tx_mode then
                r_start <= '0';
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
    end process fsm;
end rtl;