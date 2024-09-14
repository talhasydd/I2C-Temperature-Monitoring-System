-- Temperature Processor Component
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TempProcessor is
    Port (
        clk : in std_logic;
        reset : in std_logic;
        temp_data : in std_logic_vector(15 downto 0);
        data_valid : in std_logic;
        led_output : out std_logic_vector(2 downto 0)
    );
end TempProcessor;

architecture RTL of TempProcessor is
    -- Temperature thresholds 
    constant temp_low : signed(15 downto 0) := to_signed(20 * 256, 16);  -- 20 C
    constant temp_high : signed(15 downto 0) := to_signed(30 * 256, 16); -- 30 C

    -- Internal signals
    signal temp_signed : signed(15 downto 0):= (others => '0');

begin
    process(clk, reset)
    begin
        if reset = '1' then
            led_output <= "000";
        elsif rising_edge(clk) then
            if data_valid = '1' then
                temp_signed <= signed(temp_data);
                
                if temp_signed < temp_low then
                    led_output <= "001";     -- Blue: Cold
                elsif temp_signed > temp_high then
                    led_output <= "100";     -- Red: Hot
                else
                    led_output <= "010";     -- Green: Normal
                end if;
            end if;
        end if;
    end process;

end RTL;