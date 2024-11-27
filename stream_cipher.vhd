library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity stream_cipher is
    generic(data_length: integer := 32);
    port (
        key: in unsigned((data_length*8)-1 downto 0);
        counter: in unsigned(data_length-1 downto 0);
        nonce: in unsigned((data_length*3)-1 downto 0);
        clk,start,rst: in std_logic;
        child_key: out unsigned((data_length*16)-1 downto 0)
    );
end entity;

architecture behavioral of stream_cipher is

    type array_mat is array (0 to 15) of unsigned(data_length-1 downto 0);

    type state is (idle, state1, state2, finished);
    signal curr_state,next_state: state;
    signal curr_count,next_count: integer := 0;
    signal my_array2: array_mat;

    procedure quarter_round(
        A_inout,B_inout,C_inout,D_inout: inout unsigned(data_length-1 downto 0)
    ) is
        variable A,B,C,D: unsigned(data_length-1 downto 0);
    begin
        A := A_inout;
        B := B_inout;
        C := C_inout;
        D := D_inout;

        A := A + B; D := (D xor A) rol 16;
        C := C + D; B := (B xor C) rol 12;
        A := A + B; D := (D xor A) rol 8;
        C := C + D; B := (B xor C) rol 7;

        A_inout := A;
        B_inout := B;
        C_inout := C;
        D_inout := D;
    end procedure;
begin
    change_state: process(clk,rst)
    begin
        if rst = '1' then
            curr_state <= idle;
        elsif rising_edge(clk) then
            curr_state <= next_state;
            curr_count <= next_count;
        end if;
    end process change_state;

    chacha20 : process(start,curr_state,curr_count)
        variable key_temp: unsigned((data_length*8)-1 downto 0);
        variable counter_temp: unsigned(data_length-1 downto 0);
        variable nonce_temp: unsigned((data_length*3)-1 downto 0);
        variable my_array: array_mat;
        variable count1: integer;
        variable child_key_temp: unsigned((data_length*16)-1 downto 0);
        constant cons_1: unsigned(data_length-1 downto 0) := x"61707865";
        constant cons_2: unsigned(data_length-1 downto 0) := x"3320646e";
        constant cons_3: unsigned(data_length-1 downto 0) := x"79622d32";
        constant cons_4: unsigned(data_length-1 downto 0) := x"6b206574";
    begin
        if curr_state = idle then
            if start ='1' then
                my_array := my_array2;
                key_temp := unsigned(key);
                counter_temp := unsigned(counter);
                nonce_temp := unsigned(nonce);

                -- Baris 0
                my_array(0) := cons_1; 
                my_array(1) := cons_2; 
                my_array(2) := cons_3; 
                my_array(3) := cons_4;

                -- Baris 1
                my_array(4) := key_temp(255 downto 224); 
                my_array(5) := key_temp(223 downto 192); 
                my_array(6) := key_temp(191 downto 160); 
                my_array(7) := key_temp(159 downto 128);

                -- Baris 2
                my_array(8) := key_temp(127 downto 96); 
                my_array(9) := key_temp(95 downto 64); 
                my_array(10) := key_temp(63 downto 32); 
                my_array(11) := key_temp(31 downto 0);

                -- Baris 3
                my_array(12) := counter_temp(31 downto 0); 
                my_array(13) := nonce_temp(95 downto 64); 
                my_array(14) := nonce_temp(63 downto 32); 
                my_array(15) := nonce_temp(31 downto 0);
                my_array2 <= my_array;
                next_count <= 0;
                next_state <= state1;
            else
                next_state <= idle;
                next_count <= 0;
            end if;

        elsif curr_state = state1 then
            if curr_count > 9 then
                next_state <= finished;
            else
                my_array := my_array2;
                quarter_round(my_array(0), my_array(4), my_array(8), my_array(12));
                quarter_round(my_array(1), my_array(5), my_array(9), my_array(13));
                quarter_round(my_array(2), my_array(6), my_array(10), my_array(14));
                quarter_round(my_array(3), my_array(7), my_array(11), my_array(15));

                quarter_round(my_array(0), my_array(5), my_array(10), my_array(15));
                quarter_round(my_array(1), my_array(6), my_array(11), my_array(12));
                quarter_round(my_array(2), my_array(7), my_array(8), my_array(13));
                quarter_round(my_array(3), my_array(4), my_array(9), my_array(14));
                my_array2 <= my_array;
                next_count <= curr_count + 1;
                next_state <= state1;
            end if;

        elsif curr_state = finished then
            my_array := my_array2;
            child_key_temp :=
            my_array(0) & my_array(1) & my_array(2) & my_array(3) & 
            my_array(4) & my_array(5) & my_array(6) & my_array(7) & 
            my_array(8) & my_array(9) & my_array(10) & my_array(11) & 
            my_array(12) & my_array(13) & my_array(14) & my_array(15);
            next_count <= 0;
            child_key <= child_key_temp;
            next_state <= idle;
        end if;
    end process chacha20;
end architecture behavioral; 