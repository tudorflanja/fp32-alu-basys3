-- number_register.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Number_Register is
  port (
    clk        : in  STD_LOGIC;
    reset_n    : in  STD_LOGIC;
    clear      : in  STD_LOGIC;          -- from sw13
    edit_en    : in  STD_LOGIC;          -- this number currently selected & load mode
    up_down    : in  STD_LOGIC;          -- from sw0 (1=up, 0=down)
    inc_dec_p  : in  STD_LOGIC;          -- debounced pulse from btnC
    next_digit_p : in STD_LOGIC;         -- debounced pulse from btnR
    move_dp_p  : in  STD_LOGIC;          -- debounced pulse from btnD

    digits     : out STD_LOGIC_VECTOR(15 downto 0); -- [15:12]=d3 .. [3:0]=d0
    dp_pos     : out STD_LOGIC_VECTOR(2 downto 0);  -- 0..4, decimal point position
    cur_digit_onehot : out STD_LOGIC_VECTOR(3 downto 0) -- for LEDs 10..13
  );
end entity Number_Register;

architecture Behavioral of Number_Register is
  type digit_array is array (3 downto 0) of unsigned(3 downto 0);
  signal d          : digit_array := (others => (others => '0'));
  signal sel_idx    : unsigned(1 downto 0) := (others => '0');
  signal dp         : unsigned(2 downto 0) := (others => '0'); -- 0..4
begin
  process(clk, reset_n)
    variable idx : integer;
  begin
    if reset_n = '0' then
      d       <= (others => (others => '0'));
      sel_idx <= (others => '0');
      dp      <= (others => '0');
    elsif rising_edge(clk) then
      if clear = '1' then
        d       <= (others => (others => '0'));
        sel_idx <= (others => '0');
        dp      <= (others => '0');
      elsif edit_en = '1' then
        -- change selected digit
        if inc_dec_p = '1' then
          idx := to_integer(sel_idx);
          if up_down = '1' then
            if d(idx) = 9 then
              d(idx) <= (others => '0');
            else
              d(idx) <= d(idx) + 1;
            end if;
          else
            if d(idx) = 0 then
              d(idx) <= to_unsigned(9,4);
            else
              d(idx) <= d(idx) - 1;
            end if;
          end if;
        end if;

        -- move digit selection
        if next_digit_p = '1' then
          if sel_idx = "11" then
            sel_idx <= (others => '0');
          else
            sel_idx <= sel_idx + 1;
          end if;
        end if;

        -- move decimal point position (0..4)
        if move_dp_p = '1' then
          if dp = "100" then   -- 4
            dp <= (others => '0');
          else
            dp <= dp + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- pack digits
  digits <= std_logic_vector(d(3)) & std_logic_vector(d(2)) &
            std_logic_vector(d(1)) & std_logic_vector(d(0));

  dp_pos <= std_logic_vector(dp);

  -- current digit indicator (one-hot)
  with sel_idx select
    cur_digit_onehot <= "0001" when "00",  -- d0
                        "0010" when "01",  -- d1
                        "0100" when "10",  -- d2
                        "1000" when others;-- d3
end architecture Behavioral;
