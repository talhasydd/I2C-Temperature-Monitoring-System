library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity I2CmasterTB is
end I2CmasterTB;

architecture RTL of I2CmasterTB is
    -- Component declaration
    component I2CMaster is
        Port (
            clk : in std_logic;
            reset : in std_logic;
            scl : inout std_logic;
            sda : inout std_logic;
            start : in std_logic;
            stop : in std_logic;
            read : in std_logic;
            write : in std_logic;
            ack_error : out std_logic;
            data_wr : in std_logic_vector(7 downto 0);
            data_rd : out std_logic_vector(7 downto 0);
            busy : out std_logic
        );
    end component;

    -- Testbench signals
    signal clk_tb : std_logic := '0';
    signal reset_tb : std_logic := '1';
    signal scl_tb : std_logic := 'H';
    signal sda_tb : std_logic := 'H';
    signal start_tb : std_logic := '0';
    signal stop_tb : std_logic := '0';
    signal read_tb : std_logic := '0';
    signal write_tb : std_logic := '0';
    signal ack_error_tb : std_logic;
    signal data_wr_tb : std_logic_vector(7 downto 0) := (others => '0');
    signal data_rd_tb : std_logic_vector(7 downto 0) := (others => '0');
    signal busy_tb : std_logic;

    constant clk_period : time := 10 ns;

    procedure i2c_write_byte(
        signal start : out std_logic;
        signal write : out std_logic;
        signal data_wr : out std_logic_vector(7 downto 0);
        signal busy : in std_logic;
        constant byte_to_write : in std_logic_vector(7 downto 0)) is
    begin
        wait until falling_edge(clk_tb);
        start <= '1';
        data_wr <= byte_to_write;
        write <= '1';
        wait until rising_edge(busy);
        wait until falling_edge(busy);
        start <= '0';
        write <= '0';
    end procedure;

    procedure i2c_read_byte(
        signal start : out std_logic;
        signal read : out std_logic;
        signal busy : in std_logic) is
    begin
        wait until falling_edge(clk_tb);
        start <= '1';
        read <= '1';
        wait until rising_edge(busy);
        wait until falling_edge(busy);
        start <= '0';
        --stop <= '1';
        read <= '0';
    end procedure;

begin
    -- Instantiate component
    uut: I2Cmaster 
    port map (
        clk => clk_tb,
        reset => reset_tb,
        scl => scl_tb,
        sda => sda_tb,
        start => start_tb,
        stop => stop_tb,
        read => read_tb,
        write => write_tb,
        ack_error => ack_error_tb,
        data_wr => data_wr_tb,
        data_rd => data_rd_tb,
        busy => busy_tb
    );

    clk_process : process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;

    -- process
    process
    begin
        -- reset state 
        reset_tb <= '1';
        wait for 100 ns;
        reset_tb <= '0';
        wait for clk_period*10;

        -- Test case 1: Write operation
        i2c_write_byte(start_tb, write_tb, data_wr_tb, busy_tb, x"A5");
        wait for clk_period*100;

        -- Test case 2: Read operation
        i2c_read_byte(start_tb, read_tb, busy_tb);
        wait for clk_period*100;

        -- Test case 3: Write followed by Read
        i2c_write_byte(start_tb, write_tb, data_wr_tb, busy_tb, x"55");
        wait for clk_period*100;
        i2c_read_byte(start_tb, read_tb, busy_tb);
        wait for clk_period*100;

        -- Test case 4: Multiple writes
        i2c_write_byte(start_tb, write_tb, data_wr_tb, busy_tb, x"01");
        wait for clk_period*100;
        i2c_write_byte(start_tb, write_tb, data_wr_tb, busy_tb, x"02");
        wait for clk_period*100;
        i2c_write_byte(start_tb, write_tb, data_wr_tb, busy_tb, x"03");
        wait for clk_period*100;

        -- Test case 5: Stop condition
        wait until falling_edge(clk_tb);
        stop_tb <= '1';
        wait for clk_period;
        stop_tb <= '0';
        wait for clk_period*100;

        -- End simulation
        assert false report "Simulation Finished" severity failure;
        
    end process;

    -- I2C slave simulation process
    i2c_slave_proc: process
        variable bit_count : integer := 0;
        variable byte_received : std_logic_vector(7 downto 0) := (others => '0');
        variable byte_to_send : std_logic_vector(7 downto 0) := x"5A";
    begin
        wait until falling_edge(scl_tb);

        if sda_tb = '0' and scl_tb = 'H' then  -- Start condition
            bit_count := 0;
        elsif sda_tb = 'H' and scl_tb = 'H' then  -- Stop condition
            bit_count := 0;
        else
            if bit_count < 8 then
                -- Receiving data
                byte_received(7 - bit_count) := sda_tb;
                bit_count := bit_count + 1;
            elsif bit_count = 8 then
                -- Send ACK
                sda_tb <= '0' after 1 ns, 'H' after 100 ns;
                bit_count := bit_count + 1;
            else
                -- Sending data
                sda_tb <= byte_to_send(8 - bit_count) after 1 ns, 'H' after 100 ns;
                bit_count := bit_count + 1;
                if bit_count = 17 then
                    bit_count := 0;
                end if;
            end if;
        end if;
    end process;

end RTL;