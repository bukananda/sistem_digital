------------------------------------------------------------
---Author		:	TTA21
---Date			:	08/11/2020 , last update 01/26/2021
---Module		:	Simple UART module for serial communications.
---Description	:	This module transmits and recieves 8 bits [1 byte] at a time, allowing for simple communications with
---another external circuit.
---	UPDATE 01/26/2021 : Removed redundant code and added a log function.
---Extra			:	Many thanks to TONI [ https://www.youtube.com/watch?v=fMmcSpgOtJ4 ] for his tutorial in UART communications,
--- i learned much from him. This code is almost completely his with some differences and explanations,
---since i couldn't find his source code, i decided to upload this.

---Thanks to TONI [ https://www.youtube.com/user/AntoniusSimplus ].

---This was compiled for the " ALTERA DE-10 LITE " with the processor " MAX 10 10M50DAF484C7G ", change the pinout
---for your device.
---i_DATA connected to switches
---i_SEND connected to a button
---o_TX connected to a GPIO pin
---i_RX connected to a GPIO pin
---o_sig_CRRP_DATA can be unconnected
---o_sig_RX_BUSY can be unconnected
---o_sig_TX_BUSY can be unconnected
---o_DATA_OUT is connected to led's
---i_log_ADDR connected to switches

---Messages sent and recieved with an arduino uno TX/RX inputs and a serial console.

------------------------------------------------------------

------------------------------------------------------------
---UPDATE 01/26/2021

---	Removed redundant code and added a message log on RX, the two modules (RX/TX) can now be used alone withouth the TOP 
---connector module.
---	The log on RX works as follows:	When a new message is recieved and is not corrupted, it will be added to the atom
---bank (MEM_UART), the counter that chooses the adress is increased every message starting from zero to 255 ("11111111"),
---and repeating. The signal (o_sig_RX_BUSY) can be tracked to inform when the adress changes.
---	The address to read is not the same as the adress to write, this means any adress can be read, but none can be
---written to by the user.

---TTA21
------------------------------------------------------------

--------------- Update by: Muhammad Iqbal Arsyad
--- Kode ini sudah diubah dan disesuaikan untuk kegiatan Modul 4 Praktikum Sistem Digital

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
	port	(
				i_CLOCK		:	in std_logic							;
				i_DATA		:	in std_logic_vector(7 downto 0);		----What to send , 8 bits or 1 byte , comes from some other component
				i_SEND		:	in std_logic							;	----The "send data" signal , comes from some other component
				i_DISPLAY	:	in	std_logic							;	----The "show data" signal , comes from some other component
				rst_button 	: 	in std_logic;
				o_TX		:	out std_logic :='1'					;	----Output line
				o_dis		: 	out std_logic := '1';
				o_send		: 	out std_logic := '1';
				
				i_RX		:	in std_logic							;	----Input line
				i_log_ADDR	:	in std_logic_vector(7 downto 0)			;	----RX has a log of 255 regs connected to DATA_OUT, choose adress here
				
				o_sig_CRRP_DATA		:	out std_logic					;	----Corrupted data signal
				o_sig_RX_BUSY		:	out std_logic					;	---	flag if RX is busy or in receiving mode.
				o_sig_TX_BUSY		:	out std_logic					;	---	flag if TX is busy or in transmitting mode.
				
				o_DATA_OUT		:	out std_logic_vector(7 downto 0)	;	----Message from RX, 8 bits or 1 byte
				o_hex			: 	out std_logic_vector(6 downto 0)		--- HEX (7 Segments) signals.
			);
end uart;


architecture behavior of uart is
	--- SIGNALS
	type t_MEM_UART is array (0 to 255) of std_logic_vector(7 downto 0);
	type state is (idle, state1, state2);

	signal mem_rx : t_MEM_UART;
	signal state_rx : state;

	signal r_TX_DATA	:	std_logic_vector(7 downto 0) := (others => '1')	;	---	Register that holds the message to send
	signal s_TX_START	:	std_logic := '0'								;	---	Stored signal to begin transmission
	signal s_TX_BUSY	:	std_logic										;	---	Stored signal that reminds the main component that its sub component "TX" is busy

	signal s_rx_data	:	std_logic_vector	(7 downto 0)				;	--- RX data that read from RX Buffer
	signal s_hex		:	std_logic_vector	(6 downto 0)				;	--- HEX (7 Segment) signals from ASCII-HEX Converter.
	signal s_ascii		:	std_logic_vector	(7 downto 0)				;	--- RX data that read from RX Buffer and become input of ASCII-HEX Converter.
	
	signal s_log_addr		:	integer range 0 to 255	;
	signal s_button_counter	:	integer range 0 to 5000000	:= 0					;	--- counter to delay the button pressing.
	signal delay_tx,delay_rx : integer range 0 to 5000000 := 0 ;
	signal s_allow_press	: std_logic	:= '0'										;	--- signal to allow the button pressed.

	signal s_send : std_logic := '0';
	signal s_sig_RX_BUSY : std_logic;
	signal s_sig_CRRP_DATA : std_logic;
	signal s_rx,s_tx : std_logic := '0';
	signal mode : std_logic;
	signal counter,tx_counter : integer range 0 to 256;
	signal null_data : std_logic;
	--- END of SIGNALS
	
	--- COMPONENTS
	component uart_tx is
	port(
	
		i_CLOCK	:	in std_logic							;
		i_START	:	in std_logic							;
		o_BUSY	:	out std_logic							;
		i_DATA	:	in std_logic_vector(7 downto 0)	;
		o_TX_LINE:	out std_logic	:= '1'
	
	);
	end component;
	
	component uart_rx is
	port(

		i_CLOCK			:	in std_logic								;
		i_RX			:	in std_logic								;
		i_rst			:	in std_logic								;
		o_DATA			:	out std_logic_vector(7 downto 0)			;
		i_log_ADDR		:	in integer range 0 to 255			;
		o_sig_CRRP_DATA:	out std_logic := '0'						;
		o_BUSY			:	out std_logic

	);
	end component;
	
	
	component asciiHex is
		port	(
					i_ascii			:		in		std_logic_vector	(7 downto 0);
					o_hex			:		out		std_logic_vector	(6 downto 0)
				);
	end component;
	--- END of COMPONENTS
begin
	
	--- Transmitter Module
	u_TX	:	uart_tx port map(
	
		i_CLOCK	=>	i_CLOCK		,
		i_START	=>	s_TX_START	,
		o_BUSY	=>	s_TX_BUSY	,
		i_DATA	=>	r_TX_DATA	,
		
		o_TX_LINE	=>	o_TX
	
	);
	
	--- Receiver Module
	u_RX	:	uart_rx port map(
	
		i_CLOCK				=>	i_CLOCK				,
		i_RX				=>	i_RX				,
		i_rst				=> 	rst_button			,
		o_DATA				=>	s_rx_data			,
		i_log_ADDR			=>	s_log_addr			,
		o_sig_CRRP_DATA		=>	s_sig_CRRP_DATA		,
		o_BUSY				=>	s_sig_RX_BUSY
		
	);
	
	
	--- ASCII to HEX (7 Segment) Converter Module
	a2h	:	asciiHex	port map(
		
		i_ascii	=>	s_ascii	,
		o_hex		=>	s_hex
	);
		
	s_ascii <= s_rx_data;		---	rx data that read from buffer become input of ascii-hex converter
	o_DATA_OUT <= s_rx_data;	--- rx data that read from buffer displayed on LED[7 .. 0]
	o_hex	<= s_hex;			--- rx data that read from buffer displayed on 7 Segment.
	
	
	------------------------------------------------------------
	--- delay to handle debouncing of buttons
	p_button		:	process(i_CLOCK) begin
		if(rising_edge(i_CLOCK)) then
			if(s_button_counter = 4000000) then
				s_button_counter <= 0;
				s_allow_press <= '1';
			else
				s_button_counter <= s_button_counter + 1;
				s_allow_press <= '0';
			end if;
		end if;
	end process;
	--- end of delay process

	---	The transmission sub-routine chacks for avaliability to send something before sending it,
	---everything else is handled internally.
	--- process: untuk menampilkan data di RX Buffer. alamat buffer dipilih menggunakan switch. perintah display menggunakan button key_1.
	p_DISPLAY_RX	:	process	(i_CLOCK) begin
		if(rising_edge(i_CLOCK)) then
			if (state_rx = idle) then
				if(
					i_SEND = '0' and				--- Display button is pressed
					s_allow_press = '1'			--- button is allowed to be pressed
					) then
								---	set address of data that want to be display from RX buffer.
					o_dis <= '0';
					counter <= 0;
					null_data <= '0';
					state_rx <= state1;
				-- elsif (rst_button = '0' and s_allow_press = '1' and s_rx = '0') then
				-- 	s_rx <= '1';
				-- 	mode <= '0';
				-- 	o_dis <= '0';
				-- 	counter <= 0;
				-- 	null_data <= '1';
				else
					state_rx <= idle;
				end if;
			end if;
			if ( 
				state_rx = state1
			) then
				s_log_addr <= counter;
				state_rx <= state2;
			end if;
			if (
				state_rx = state2
			) then
				if (s_sig_crrp_data = '0' and s_sig_rx_busy = '0' and delay_rx = 2000000) then
					if (null_data <= '0') then
						mem_rx(counter) <= s_rx_data;
					-- elsif (null_data <= '1') then
					-- 	mem_rx(counter) <= "00000000";
					end if;
					delay_rx <= 0;
					if (counter < 255) then
						counter <= counter + 1;
						state_rx <= state1;
					else
						state_rx <= idle;
						o_dis <= '1';
					end if;
				else
					delay_rx <= delay_rx + 1;
				end if;
			end if;
		end if;
	end process;
	--- end of process
	
	--- process: untuk melakukan pengiriman data. input data diatur dari switch. perintah pengiriman menggunakan button key_0.
	p_TRANSMIT	:	process(i_CLOCK,tx_counter) begin
	
		if(rising_edge(i_CLOCK)) then
			------------------------------------------------------------
		
			---	If possible, send the byte of data in the input.
			if( 
				i_DISPLAY = '0' and s_tx = '0'	and s_allow_press = '1'	----	Send button is pressed
				) then 					----	Send message over if subcomponent "TX" is not busy
				s_tx <= '1';
				tx_counter <= 0;
				o_send <= '0';
			
			elsif (s_tx = '1') then
				if (s_TX_BUSY = '0' and delay_tx = 4000000) then 	----	transmitter is not busy / not transmitting
					r_TX_DATA	<=	mem_rx(tx_counter);									----Give subcomponent message
					s_TX_START	<=	'1';									----Tell it to transmit
					delay_tx 	<= 0;
					if (tx_counter < 256) then
						tx_counter <= tx_counter + 1;
					else
						s_tx <= '0';
						s_tx_start <= '0';
						o_send <= '1';
					end if;
				else
					s_TX_START <= '0';									----If Subcomponent "TX" is busy, or key is not pressed, do not send
					delay_tx <= delay_tx + 1;
				end if;
			--	If possible, send the byte of data in the input.
			-- if( 
			-- 	i_SEND = '0' and 		----	Send button is pressed
			-- 	s_TX_BUSY = '0' and 	----	transmitter is not busy / not transmitting
			-- 	s_allow_press = '1'		----  	button is allowed to be pressed
			-- 	) then 					----	Send message over if subcomponent "TX" is not busy
			
			-- 	r_TX_DATA	<=	mem_rx(255);									----Give subcomponent message
			-- 	s_TX_START	<=	'1';									----Tell it to transmit

			-- else
			
			-- 	s_TX_START <= '0';									----If Subcomponent "TX" is busy, or key is not pressed, do not send
				
			end if;	---KEY(0) = '0' and s_TX_BUSY = '0'
			
			------------------------------------------------------------
			
		
		end if;	---rising_edge(i_CLOCK)
	
	end process;
	
	------------------------------------------------------------

end behavior;