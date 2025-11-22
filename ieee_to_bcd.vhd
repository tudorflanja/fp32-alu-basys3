-- ieee_to_bcd.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IEEE_to_BCD is
  port (
    ieee_in  : in  STD_LOGIC_VECTOR(31 downto 0);
    sign_out : out STD_LOGIC;
    digits   : out STD_LOGIC_VECTOR(15 downto 0); -- [15:12]=d3 .. [3:0]=d0
    dp_pos   : out STD_LOGIC_VECTOR(2 downto 0)   -- here always 0 (integer)
  );
end entity IEEE_to_BCD;

architecture Behavioral of IEEE_to_BCD is
  function ieee_to_int(x : STD_LOGIC_VECTOR(31 downto 0)) return integer is
    variable sign    : STD_LOGIC := x(31);
    variable e       : integer := to_integer(unsigned(x(30 downto 23))) - 127;
    variable mant24  : unsigned(23 downto 0);
    variable val     : integer;
  begin
    if e = -127 and x(22 downto 0) = (others => '0') then
      return 0; -- zero
    end if;

    mant24 := "1" & x(22 downto 0); -- implicit 1

    if e >= 23 then
      val := to_integer(mant24) * (2 ** (e-23));
    else
      val := to_integer(mant24) / (2 ** (23-e));
    end if;

    if sign = '1' then
      val := -val;
    end if;
    return val;
  end function;

begin
  process(ieee_in)
    variable n    : integer;
    variable n_abs: integer;
    variable d3,d2,d1,d0 : integer;
  begin
    sign_out <= ieee_in(31);

    n := ieee_to_int(ieee_in);

    if n < 0 then
      n_abs := -n;
    else
      n_abs := n;
    end if;

    -- clamp to 0..9999
    if n_abs < 0 then
      n_abs := 0;
    elsif n_abs > 9999 then
      n_abs := 9999;
    end if;

    d3 := n_abs / 1000;
    d2 := (n_abs / 100) mod 10;
    d1 := (n_abs / 10)  mod 10;
    d0 := n_abs mod 10;

    digits <= std_logic_vector(to_unsigned(d3,4)) &
              std_logic_vector(to_unsigned(d2,4)) &
              std_logic_vector(to_unsigned(d1,4)) &
              std_logic_vector(to_unsigned(d0,4));

    dp_pos <= "000"; -- show as integer
  end process;
end architecture Behavioral;
