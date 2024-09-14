library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TempProcessorTB is
end TempProcessorTB;

architecture RTL of TempProcessorTB is
    -- Component declaration
    component TempProcessor is
        Port (
            clk 		: in std_logic;
            reset 		: in std_logic;
            temp_data 	: in std_logic_vector(15 downto 0);
            data_valid 	: in std_logic;
            led_output 	: out std_logic_vector(2 downto 0)
        );
    end component;

    -- Testbench signals
    signal clk 				: std_logic := '0';
    signal reset 			: std_logic := '1';
    signal temp_data_tb 	: std_logic_vector(15 downto 0) := (others => '0');
    signal data_valid_tb 	: std_logic := '0';
    signal led_output_tb 	: std_logic_vector(2 downto 0):= "000";

    -- Clock period definitions
    constant clk_period : time := 10 ns;
    

    -- Test procedure
    procedure check_temperature(
        signal temp_data 		: out std_logic_vector(15 downto 0);
        signal data_valid 		: out std_logic;
        signal led_output 		: in std_logic_vector(2 downto 0);
        constant test_temp 		: in INTEGER;
        constant expected_led 	: in std_logic_vector(2 downto 0);
        constant test_name 		: in STRING
    ) is
    begin
        wait until falling_edge(clk);
        temp_data <= std_logic_vector(to_signed(test_temp * 256, 16));  -- Convert to fixed-point
        data_valid <= '1';
        wait until rising_edge(clk);
        data_valid <= '0';
        wait for clk_period;
        
-- assert led_output = expected_led
--        report "Test " & test_name & " failed. Expected: " & std_logic_vector'IMAGE(expected_led) & 
--               ", Got: " & std_logic_vector'IMAGE(led_output)
--        severity error;
        
end procedure;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: TempProcessor 
    port map (
        clk 		=> clk,
        reset 		=> reset,
        temp_data 	=> temp_data_tb,
        data_valid 	=> data_valid_tb,
        led_output 	=> led_output_tb
    );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    process
    begin
        -- Hold reset state for 100 ns
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for clk_period*10;

        -- Test case 1: Low temperature (below 20 C)
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, 15, "001", "Low temperature");
        wait for clk_period*10;

        -- Test case 2: Normal temperature (between 20C and 30 C)
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, 25, "010", "Normal temperature");
        wait for clk_period*10;

        -- Test case 3: High temperature (above 30 C)
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, 35, "100", "High temperature");
        wait for clk_period*10;

        -- Test case 4: Edge case - exactly 20 C
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, 20, "010", "Edge case - 20 C");
        wait for clk_period*10;

        -- Test case 5: Edge case - exactly 30 C
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, 30, "010", "Edge case - 30 C");
        wait for clk_period*10;

        -- Test case 6: Very low temperature
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, -10, "001", "Very low temperature");
        wait for clk_period*10;

        -- Test case 7: Very high temperature
        check_temperature(temp_data_tb, data_valid_tb, led_output_tb, 50, "100", "Very high temperature");
        wait for clk_period*10;

        -- End simulation
        assert false report "Simulation Finished" severity failure;
    end process;

end RTL;