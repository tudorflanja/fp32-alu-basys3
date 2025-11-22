-- division_core.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Division is
  port (
    clk      : in  STD_LOGIC;
    input1   : in  STD_LOGIC_VECTOR(23 downto 0);  -- dividend (mantissa+1)
    input2   : in  STD_LOGIC_VECTOR(23 downto 0);  -- divisor (mantissa+1)
    load     : in  STD_LOGIC;
    result   : out STD_LOGIC_VECTOR(24 downto 0);  -- 1.int + 23 frac bits
    done_flag: out STD_LOGIC
  );
end entity Division;

architecture Behavioral of Division is
  constant N : natural := 24;

  signal divisor   : unsigned(N-1 downto 0) := (others => '0');
  signal remainder : unsigned(N downto 0)   := (others => '0');
  signal dividend  : unsigned(N-1 downto 0) := (others => '0');
  signal quotient  : unsigned(N-1 downto 0) := (others => '0');
  signal count     : natural range 0 to N := 0;
  signal busy      : STD_LOGIC := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        divisor   <= unsigned(input2);
        dividend  <= unsigned(input1);
        remainder <= (others => '0');
        quotient  <= (others => '0');
        count     <= 0;
        busy      <= '1';
        done_flag <= '0';

      elsif busy = '1' then
        -- shift left (remainder, dividend)
        remainder <= remainder(N-1 downto 0) & dividend(N-1);
        dividend  <= dividend(N-2 downto 0) & '0';

        -- try subtract
        if remainder(N downto 1) >= divisor then
          remainder(N downto 1) <= remainder(N downto 1) - divisor;
          quotient <= quotient(N-2 downto 0) & '1';
        else
          quotient <= quotient(N-2 downto 0) & '0';
        end if;

        count <= count + 1;
        if count = N-1 then
          busy      <= '0';
          done_flag <= '1';
        end if;
      else
        done_flag <= '0';
      end if;
    end if;
  end process;

  -- result with implicit leading bit + 23 bits
  result <= quotient(N-1) & std_logic_vector(quotient);
end architecture Behavioral;
