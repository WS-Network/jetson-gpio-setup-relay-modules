# Relay Module Control for Jetson Orin

This guide explains how to connect and control a relay module using the Jetson Orin GPIO pins.

## Hardware Connection

Connect your relay module to the Jetson Orin as follows:

1. **VCC/Power**: Connect to a 3.3V or 5V pin on the Jetson (depending on your relay module requirements)
2. **GND**: Connect to a GND pin on the Jetson
3. **Signal/IN**: Connect to Pin 7 on the Jetson 40-pin header

**Note**: Some relay modules are active-low (triggered by a LOW signal), while others are active-high (triggered by a HIGH signal). Check your relay module's documentation to determine which type you have.

## Wiring Diagram

```
Jetson Orin          Relay Module
-----------          ------------
Pin 7 (GPIO) ------> IN (Signal)
3.3V/5V     ------> VCC
GND         ------> GND
```

## Software Usage

Two Python scripts are provided for controlling the relay:

### 1. relay_control.py

This script cycles the relay on and off with configurable timing.

```bash
# Basic usage (cycles the relay on/off with default settings)
python3 relay_control.py

# Turn relay on for 5 seconds, off for 1 second, repeat 10 times
python3 relay_control.py --on-time 5 --off-time 1 --cycles 10

# For active-low relay modules
python3 relay_control.py --active-low

# Start with relay on
python3 relay_control.py --initial-state on
```

### 2. relay_switch.py

This script simply turns the relay on or off.

```bash
# Turn relay on
python3 relay_switch.py on

# Turn relay off
python3 relay_switch.py off

# Turn relay on for 10 seconds, then off
python3 relay_switch.py on --hold-time 10

# For active-low relay modules
python3 relay_switch.py on --active-low
```

## Troubleshooting

1. **Relay not responding**: 
   - Check your wiring connections
   - Verify that you're using the correct active-high/active-low setting
   - Ensure the relay module is receiving adequate power

2. **Permission issues**:
   - Run the script with sudo: `sudo python3 relay_switch.py on`
   - Or add your user to the gpio group: `sudo usermod -a -G gpio $USER`
   - Remember to log out and log back in for group changes to take effect

3. **GPIO already in use**:
   - Make sure no other program is using Pin 7
   - Run `GPIO.cleanup()` to release the pin if a previous program crashed

## Safety Considerations

1. Be careful when controlling high-voltage devices with relays
2. Ensure proper isolation between the Jetson and high-voltage circuits
3. For high-current applications, use appropriate relay ratings and wiring
