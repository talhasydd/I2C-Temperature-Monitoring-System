-- I2C Master Component
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2CMaster is
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
end I2CMaster;

architecture RTL of I2CMaster is
    -- I2C bus states
    type i2c_state_type is (IDLE, STARTED, COMMAND, SLVACK, DATA, MASTACK);
    signal state : i2c_state_type;

    -- Internal signals
    signal sda_ena, scl_ena : std_logic;
    signal bit_cnt : integer range 0 to 7;
    signal data_tx, data_rx : std_logic_vector(7 downto 0):= (others => '0');
    
    
    -- Clock divider for SCL
    constant scl_period : integer := 100; -- based on clock frequency and I2C speed
    signal scl_cnt : integer range 0 to scl_period-1;

begin
    -- I2C bus control
    sda <= '0' when sda_ena = '1' else 'Z';
    scl <= '0' when scl_ena = '1' else 'Z';

    -- Main process
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            busy <= '0';
            scl_ena <= '0';
            sda_ena <= '0';
            ack_error <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    busy <= '0';
                    if start = '1' then
                        busy 	<= '1';
                        data_tx <= data_wr;
                        state 	<= STARTED;
                    else
                        busy <= '0';
                    end if;
                    scl_ena <= '0';
                    sda_ena <= '0';

                when STARTED =>
                    busy 	<= '1';
                    scl_ena <= '0';
                    sda_ena <= '1';
                    state 	<= COMMAND;
                    bit_cnt <= 7;

                when COMMAND =>
                    if scl_cnt = scl_period/2 then
                        sda_ena <= not data_tx(bit_cnt);
                        if bit_cnt = 0 then
                            state <= SLVACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                        end if;
                    end if;

                when SLVACK =>
                    if scl_cnt = scl_period / 2 then
                        
                            if read = '1' then
                                state <= DATA;
                                bit_cnt <= 7;
                                sda_ena <= '0';  -- Release SDA for reading
                                ack_error <= '0';
                            elsif write = '1' then
                                if sda = '0' then
                                    ack_error <= '0';
                                    if bit_cnt = 0 then  -- Assuming the write operation is done
                                        state <= IDLE;   -- Move to IDLE after the write is done
                                    else
                                        state <= COMMAND;
                                        bit_cnt <= 7;
                                        data_tx <= data_wr;
                                    end if;
                                 else
                                    ack_error <= '1';
                                    state <= IDLE;
                                    busy <= '0';
                                end if;
                            else
                                state <= IDLE;
                                busy <= '0';
                            end if;                      
                    end if;


                when DATA =>
                    busy <= '1';
                    if scl_cnt = scl_period/2 then
                        data_rx(bit_cnt) <= sda;
                        if bit_cnt = 0 then
                            state <= MASTACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                        end if;
                    end if;

                when MASTACK =>
                    busy <= '0';
                    if scl_cnt = scl_period/2 then
                        if stop = '1' then
                            state <= IDLE;
                        else
                            state <= DATA;
                            bit_cnt <= 7;
                        end if;
                    end if;

            end case;
            
            -- SCL generation
            if scl_cnt = scl_period-1 then
                scl_cnt <= 0;
                scl_ena <= not scl_ena;
            else
                scl_cnt <= scl_cnt + 1;
            end if;
        end if;
    end process;

    -- Output read data
   process(clk, reset)
    begin
        if reset = '1' then
            data_rd <= (others => '0');
        elsif rising_edge(clk) then
            if state = DATA and read = '1' then
                data_rd <= data_rx;
            end if;
        end if;
    end process;

end RTL;