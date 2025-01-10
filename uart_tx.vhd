library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity UART_TX is
  generic (n : integer := 5209); -- 50 MHz / 9600
    
  port (
    clock       : in  std_logic;
    i_TX_valid  : in  std_logic;
    i_TX_Byte   : in  std_logic_vector(7 downto 0);
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic
    );
end UART_TX;
 
 
architecture RTL of UART_TX is
 
  type state is (IDLE, MULAI, PROSESS, STOP, CLEAN);
  signal curr_state : state := IDLE;
 
  signal r_Count : integer range 0 to n-1 := 0; -- Penghitung clock
  signal r_indeks : integer range 0 to 7 := 0; -- indeks 
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_TX_Done   : std_logic := '0';
   
begin
 
  Pengiriman : process (clock)
  begin
    if rising_edge(clock) then
      case curr_state is
 
        when IDLE =>
          o_TX_Active <= '0';
          o_TX_Serial <= '1'; 
          r_TX_Done   <= '0';
          r_Count <= 0;
          r_indeks <= 0;
 
          if i_TX_valid = '1' then -- Jika input valid = 1 
            r_TX_Data <= i_TX_Byte;
            curr_state <= MULAI;
          else
            curr_state <= IDLE;
          end if;
 
        when MULAI =>
          o_TX_Active <= '1'; -- Sinyal bahwa TX sedang aktif 
          o_TX_Serial <= '0';
          if r_Count < n-1 then 
            r_Count <= r_Count + 1;
            curr_state   <= MULAI;
          else -- Lanjut ke proses 
            r_Count <= 0;
            curr_state   <= PROSESS;
          end if;
 
        when PROSESS =>
          o_TX_Serial <= r_TX_Data(r_indeks); -- kirim dalam o_TX_Serial
          if r_Count < n-1 then
            r_Count <= r_Count + 1;
            curr_state   <= PROSESS;
          else 
            r_Count <= 0;
            if r_indeks < 7 then -- Jika belum 8 bit yang terkirim
              r_indeks <= r_indeks + 1;
              curr_state   <= PROSESS;
            else -- Sudah terkirim semua, stop
              r_indeks <= 0;
              curr_state   <= STOP;
            end if;
          end if;

        when STOP =>
          o_TX_Serial <= '1'; -- Stop bit 
          if r_Count < n-1 then
            r_Count <= r_Count + 1;
            curr_state   <= STOP;
          else
            r_TX_Done   <= '1';
            r_Count <= 0;
            curr_state   <= CLEAN;
          end if;
         
        when CLEAN =>
          o_TX_Active <= '0'; -- Sudah tidak aktif 
          r_TX_Done   <= '1'; -- proses pengiriman selesai
          curr_state   <= IDLE;
 
        when others =>
          curr_state <= IDLE;
 
      end case;
    end if;
  end process Pengiriman;
  o_TX_Done <= r_TX_Done;
end RTL;