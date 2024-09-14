library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity I2CtopLevelTB is
end I2CtopLevelTB;

architecture RTL of I2CtopLevelTB is
    -- Component declaration
    component I2CtopLevel is
		
		Port ( 
            clk : in std_logic;
            reset : in std_logic;
            scl : inout std_logic;
            sda : inout std_logic;
            led_output : out std_logic_vector(2 downto 0)
        );
    end component;

    -- Testbench signals
    signal clk_tb : std_logic := '0';
    signal rst_tb : std_logic := '1';
    signal scl_tb : std_logic := 'H';
    signal sda_tb : std_logic := 'H';
    signal led_output_tb : std_logic_vector(2 downto 0);
	

    -- Clock period definitions
    constant clk_period : time := 10 ns;

    -- I2C slave (temperature sensor) simulation
    signal i2c_slave_ack : std_logic := '0';
    signal i2c_slave_data : std_logic_vector(15 downto 0) := x"1E00"; -- Example temperature data

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: I2CtopLevel 

    port map (
        clk 		=> clk_tb,
        reset 		=> rst_tb,
        scl 		=> scl_tb,
        sda 		=> sda_tb,
        led_output 	=> led_output_tb
        
    );

    -- Clock process
    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
       
        rst_tb <= '1';
        wait for 100 ns;
        rst_tb <= '0';

        
        wait for 10 ms;

        -- Changing temperature data
        i2c_slave_data <= x"1E00";
        wait for 10 ms;

        
        assert false report "Simulation Finished" severity failure;
    end process;

    -- I2C slave (temperature sensor) simulation process
    i2c_slave_proc: process
        variable bit_count : integer := 0;
        variable byte_count : integer := 0;
        variable read_mode : boolean := false;
    begin
        wait until falling_edge(scl_tb);

        -- Detect start condition
        if sda_tb = '0' and scl_tb = 'H' then
            bit_count := 0;
            byte_count := 0;
            read_mode := false;
        -- Detect stop condition
        elsif sda_tb = 'H' and scl_tb = 'H' then
            bit_count := 0;
            byte_count := 0;
            read_mode := false;
        -- Handle data bits
        else
            if bit_count < 8 then
                -- Receiving address or data
                bit_count := bit_count + 1;
                if bit_count = 8 then
                    -- Send ACK
                    sda_tb <= '0' after 1 ns, 'H' after 100 ns;
                    byte_count := byte_count + 1;

                    if byte_count = 1 and sda_tb = 'H' then
                        read_mode := true;
                    end if;
                end if;
            elsif read_mode then
                -- Sending data
                sda_tb <= i2c_slave_data(15 - ((byte_count - 2) * 8 + bit_count)) after 1 ns, 'H' after 100 ns;
                bit_count := bit_count + 1;
                if bit_count = 9 then
                    bit_count := 0;
                    byte_count := byte_count + 1;
                end if;
            else
                -- Receiving data (ignored in this simple simulation)
                bit_count := 0;
                byte_count := byte_count + 1;
            end if;
        end if;
    end process;

end RTL;