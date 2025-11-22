-- division_ieee.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Division_IEEE is
  port (
    clk       in  STD_LOGIC;
    input1    in  STD_LOGIC_VECTOR(31 downto 0);
    input2    in  STD_LOGIC_VECTOR(31 downto 0);
    load      in  STD_LOGIC;
    output    out STD_LOGIC_VECTOR(31 downto 0);
    done_flag out STD_LOGIC
  );
end entity Division_IEEE;

architecture Behavioral of Division_IEEE is
  component Division is
    port (
      clk       in  STD_LOGIC;
      input1    in  STD_LOGIC_VECTOR(23 downto 0);
      input2    in  STD_LOGIC_VECTOR(23 downto 0);
      load      in  STD_LOGIC;
      result    out STD_LOGIC_VECTOR(24 downto 0);
      done_flag out STD_LOGIC
    );
  end component;

  signal input1_sign,  input2_sign, output_sign  STD_LOGIC;
  signal input1_exp,   input2_exp,  output_exp   STD_LOGIC_VECTOR(7 downto 0);
  signal input1_man,   input2_man               STD_LOGIC_VECTOR(22 downto 0);
  signal output_man                              STD_LOGIC_VECTOR(22 downto 0);

  signal man1_with_1  STD_LOGIC_VECTOR(23 downto 0);
  signal man2_with_1  STD_LOGIC_VECTOR(23 downto 0);
  signal div_result   STD_LOGIC_VECTOR(24 downto 0);
  signal norm_bit     STD_LOGIC;
begin
  -- Special cases X2 == 0 or both 0 (NAN) are mentioned in docs,
  -- but not fully handled here; you can extend this easily.

  input1_sign = input1(31);
  input1_exp  = input1(30 downto 23);
  input1_man  = input1(22 downto 0);

  input2_sign = input2(31);
  input2_exp  = input2(30 downto 23);
  input2_man  = input2(22 downto 0);

  output_sign = input1_sign xor input2_sign;

  man1_with_1 = '1' & input1_man;
  man2_with_1 = '1' & input2_man;

  core_div  Division
    port map (
      clk      = clk,
      input1   = man1_with_1,
      input2   = man2_with_1,
      load     = load,
      result   = div_result,
      done_flag= done_flag
    );

  -- Normalization bit is inverse of top bit as in the Romanian doc
  norm_bit = not div_result(24);

  -- Exponent E1 - E2 + 127 - normalization
  process(input1_exp, input2_exp, norm_bit)
    variable e1, e2, e3  integer;
  begin
    e1 = to_integer(unsigned(input1_exp));
    e2 = to_integer(unsigned(input2_exp));
    e3 = e1 - e2 + 127 - (0 when norm_bit = '0' else 1);

    if e3  0 then
      e3 = 0;
    elsif e3  255 then
      e3 = 255;
    end if;

    output_exp = std_logic_vector(to_unsigned(e3, 8));
  end process;

  output_man = div_result(23 downto 1) when norm_bit = '0'
                else div_result(22 downto 0);

  output = output_sign & output_exp & output_man;
end architecture Behavioral;
