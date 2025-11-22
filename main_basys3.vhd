-- main_basys3.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Main_Basys3 is
  port (
    clk    : in  STD_LOGIC;                        -- 100 MHz

    sw     : in  STD_LOGIC_VECTOR(15 downto 0);    -- switches
    btnC   : in  STD_LOGIC;                        -- increment/decrement
    btnR   : in  STD_LOGIC;                        -- next digit
    btnD   : in  STD_LOGIC;                        -- move decimal point

    led    : out STD_LOGIC_VECTOR(15 downto 0);    -- LEDs
    an     : out STD_LOGIC_VECTOR(3 downto 0);     -- 7-seg anodes
    seg    : out STD_LOGIC_VECTOR(6 downto 0)      -- 7-seg segments
  );
end entity Main_Basys3;

architecture Structural of Main_Basys3 is
  -- Components
  component Debouncer is
    generic ( CNT_WIDTH : natural := 18 );
    port (
      clk     : in  STD_LOGIC;
      reset_n : in  STD_LOGIC;
      din     : in  STD_LOGIC;
      dout    : out STD_LOGIC
    );
  end component;

  component Number_Register is
    port (
      clk        : in  STD_LOGIC;
      reset_n    : in  STD_LOGIC;
      clear      : in  STD_LOGIC;
      edit_en    : in  STD_LOGIC;
      up_down    : in  STD_LOGIC;
      inc_dec_p  : in  STD_LOGIC;
      next_digit_p : in STD_LOGIC;
      move_dp_p  : in  STD_LOGIC;
      digits     : out STD_LOGIC_VECTOR(15 downto 0);
      dp_pos     : out STD_LOGIC_VECTOR(2 downto 0);
      cur_digit_onehot : out STD_LOGIC_VECTOR(3 downto 0)
    );
  end component;

  component BCD_to_IEEE is
    port (
      sign_in  : in  STD_LOGIC;
      digits   : in  STD_LOGIC_VECTOR(15 downto 0);
      dp_pos   : in  STD_LOGIC_VECTOR(2 downto 0);
      ieee_out : out STD_LOGIC_VECTOR(31 downto 0)
    );
  end component;

  component IEEE_to_BCD is
    port (
      ieee_in  : in  STD_LOGIC_VECTOR(31 downto 0);
      sign_out : out STD_LOGIC;
      digits   : out STD_LOGIC_VECTOR(15 downto 0);
      dp_pos   : out STD_LOGIC_VECTOR(2 downto 0)
    );
  end component;

  component ALU_FP32 is
    port (
      clk       : in  STD_LOGIC;
      op_sel    : in  STD_LOGIC;               -- 0 mul, 1 div
      load      : in  STD_LOGIC;
      a, b      : in  STD_LOGIC_VECTOR(31 downto 0);
      result    : out STD_LOGIC_VECTOR(31 downto 0);
      done_flag : out STD_LOGIC
    );
  end component;

  component SevenSeg_BCD4 is
    port (
      clk      : in  STD_LOGIC;
      reset_n  : in  STD_LOGIC;
      digits   : in  STD_LOGIC_VECTOR(15 downto 0);
      an       : out STD_LOGIC_VECTOR(3 downto 0);
      seg      : out STD_LOGIC_VECTOR(6 downto 0)
    );
  end component;

  -- internal signals
  signal reset_n  : STD_LOGIC;
  signal mode_load: STD_LOGIC; -- sw15: 1=load/edit, 0=show result & compute

  -- debounced buttons
  signal btnC_db, btnR_db, btnD_db : STD_LOGIC;

  -- load pulse for ALU (on 1->0 transition of sw15)
  signal sw15_prev : STD_LOGIC := '1';
  signal alu_load  : STD_LOGIC := '0';

  -- number registers
  signal digits1, digits2    : STD_LOGIC_VECTOR(15 downto 0);
  signal dp1, dp2            : STD_LOGIC_VECTOR(2 downto 0);
  signal curdig1, curdig2    : STD_LOGIC_VECTOR(3 downto 0);

  -- IEEE operands/result
  signal ieee1, ieee2, ieee_res : STD_LOGIC_VECTOR(31 downto 0);
  signal sign1, sign2, sign_res : STD_LOGIC;

  -- result in BCD
  signal digits_res : STD_LOGIC_VECTOR(15 downto 0);
  signal dp_res     : STD_LOGIC_VECTOR(2 downto 0);

  -- display mux
  signal digits_disp : STD_LOGIC_VECTOR(15 downto 0);
  signal curdig_sel  : STD_LOGIC_VECTOR(3 downto 0);

