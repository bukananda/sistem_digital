library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keystream_maker is
    port (
        clk             : in std_logic;
        i_start         : in std_logic := '1';
        i_rst           : in std_logic := '0';
        key             : in unsigned(255 downto 0) := x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
        nonce           : in unsigned(95 downto 0) := x"000000000000004a00000000";
        keystream8bit   : out unsigned(7 downto 0);
        out_active      : out std_logic;
        out_done        : out std_logic     
    );
end entity;

architecture behavioral of keystream_maker is
    type state is (idle,odd_round,overwrite_odd_round,even_round,overwrite_even_round,adding_initial_matrix,output_mode);
    signal curr_state: state;

    type array_mat is array (0 to 15) of unsigned(31 downto 0);
    signal temp_array: array_mat;

    signal chacha_counter: unsigned(31 downto 0) := x"00000001";

    signal counter,count_even_odd: integer range 0 to 10 := 0;

    signal ctr_out_mat: integer range 0 to 15 := 0; -- Untuk menghitung elemen matriks
    signal ctr_out_el: integer range 0 to 3 := 0; -- Untuk menghitung byte tiap elemen matriks 

    signal r_in1,r_in2,r_in3,r_in4,r_out1,r_out2,r_out3,r_out4: unsigned(31 downto 0);

  
    component quarter_round is
        port (
            A,B,C,D: in unsigned(31 downto 0);
            A_o, B_o, C_o, D_o: out unsigned(31 downto 0) 
        );
    end component;
