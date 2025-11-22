-- sevenseg_bcd4.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SevenSeg_BCD4 is
  port (
    clk      : in  STD_LOGIC;  -- 100 MHz
    reset_n  : in  STD_LOGIC;
    digits   : in  STD_LOGIC_VECTOR(15 downto 0); -- [15:12]=d3 .. [3:0]=d0
    an       : out STD_LOGIC_VECTOR(3 downto 0);  -- active-low anodes
    seg      : out STD_LOGIC_VECTOR(6 downto 0)   -- active-low a..g
  );
end entity SevenSeg_BCD4;

architecture Behavioral of SevenSeg_BCD4 is
  signal clk_div : unsigned(15 downto 0) := (others => '0');
  signal sel     : unsigned(1 downto 0) := (others => '0');
  signal nibble  : STD_LOGIC_VECTOR(3 downto 0);
  signal seg_int : STD_LOGIC_VECTOR(6 downto 0);
begin
  -- simple divider
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      clk_div <= (others => '0');
    elsif rising_edge(clk) then
      clk_div <= clk_div + 1;
    end if;
  end process;

  sel <= clk_div(15 downto 14);

  -- select digit
  process(sel, digits)
  begin
    case sel is
      when "00" => nibble <= digits(3 downto 0);    -- rightmost
      when "01" => nibble <= digits(7 downto 4);
      when "10" => nibble <= digits(11 downto 8);
      when others => nibble <= digits(15 downto 12); -- leftmost
    end case;
  end process;

  -- BCD to segments (active-low)
  process(nibble)
  begin
    case nibble is
      when "0000" => seg_int <= "0000001"; -- 0
      when "0001" => seg_int <= "1001111"; -- 1
      when "0010" => seg_int <= "0010010"; -- 2
      when "0011" => seg_int <= "0000110"; -- 3
      when "0100" => seg_int <= "1001100"; -- 4
      when "0101" => seg_int <= "0100100"; -- 5
      when "0110" => seg_int <= "0100000"; -- 6
      when "0111" => seg_int <= "0001111"; -- 7
      when "1000" => seg_int <= "0000000"; -- 8
      when "1001" => seg_int <= "0000100"; -- 9
      when others => seg_int <= "1111111"; -- blank
    end case;
  end process;

  seg <= seg_int;

  -- active-low anodes
  process(sel)
  begin
    case sel is
      when "00" => an <= "1110"; -- rightmost
      when "01" => an <= "1101";
      when "10" => an <= "1011";
      when others => an <= "0111"; -- leftmost
    end case;
  end process;
end architecture Behavioral;
