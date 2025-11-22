-- multiplication_core.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Multiplication is
  generic (
    n : natural := 24     -- multiplier width (mantissa+hidden 1)
  );
  port (
    clk         : in  STD_LOGIC;
    multiplicand: in  STD_LOGIC_VECTOR(2*n-1 downto 0);
    multiplier  : in  STD_LOGIC_VECTOR(n-1 downto 0);
    load        : in  STD_LOGIC;
    result      : out STD_LOGIC_VECTOR(2*n-1 downto 0);
    done_flag   : out STD_LOGIC
  );
end entity Multiplication;

architecture Behavioral of Multiplication is
  signal acc    : unsigned(2*n-1 downto 0) := (others => '0');
  signal mcand  : unsigned(2*n-1 downto 0) := (others => '0');
  signal mplier : unsigned(n-1 downto 0)   := (others => '0');
  signal count  : natural range 0 to n := 0;
  signal busy   : STD_LOGIC := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        acc    <= (others => '0');
        mcand  <= unsigned(multiplicand);
        mplier <= unsigned(multiplier);
        count  <= 0;
        busy   <= '1';
        done_flag <= '0';

      elsif busy = '1' then
        if mplier(0) = '1' then
          acc <= acc + mcand;
        end if;

        mcand  <= mcand sll 1;
        mplier <= '0' & mplier(n-1 downto 1);
        count  <= count + 1;

        if count = n-1 then
          busy <= '0';
          done_flag <= '1';
        end if;
      else
        done_flag <= '0';
      end if;
    end if;
  end process;

  result <= std_logic_vector(acc);
end architecture Behavioral;
