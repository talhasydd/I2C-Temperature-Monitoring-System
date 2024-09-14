-- Top-level module
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2CtopLevel is
    
	
	Port ( 
        clk : in std_logic;
        reset : in std_logic;
        scl : inout std_logic;
        sda : inout std_logic;
        led_output : out std_logic_vector(2 downto 0) := "000"
    );
end I2CtopLevel;

architecture RTL of I2CtopLevel is
    -- Component declarations
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

    component TempProcessor is
        Port (
            clk : in std_logic;
            reset : in std_logic;
            temp_data : in std_logic_vector(15 downto 0);
            data_valid : in std_logic;
            led_output : out std_logic_vector(2 downto 0)
        );
    end component;

    -- Internal signals
    signal start, stop, read, write, ack_error, busy : std_logic;
    signal data_wr, data_rd : std_logic_vector(7 downto 0);
    signal temp_data : std_logic_vector(15 downto 0);
    signal data_valid : std_logic;

    -- FSM states
    type state_type is (IDLE, START_TEMP_READ, SEND_ADDR, SEND_REG, READ_MSB, READ_LSB, PROCESS_TEMP);
    signal state : state_type;
    
    constant SENSOR_ADDR : STD_LOGIC_VECTOR(7 downto 0) := x"48"; -- Example address
    constant TEMP_REG : STD_LOGIC_VECTOR(7 downto 0) := x"00"; -- Example temperature register

begin
    -- Instantiate components
    i2c_master_inst : I2CMaster
    port map (
        clk => clk,
        reset => reset,
        scl => scl,
        sda => sda,
        start => start,
        stop => stop,
        read => read,
        write => write,
        ack_error => ack_error,
        data_wr => data_wr,
        data_rd => data_rd,
        busy => busy
    );

    temp_processor_inst : TempProcessor
    port map (
        clk => clk,
        reset => reset,
        temp_data => temp_data,
        data_valid => data_valid,
        led_output => led_output
    );

    -- Main process
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            start <= '0';
            stop <= '0';
            read <= '0';
            write <= '0';
            data_wr <= (others => '0');
            temp_data <= (others => '0');
            data_valid <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if busy = '0' then
                        state <= START_TEMP_READ;
                    end if;

                when START_TEMP_READ =>
                    start <= '1';
                    data_wr <= sensor_addr;
                    write <= '1';
                    state <= SEND_ADDR;

                when SEND_ADDR =>
                    if busy = '1' then
                        start <= '0';
                        write <= '0';
                        state <= SEND_REG;
                    end if;

                when SEND_REG =>
                    if busy = '0' then
                        data_wr <= temp_reg;
                        write <= '1';
                        state <= READ_MSB;
                    end if;

                when READ_MSB =>
                    if busy = '0' then
                        write <= '0';
                        start <= '1';
                        data_wr <= sensor_addr or x"01"; -- Set read bit
                        state <= READ_LSB;
                    end if;

                when READ_LSB =>
                    if busy = '0' then
                        start <= '0';
                        read <= '1';
                        state <= PROCESS_TEMP;
                    end if;

                when PROCESS_TEMP =>
                    if busy = '0' then
                        read <= '0';
                        stop <= '1';
                        temp_data <= data_rd & temp_data(15 downto 8);
                        data_valid <= '1';
                        state <= IDLE;
                    end if;

            end case;
        end if;
    end process;

end RTL;