begin

    q: quarter_round
        port map (
            A  => r_in1, B => r_in2, C => r_in3, D => r_in4,
            A_o  => r_out1, B_o => r_out2, C_o => r_out3, D_o => r_out4
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if (i_rst = '1') then -- Jika di reset maka
                chacha_counter <= x"00000001"; -- Counter chacha kembali ke 1 
                ctr_out_mat <= 0; 
                ctr_out_el <= 0;
                curr_state <= idle;
            end if;
    
            if (curr_state = idle) then
                ctr_out_mat <= 0;
                ctr_out_el <= 0;
                out_done <= '0';
                out_active <= '0';
                if (i_start = '1') then -- Jika di mulai 
                    out_active <= '1'; -- Sinyal bahwa chacha aktiv 
                    counter <= 0; 
                    count_even_odd <= 0;

       -- Assign untuk baris pertama dari konstanta chacha20 
                    temp_array(0) <= x"61707865";
                    temp_array(1) <= x"3320646e";
                    temp_array(2) <= x"79622d32";
                    temp_array(3) <= x"6b206574";

        
       -- Assign untuk key yang berada pada baris kedua dan ketiga 
                    for i in 4 to 11 loop
                        temp_array(i) <= key(255-32*(i-4)-24 downto 255-32*(i-4)-31) & key(255-32*(i-4)-16 downto 255-32*(i-4)-23) & key(255-32*(i-4)-8 downto 255-32*(i-4)-15) & key(255-32*(i-4) downto 255-32*(i-4)-7);
                    end loop;

       -- Assign untuk counter chacha di baris ke empat sebagai satu elemen 
                    temp_array(12) <= chacha_counter;

       -- Assign untuk nonce 
                    for i in 13 to 15 loop
                        temp_array(i) <= nonce(95-32*(i-13)-24 downto 95-32*(i-13)-31) & nonce(95-32*(i-13)-16 downto 95-32*(i-13)-23) & nonce(95-32*(i-13)-8 downto 95-32*(i-13)-15) & nonce(95-32*(i-13) downto 95-32*(i-13)-7);
                    end loop;
        
        -- Masuk ke state odd_round 
                    curr_state <= odd_round;
                else
                    curr_state <= idle; -- Jika belum start, kembali ke iddle 
                end if;
      
            elsif curr_state = odd_round then
      -- Memasukkan matriks yang sebelumnya dah diberi nilai untuk diolah pada Quarter round 
                r_in1 <= temp_array(counter);
                r_in2 <= temp_array(counter+4);
                r_in3 <= temp_array(counter+8);
                r_in4 <= temp_array(counter+12);
                curr_state <= overwrite_odd_round;
      
            elsif curr_state <= overwrite_odd_round then
                temp_array(counter) <= r_out1;
                temp_array(counter+4) <= r_out2;
                temp_array(counter+8) <= r_out3;
                temp_array(counter+12) <= r_out4;
                if (counter = 3) then -- Jika semua kolom sudah di round, maka akan pindah ke even round
                    counter <= 0; -- counter kembali ke 0
                    curr_state <= even_round;
                else
                    counter <= counter + 1;
                    curr_state <= odd_round;
                end if;
      
            elsif curr_state = even_round then
      -- Memasukkan matriks ke proses quarter round 
                r_in1 <= temp_array(counter);
                r_in2 <= temp_array(((counter+1) mod 4) + 4);
                r_in3 <= temp_array(((counter+2) mod 4) + 8);
                r_in4 <= temp_array(((counter+3) mod 4) + 12);
                curr_state <= overwrite_even_round;
      
            elsif curr_state = overwrite_even_round then
                temp_array(counter) <= r_out1;
                temp_array(((counter+1) mod 4) + 4) <= r_out2;
                temp_array(((counter+2) mod 4) + 8) <= r_out3;
                temp_array(((counter+3) mod 4) + 12) <= r_out4;
                if (counter = 3) then -- Sudah 4 kali pemutaran 
                    if (count_even_odd = 9) then -- Sudah 10 kali pengulangan ronde 
                        curr_state <= adding_initial_matrix; -- Pindah ke penyusunan matriks 
                    else
                        counter <= 0; -- Jika belum, kembali ke odd round 
                        count_even_odd <= count_even_odd + 1; 
                        curr_state <= odd_round;
                    end if;
                else
                    counter <= counter + 1;
                    curr_state <= even_round;
                end if;
      
            elsif curr_state = adding_initial_matrix then
      -- Mengatur array baru untuk baris pertama 
                temp_array(0) <= temp_array(0) + x"61707865";
                temp_array(1) <= temp_array(1) + x"3320646e";
                temp_array(2) <= temp_array(2) + x"79622d32";
                temp_array(3) <= temp_array(3) + x"6b206574";

                for i in 4 to 11 loop
       -- Array baru pada baris kedua dan ketiga 
                    temp_array(i) <= temp_array(i) + (key(255-32*(i-4)-24 downto 255-32*(i-4)-31) & key(255-32*(i-4)-16 downto 255-32*(i-4)-23) & key(255-32*(i-4)-8 downto 255-32*(i-4)-15) & key(255-32*(i-4) downto 255-32*(i-4)-7));
                end loop;

      -- Array baru pada baris ke empat counter 
                temp_array(12) <= temp_array(12) + chacha_counter;

      -- Array baru nonce 
                for i in 13 to 15 loop
                    temp_array(i) <= temp_array(i) + (nonce(95-32*(i-13)-24 downto 95-32*(i-13)-31) & nonce(95-32*(i-13)-16 downto 95-32*(i-13)-23) & nonce(95-32*(i-13)-8 downto 95-32*(i-13)-15) & nonce(95-32*(i-13) downto 95-32*(i-13)-7));
                end loop;
      -- Key stream sudah dihasilkan
                curr_state <= output_mode;
      
            elsif (curr_state = output_mode) then
                out_done <= '1'; -- Sinyal sudah selesai 
                    keystream8bit <= temp_array(ctr_out_mat)((ctr_out_el+1)*8-1 downto ctr_out_el*8); -- ambil key stream tiap 8 bit 
                    if (ctr_out_el = 3) then 
                        if (ctr_out_mat = 15) then
                            chacha_counter <= chacha_counter + 1;
                            curr_state <= idle;
                        else
                            ctr_out_el <= 0;
                            ctr_out_mat <= ctr_out_mat + 1;
                        end if;
                    else
                        ctr_out_el <= ctr_out_el + 1;
                    end if;
            end if;
        end if;
    end process;
end architecture;