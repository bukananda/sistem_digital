library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity quarter_round is 
    port (
    A,B,C,D: in unsigned(31 downto 0); 
    A_o, B_o, C_o, D_o: out unsigned(31 downto 0) 
    );
end entity;

architecture rtl of quarter_round is
    signal temp_A,temp_B,temp_C,temp_D: unsigned(31 downto 0);
    signal temp_A2,temp_B2,temp_C2,temp_D2: unsigned(31 downto 0);
begin
 -- Jika terdapat sebuah matriks[A, B, C, D]
 
 -- A' = A+B; D' = D XOR A' kemudian di rotasi ke kiri sebanyak 16 
    temp_A <= A + B; temp_D <= (D xor temp_A) rol 16;
  
 -- C' = C+D'; B' = B XOR C' kemudian di rotasi ke kiri sebanyak 12
    temp_C <= C + temp_D; temp_B <= (B xor temp_C) rol 12;
  
 -- A'' = A'+B'; D'' = D' XOR A'' kemudian di rotasi ke kiri sebanyak 8
    temp_A2 <= temp_A + temp_B;  temp_D2 <= (temp_D xor temp_A2) rol 8;
  
 -- C'' = C'+D''; B'' = B' XOR C'' kemudian di rotasi ke kiri sebanyak 7
    temp_C2 <= temp_C + temp_D2; temp_B2 <= (temp_B xor temp_C2) rol 7;
  
 -- Output berupa [A'', B'', C'', D'']
    A_o <= temp_A2; B_o <= temp_B2; C_o <= temp_C2; D_o <= temp_D2;
end rtl;