library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY fpg IS 
	PORT( 
		Clock, Start, reset : IN STD_LOGIC;
		ciper_text : OUT STD_LOGIC_VECTOR (511 DOWNTO 0);
		input_text : IN STD_LOGIC_VECTOR (511 DOWNTO 0);
		key_out : OUT STD_LOGIC_VECTOR (351 DOWNTO 0));
END fpg; 

ARCHITECTURE behav OF fpg IS 
	COMPONENT cacha20 IS
		port (
        clk             : in std_logic; -- Clock signal
        i_start         : in std_logic := '1';
        i_rst           : in std_logic := '0';
        key             : in unsigned(255 downto 0) := x"03020100070605040b0a09080f0e0d0c13121110171615141b1a19181f1e1d1c";
        nonce           : in unsigned(95 downto 0) := x"090000004a00000000000000";
        keystream8bit   : out unsigned(7 downto 0);
        out_active      : out std_logic;
        out_done        : out std_logic);
	END COMPONENT; 
	
	COMPONENT fsm IS 
		PORT (
		Start, Clock, full_stream, chacha_done, reset, full_key : IN STD_LOGIC; 
		-- Start:mulai, Compare_flag:menunjukkan A<B
		flag_state : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
		En_stream, En_A, SelA, En_chacha, En_fibonacci, En_key : OUT STD_LOGIC);
	END COMPONENT; 
	
	COMPONENT fill_regist IS 
		GENERIC (n : INTEGER := 512; byte : INTEGER := 64);
		PORT (
		data_in : IN unsigned(7 DOWNTO 0); -- Input yang akan di regist
		Reset, Enable, Clock : IN STD_LOGIC; 
		Q : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (OTHERS => '0');
		done_flag : OUT STD_LOGIC := '0');
	END COMPONENT; 
	
	COMPONENT muxnbit IS 
		port (
        -- Input
        data1, data2 : in  std_logic_vector(511 downto 0);  -- 64 input data, 8-bit each
        sel  : in  STD_LOGIC;   -- 6-bit selector for choosing input
        -- Output
        y    : out std_logic_vector(511 downto 0)     -- 8-bit output
    );
	END COMPONENT; 
	
	COMPONENT reg_nbit IS 
		GENERIC ( n: INTEGER := 512);
		PORT ( 
		R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0); -- Input yang akan di regist
		Reset, Enable, Clock : IN STD_LOGIC; 
		Q : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)); -- Output
	END COMPONENT;
	
	COMPONENT fibonacci IS 
		PORT (
			clk : in STD_LOGIC;
         rst,enab : in STD_LOGIC;  -- Reset untuk menginisialisasi register
         random_byte : out UNSIGNED(7 downto 0));
	END COMPONENT;
	
	SIGNAL kabelA, kabelG : UNSIGNED (7 DOWNTO 0); 
	SIGNAL kabelE : STD_LOGIC_VECTOR (351 DOWNTO 0);
	SIGNAL kabelB, kabelC, kabelD, kabelF : STD_LOGIC_VECTOR (511 DOWNTO 0); 
	SIGNAL enchacha, enstream, sela, streamfull, chacha_active, chacha_done, entext : STD_LOGIC; 
	SIGNAL enfbc, enkey, keyfull : STD_LOGIC;
	SIGNAL state_fsm : STD_LOGIC_VECTOR (1 DOWNTO 0);
	SIGNAL inputchacha : UNSIGNED (351 DOWNTO 0);
BEGIN
chacha20 : cacha20 PORT MAP (clk=>Clock, i_start=>enchacha, i_rst=>reset, keystream8bit=>kabelA, out_active=>chacha_active, 
									key=>inputchacha(351 DOWNTO 96), nonce=>inputchacha(95 DOWNTO 0), out_done=>chacha_done);
keystream : fill_regist PORT MAP (data_in=>kabelA, Reset=>reset, Enable=>enstream, Clock=>Clock, Q=>kabelB, done_flag=>streamfull); 
mux : muxnbit PORT MAP (data1=>input_text, data2=>kabelD, sel=>sela, y=>kabelF);
teks : reg_nbit PORT MAP (R=>kabelF, Reset=>reset, Enable=>entext, Clock=>Clock, Q=>kabelC);
keynonce : fill_regist GENERIC MAP (n=>352, byte=>44)
								PORT MAP (data_in=>kabelG, Reset=>reset, Enable=>enkey, Clock=>Clock, Q=>kabelE, done_flag=>keyfull);
fibonaccirdm : fibonacci PORT MAP (clk=>Clock, rst=>reset, enab=>enfbc, random_byte=>kabelG);
fsm_apply : fsm PORT MAP (Start=>Start, Clock=>Clock, full_stream=>streamfull, chacha_done=>chacha_done, reset=>reset, full_key=>keyfull,
								flag_state=>state_fsm, En_stream=>enstream, En_A=>entext, SelA=>sela, En_chacha=>enchacha, En_fibonacci=>enfbc,
								En_key=>enkey);
	inputchacha <= UNSIGNED(kabelE);
	kabelD <= kabelC XOR kabelB;
	ciper_text <= kabelC;
	key_out <= kabelE;
END behav;
