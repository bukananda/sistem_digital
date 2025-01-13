library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART_RX is
  generic (
    n : integer := 5208); -- 50 MHz / 9600 
  port (
    clock       : in  std_logic;
    i_RX_Serial : in  std_logic; 
    o_RX_valid  : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end UART_RX;
 
 
architecture rtl of UART_RX is
 
  type state is (IDLE, MULAI, PROSESS, STOP, CLEAN);
  signal curr_state : state := IDLE;
 
  signal r_RX_Data_R : std_logic := '0';
  signal r_RX_Data   : std_logic := '0';
   
  signal r_Count : integer range 0 to n-1 := 0; -- Penghitung clock
  signal r_indeks : integer range 0 to 7 := 0;  -- indeks 
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0'); -- Sinyal yang di terima 
  signal r_RX_valid     : std_logic := '0';
   
begin
  ambil_data : process (clock)
  begin
    if rising_edge(clock) then -- Digunakan dua register untuk menyesuaikan dengan clock input 
      r_RX_Data_R <= i_RX_Serial;
      r_RX_Data   <= r_RX_Data_R; 
    end if; 
  end process ambil_data;

  penerimaan : process (clock)
  begin
    if rising_edge(clock) then
      case curr_state is
        when IDLE => -- Saat masih iddle, 
          r_RX_valid <= '0'; -- Belum menerima 
          r_Count <= 0;
          r_indeks <= 0;
 
          if r_RX_Data = '0' then -- Jika ada start bit, '0'
            curr_state <= MULAI; -- Lanjut ke state mulai
          else
            curr_state <= IDLE; -- Jika tidak ada, tetap di idle 
          end if;
 
          
         when MULAI =>
          if r_Count = (n-1)/2 then -- Jika penghitung clock sudah di tengah
            if r_RX_Data = '0' then 
              r_Count <= 0;  -- Benar bahwa start bit ada, lanjut ke prosess 
              curr_state   <= PROSESS;
            else
              curr_state   <= IDLE;
            end if;
    
          else
            r_Count <= r_Count + 1;
            curr_state   <= MULAI;
          end if;
         
        when PROSESS =>
          if r_Count < n-1 then
            r_Count <= r_Count + 1;
            curr_state   <= PROSESS;
          else
            r_Count <= 0; 
            r_RX_Byte(r_indeks) <= r_RX_Data; -- Mulai penyimpan data yang diterima ke r_RX_Byte 
            if r_indeks < 7 then -- Terus hingga 8 bit sudah diterima 
              r_indeks <= r_indeks + 1;
              curr_state   <= PROSESS;
            else -- Sudah 8 bit 
              r_indeks <= 0;
              curr_state   <= STOP; -- Masuk ke state STOP
            end if;
          end if;
           
        when STOP =>
          if r_Count < n-1 then
            r_Count <= r_Count + 1;
            curr_state <= STOP;
          else
            r_RX_valid <= '1';
            r_Count <= 0;
            curr_state <= CLEAN;
          end if;
            
        when CLEAN =>
          curr_state <= IDLE; -- Kembali ke idle 
          r_RX_valid   <= '0'; 
    
    when others =>
          curr_state <= IDLE; 
      end case;
    end if;
  end process penerimaan;
 
  o_RX_valid   <= r_RX_valid;
  o_RX_Byte <= r_RX_Byte;
end rtl;