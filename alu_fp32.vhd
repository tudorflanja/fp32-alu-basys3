-- alu_fp32.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_FP32 is
  port (
    clk       : in  STD_LOGIC;
    op_sel    : in  STD_LOGIC;               -- '0' = multiply, '1' = divide
    load      : in  STD_LOGIC;
    a, b      : in  STD_LOGIC_VECTOR(31 downto 0);
    result    : out STD_LOGIC_VECTOR(31 downto 0);
    done_flag : out STD_LOGIC
  );
end entity ALU_FP32;

architecture Structural of ALU_FP32 is
  component Multiplication_IEEE is
    port (
      clk      : in  STD_LOGIC;
      input1   : in  STD_LOGIC_VECTOR(31 downto 0);
      input2   : in  STD_LOGIC_VECTOR(31 downto 0);
      load     : in  STD_LOGIC;
      output   : out STD_LOGIC_VECTOR(31 downto 0);
      done_flag: out STD_LOGIC
    );
  end component;

  component Division_IEEE is
    port (
      clk      : in  STD_LOGIC;
      input1   : in  STD_LOGIC_VECTOR(31 downto 0);
      input2   : in  STD_LOGIC_VECTOR(31 downto 0);
      load     : in  STD_LOGIC;
      output   : out STD_LOGIC_VECTOR(31 downto 0);
      done_flag: out STD_LOGIC
    );
  end component;

  signal mul_out, div_out : STD_LOGIC_VECTOR(31 downto 0);
  signal mul_done, div_done: STD_LOGIC;
begin
  mul_u : Multiplication_IEEE
    port map (
      clk       => clk,
      input1    => a,
      input2    => b,
      load      => load when op_sel = '0' else '0',
      output    => mul_out,
      done_flag => mul_done
    );

  div_u : Division_IEEE
    port map (
      clk       => clk,
      input1    => a,
      input2    => b,
      load      => load when op_sel = '1' else '0',
      output    => div_out,
      done_flag => div_done
    );

  result    <= mul_out when op_sel = '0' else div_out;
  done_flag <= mul_done when op_sel = '0' else div_done;
end architecture Structural;
