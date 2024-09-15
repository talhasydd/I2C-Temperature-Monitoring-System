# I2C-Temperature-Monitoring-System

## Overview

This VHDL project implements an I2C-based temperature monitoring system with three main components: I2CMaster, TempProcessor, and I2CtopLevel. This I2C-based temperature monitoring system is designed to interface with an I2C temperature sensor, read temperature data, process it, and provide visual feedback through LEDs. 

The system begins by initializing the I2C master, which then communicates with the temperature sensor using the I2C protocol. It sends a start condition, followed by the sensor's address and a read command. The master then reads two bytes of temperature data from the sensor, typically in a fixed-point format where the temperature is represented as a 16-bit value with the lower 8 bits representing fractional degrees. Throughout this process, the I2C master handles the intricacies of the I2C protocol, including clock stretching, acknowledging received data, and generating stop conditions.
Once the raw temperature data is acquired, it's passed to the TempProcessor component. This component converts the fixed-point representation into a usable temperature value and compares it against predefined thresholds. Based on these comparisons, it determines whether the current temperature falls into a "cold," "normal," or "hot" range. The system then outputs a 3-bit signal to control three LEDs: blue for cold, green for normal, and red for hot. This entire process - from initiating the I2C communication to updating the LED output - is orchestrated by the top-level component, which manages the state transitions and ensures proper timing and coordination between the I2C master and temperature processing units. The system continuously repeats this cycle, providing real-time temperature monitoring and visual feedback.

## Key Processes and State Machines

### I2CMaster

The I2CMaster component implements the I2C protocol using a state machine with the following states:

1. IDLE
2. STARTED
3. COMMAND
4. SLVACK (Slave Acknowledge)
5. DATA
6. MASTACK (Master Acknowledge)

#### Main Process:
- Handles state transitions
- Controls SCL and SDA lines
- Manages data transmission and reception

#### Clock Generation Process:
- Generates the SCL signal based on the defined I2C speed

### TempProcessor

The TempProcessor uses a single process to handle temperature data:

- Converts raw sensor data to temperature
- Compares temperature against predefined thresholds
- Sets LED output based on temperature range

### I2CtopLevel

The top-level component uses a state machine to coordinate I2C communication and temperature processing:

1. IDLE
2. START_TEMP_READ
3. SEND_ADDR
4. SEND_REG
5. READ_MSB
6. READ_LSB
7. PROCESS_TEMP

#### Main Process:
- Manages overall system operation
- Coordinates between I2CMaster and TempProcessor
- Handles temperature reading cycle

## Testbenches

1. **I2CmasterTB**: Tests I2C protocol operations
This testbench verifies the functionality of the I2CMaster component.
Test Cases:

- Write operation
- Read operation
- Write followed by Read
- Multiple writes
- Stop condition

2. **TempProcessorTB**: Verifies temperature processing and LED control
This testbench checks the TempProcessor component's behavior under various temperature conditions.
Test Cases:

- Low temperature (below 20°C)
- Normal temperature (between 20°C and 30°C)
- High temperature (above 30°C)
- Edge cases (exactly 20°C and 30°C)
- Extreme temperatures (very low and very high)

3. **I2CtopLevelTB**: Validates entire system functionality
This testbench validates the entire system's operation, including I2C communication and temperature processing.
Key Features:

- Simulates an I2C slave (temperature sensor)
- Tests the complete temperature reading and processing cycle
- Verifies LED output based on simulated temperature data