begin
  -- reset: sw14
  reset_n   <= not sw(14);
  mode_load <= sw(15);

  -- Debounce buttons
  dbC : Debouncer
    port map ( clk => clk, reset_n => reset_n, din => btnC, dout => btnC_db );

  dbR : Debouncer
    port map ( clk => clk, reset_n => reset_n, din => btnR, dout => btnR_db );

  dbD : Debouncer
    port map ( clk => clk, reset_n => reset_n, din => btnD, dout => btnD_db );

  -- Generate ALU load pulse when sw15 goes from 1 (load) to 0 (compute/show)
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      sw15_prev <= '1';
      alu_load  <= '0';
    elsif rising_edge(clk) then
      if sw15_prev = '1' and mode_load = '0' then
        alu_load <= '1';
      else
        alu_load <= '0';
      end if;
      sw15_prev <= mode_load;
    end if;
  end process;

  -- which number is selected for editing: sw4
  -- sw4=1 -> first number, sw4=0 -> second number
  num1_reg : Number_Register
    port map (
      clk        => clk,
      reset_n    => reset_n,
      clear      => sw(13),
      edit_en    => (mode_load and sw(4)),
      up_down    => sw(0),
      inc_dec_p  => btnC_db,
      next_digit_p => btnR_db,
      move_dp_p  => btnD_db,
      digits     => digits1,
      dp_pos     => dp1,
      cur_digit_onehot => curdig1
    );

  num2_reg : Number_Register
    port map (
      clk        => clk,
      reset_n    => reset_n,
      clear      => sw(13),
      edit_en    => (mode_load and (not sw(4))),
      up_down    => sw(0),
      inc_dec_p  => btnC_db,
      next_digit_p => btnR_db,
      move_dp_p  => btnD_db,
      digits     => digits2,
      dp_pos     => dp2,
      cur_digit_onehot => curdig2
    );

  -- signs from switches: sw3 -> first, sw2 -> second
  sign1 <= sw(3);
  sign2 <= sw(2);

  -- BCD -> IEEE operands
  b2i_1 : BCD_to_IEEE
    port map (
      sign_in  => sign1,
      digits   => digits1,
      dp_pos   => dp1,
      ieee_out => ieee1
    );

  b2i_2 : BCD_to_IEEE
    port map (
      sign_in  => sign2,
      digits   => digits2,
      dp_pos   => dp2,
      ieee_out => ieee2
    );

  -- ALU: sw1 selects operation (0 mul, 1 div)
  alu_inst : ALU_FP32
    port map (
      clk       => clk,
      op_sel    => sw(1),
      load      => alu_load,
      a         => ieee1,
      b         => ieee2,
      result    => ieee_res,
      done_flag => led(0)      -- led0 = done
    );

  -- IEEE -> BCD result
  i2b_res : IEEE_to_BCD
    port map (
      ieee_in  => ieee_res,
      sign_out => sign_res,
      digits   => digits_res,
      dp_pos   => dp_res
    );

  -- Display mux: in load mode show selected number; else show result
  process(mode_load, sw, digits1, digits2, digits_res,
          curdig1, curdig2)
  begin
    if mode_load = '1' then
      if sw(4) = '1' then
        digits_disp <= digits1;
        curdig_sel  <= curdig1;
      else
        digits_disp <= digits2;
        curdig_sel  <= curdig2;
      end if;
    else
      digits_disp <= digits_res;
      curdig_sel  <= "0000";  -- no current-digit indication
    end if;
  end process;

  -- 7-segment driver
  disp : SevenSeg_BCD4
    port map (
      clk     => clk,
      reset_n => reset_n,
      digits  => digits_disp,
      an      => an,
      seg     => seg
    );

  -- LEDs
  -- led15: sign of result
  led(15) <= sign_res;

  -- led10..13 : current digit indicator
  led(13 downto 10) <= curdig_sel;

  -- the rest off (except led0 = done flag from ALU)
  led(9 downto 1)   <= (others => '0');
end architecture Structural;
