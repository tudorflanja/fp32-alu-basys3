-- multiplication_ieee.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Multiplication_IEEE is
  port (
    clk      : in  STD_LOGIC;
    input1   : in  STD_LOGIC_VECTOR(31 downto 0);
    input2   : in  STD_LOGIC_VECTOR(31 downto 0);
    load     : in  STD_LOGIC;
    output   : out STD_LOGIC_VECTOR(31 downto 0);
    done_flag: out STD_LOGIC
  );
end entity Multiplication_IEEE;

architecture Behavioral of Multiplication_IEEE is
  component Multiplication is
    generic ( n : natural := 24 );
    port (
      clk         : in  STD_LOGIC;
      multiplicand: in  STD_LOGIC_VECTOR(47 downto 0);
      multiplier  : in  STD_LOGIC_VECTOR(23 downto 0);
      load        : in  STD_LOGIC;
      result      : out STD_LOGIC_VECTOR(47 downto 0);
      done_flag   : out STD_LOGIC
    );
  end component;

  signal input1_sign,  input2_sign,  output_sign  : STD_LOGIC;
  signal input1_exp,   input2_exp,   output_exp   : STD_LOGIC_VECTOR(7 downto 0);
  signal input1_man,   input2_man,   output_man   : STD_LOGIC_VECTOR(22 downto 0);

  signal man1_with_1 : STD_LOGIC_VECTOR(47 downto 0);
  signal man2_with_1 : STD_LOGIC_VECTOR(23 downto 0);
  signal mul_result  : STD_LOGIC_VECTOR(47 downto 0);
begin
  -- Split fields
  input1_sign <= input1(31);
  input1_exp  <= input1(30 downto 23);
  input1_man  <= input1(22 downto 0);

  input2_sign <= input2(31);
  input2_exp  <= input2(30 downto 23);
  input2_man  <= input2(22 downto 0);

  -- Sign = xor
  output_sign <= input1_sign xor input2_sign;

  -- Add hidden 1
  man1_with_1(47 downto 24) <= (others => '0');
  man1_with_1(23 downto 0)  <= '1' & input1_man; -- 24 bits

  man2_with_1 <= '1' & input2_man;               -- 24 bits

  core_mul : Multiplication
    generic map ( n => 24 )
    port map (
      clk          => clk,
      multiplicand => man1_with_1,
      multiplier   => man2_with_1,
      load         => load,
      result       => mul_result,
      done_flag    => done_flag
    );

  -- Exponent: (E1 - 127) + (E2 - 127) + carry + 127  = E1 + E2 + carry - 127
  process(input1_exp, input2_exp, mul_result)
    variable e1, e2 : integer;
    variable sum    : integer;
  begin
    e1 := to_integer(unsigned(input1_exp));
    e2 := to_integer(unsigned(input2_exp));
    sum := e1 + e2 + (0 when mul_result(47) = '0' else 1) - 127;

    if sum < 0 then
      sum := 0;
    elsif sum > 255 then
      sum := 255; -- crude overflow handling
    end if;

    output_exp <= std_logic_vector(to_unsigned(sum, 8));
  end process;

  -- Normalization:
  -- if MSB (bit 47) is 1 -> take bits 46..24
  -- else take bits 45..23
  with mul_result(47) select
    output_man <= mul_result(45 downto 23) when '0',
                  mul_result(46 downto 24) when others;

  output <= output_sign & output_exp & output_man;
end architecture Behavioral;
