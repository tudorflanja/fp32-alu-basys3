-- bcd_to_ieee.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BCD_to_IEEE is
  port (
    sign_in  : in  STD_LOGIC;                 -- '1' = negative
    digits   : in  STD_LOGIC_VECTOR(15 downto 0); -- [15:12]=d3 .. [3:0]=d0 (BCD)
    dp_pos   : in  STD_LOGIC_VECTOR(2 downto 0);  -- 0..4, digits - dp position
    ieee_out : out STD_LOGIC_VECTOR(31 downto 0)
  );
end entity BCD_to_IEEE;

architecture Behavioral of BCD_to_IEEE is
  -- integer -> IEEE754 single (positive)
  function int_to_ieee(n_in : integer) return STD_LOGIC_VECTOR is
    variable n       : integer := n_in;
    variable sign    : STD_LOGIC := '0';
    variable exp_int : integer;
    variable mant_int: integer;
    variable frac    : integer;
    variable p       : integer;
    variable tmp     : integer;
    variable mant    : STD_LOGIC_VECTOR(22 downto 0);
    variable res     : STD_LOGIC_VECTOR(31 downto 0);
  begin
    if n = 0 then
      return (others => '0');
    end if;

    if n < 0 then
      sign := '1';
      n := -n;
    end if;

    -- find MSB position p such that 2^p <= n < 2^(p+1)
    tmp := n;
    p   := 0;
    while tmp > 1 loop
      tmp := tmp / 2;
      p   := p + 1;
    end loop;

    exp_int := p + 127;

    -- normalized: n = (1.f) * 2^p
    frac := n - (2 ** p);   -- remainder
    mant_int := 0;
    -- generate 23 bits of mantissa
    for i in 22 downto 0 loop
      frac := frac * 2;
      if frac >= (2 ** p) then
        mant_int := mant_int + (2 ** i);
        frac := frac - (2 ** p);
      end if;
    end loop;

    mant := std_logic_vector(to_unsigned(mant_int, 23));
    res  := sign & std_logic_vector(to_unsigned(exp_int,8)) & mant;
    return res;
  end function;

begin
  process(sign_in, digits, dp_pos)
    variable d3,d2,d1,d0 : integer;
    variable n_int       : integer;
    variable dp_i        : integer;
    variable scale       : integer;
    variable n_scaled    : integer;
    variable unsigned_ieee : STD_LOGIC_VECTOR(31 downto 0);
  begin
    d3 := to_integer(unsigned(digits(15 downto 12)));
    d2 := to_integer(unsigned(digits(11 downto 8)));
    d1 := to_integer(unsigned(digits(7 downto 4)));
    d0 := to_integer(unsigned(digits(3 downto 0)));

    n_int := d3*1000 + d2*100 + d1*10 + d0;

    dp_i := to_integer(unsigned(dp_pos));  -- 0..4

    -- divide by 10^dp_i (truncate fractional part)
    case dp_i is
      when 0 =>
        scale := 1;
      when 1 =>
        scale := 10;
      when 2 =>
        scale := 100;
      when 3 =>
        scale := 1000;
      when others =>
        scale := 10000;
    end case;

    if scale /= 0 then
      n_scaled := n_int / scale;
    else
      n_scaled := n_int;
    end if;

    if sign_in = '1' then
      n_scaled := -n_scaled;
    end if;

    unsigned_ieee := int_to_ieee(n_scaled);
    -- overwrite sign bit explicitly
    ieee_out <= sign_in & unsigned_ieee(30 downto 0);
  end process;
end architecture Behavioral;
