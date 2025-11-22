-- debouncer.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Debouncer is
  generic (
    CNT_WIDTH : natural := 18      -- adjust for debounce time at 100 MHz
  );
  port (
    clk     : in  STD_LOGIC;
    reset_n : in  STD_LOGIC;
    din     : in  STD_LOGIC;
    dout    : out STD_LOGIC
  );
end entity Debouncer;

architecture Behavioral of Debouncer is
  signal sync_0, sync_1 : STD_LOGIC := '0';
  signal cnt            : unsigned(CNT_WIDTH-1 downto 0) := (others => '0');
  signal dout_reg       : STD_LOGIC := '0';
begin
  -- 2-FF synchronizer
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      sync_0 <= '0';
      sync_1 <= '0';
    elsif rising_edge(clk) then
      sync_0 <= din;
      sync_1 <= sync_0;
    end if;
  end process;

  -- counter based debounce
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      cnt      <= (others => '0');
      dout_reg <= '0';
    elsif rising_edge(clk) then
      if sync_1 = dout_reg then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;
        if cnt = (cnt'range => '1') then
          dout_reg <= sync_1;
          cnt      <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  dout <= dout_reg;
end architecture Behavioral;
