#!/bin/bash

# Jetson GPIO Relay Module Setup Script
# This script automates the complete setup process for using relay modules with Jetson GPIO pins
# It can be downloaded and executed with a single curl command:
# curl -sSL https://raw.githubusercontent.com/yourusername/jetson-gpio-setup-relay-modules/main/jetson_relay_setup.sh | bash

set -e  # Exit on error

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Function to print colored messages
print_msg() {
    echo -e "${BOLD}${2}${1}${RESET}"
}

# Function to check if command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        print_msg "$1" "${GREEN}"
    else
        print_msg "Error: $2" "${RED}"
        exit 1
    fi
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_msg "This script must be run as root (sudo). Exiting..." "${RED}"
        exit 1
    fi
}

# Function to check if Jetson device
check_jetson() {
    if [ ! -d "/opt/nvidia/jetson-io" ]; then
        print_msg "This doesn't appear to be a Jetson device. Exiting..." "${RED}"
        exit 1
    fi
}

# Main setup function
main() {
    print_msg "Jetson GPIO Relay Module Setup" "${BLUE}"
    print_msg "===============================" "${BLUE}"
    
    # Check if running as root
    check_root
    
    # Check if this is a Jetson device
    check_jetson
    
    # Create working directory
    WORK_DIR="/tmp/jetson-gpio-relay-setup"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    print_msg "Working directory: ${WORK_DIR}" "${YELLOW}"
    
    # Step 1: Install required packages
    print_msg "\nStep 1: Installing required packages..." "${BLUE}"
    apt update
    check_success "Package lists updated." "Failed to update package lists."
    
    apt install -y python3 python3-pip device-tree-compiler git
    check_success "Required packages installed." "Failed to install required packages."
    
    pip3 install --upgrade Jetson.GPIO
    check_success "Jetson.GPIO library installed/upgraded." "Failed to install Jetson.GPIO library."
    
    # Step 2: Create device tree overlay
    print_msg "\nStep 2: Creating device tree overlay..." "${BLUE}"
    
    cat > "${WORK_DIR}/pin7_as_gpio.dts" << 'EOF'
/dts-v1/;
/plugin/;

/ {
    jetson-header-name = "Jetson 40pin Header";
    overlay-name = "Pin 7 gpio bidirectional";
    compatible = "nvidia,p3768-0000+p3767-0000\0nvidia,p3768-0000+p3767-0001\0nvidia,p3768-0000+p3767-0003\0nvidia,p3768-0000+p3767-0004\0nvidia,p3768-0000+p3767-0005\0nvidia,p3768-0000+p3767-0000-super\0nvidia,p3768-0000+p3767-0001-super\0nvidia,p3768-0000+p3767-0003-super\0nvidia,p3768-0000+p3767-0004-super\0nvidia,p3768-0000+p3767-0005-super\0nvidia,p3509-0000+p3767-0000\0nvidia,p3509-0000+p3767-0001\0nvidia,p3509-0000+p3767-0003\0nvidia,p3509-0000+p3767-0004\0nvidia,p3509-0000+p3767-0005";


    fragment@0 {
        target = <&pinmux>;

        __overlay__ {
            pinctrl-names = "default";
            pinctrl-0 = <&jetson_io_pinmux>;
            
            jetson_io_pinmux: exp-header-pinmux {
                hdr40-pin7 {
                    nvidia,pins = "soc_gpio59_pac6";
                    nvidia,tristate = <0x0>;
                    nvidia,enable-input = <0x1>;
                    nvidia,pull = <0x0>;
                };
            };
        };
    };
};
EOF
    check_success "Device tree overlay file created." "Failed to create device tree overlay file."
    
    # Compile the device tree overlay
    dtc -O dtb -o "${WORK_DIR}/pin7_as_gpio.dtbo" "${WORK_DIR}/pin7_as_gpio.dts"
    check_success "Device tree overlay compiled." "Failed to compile device tree overlay."
    
    # Copy the compiled overlay to /boot
    cp "${WORK_DIR}/pin7_as_gpio.dtbo" /boot/
    check_success "Device tree overlay copied to /boot." "Failed to copy device tree overlay to /boot."
    
    # Step 3: Create example scripts directory
    print_msg "\nStep 3: Setting up example scripts..." "${BLUE}"
    
    INSTALL_DIR="/opt/jetson-gpio-relay"
    mkdir -p "${INSTALL_DIR}/examples"
    check_success "Installation directory created." "Failed to create installation directory."
    
    # Create relay control script
    print_msg "Creating relay control scripts..." "${YELLOW}"
    
    cat > "${INSTALL_DIR}/examples/relay_control.py" << 'EOF'
#!/usr/bin/env python3

import Jetson.GPIO as GPIO
import time
import argparse

# Pin Definitions
relay_pin = 7  # Jetson Board Pin 7

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Control a relay module connected to Jetson GPIO')
    parser.add_argument('--on-time', type=float, default=2.0, help='Time in seconds to keep the relay ON (default: 2.0)')
    parser.add_argument('--off-time', type=float, default=2.0, help='Time in seconds to keep the relay OFF (default: 2.0)')
    parser.add_argument('--cycles', type=int, default=0, help='Number of ON/OFF cycles (0 for infinite, default: 0)')
    parser.add_argument('--initial-state', type=str, choices=['on', 'off'], default='off', 
                        help='Initial state of the relay (on/off, default: off)')
    parser.add_argument('--active-high', action='store_true', 
                        help='Set if relay is activated by HIGH signal (default: relay is activated by HIGH)')
    parser.add_argument('--active-low', dest='active_high', action='store_false',
                        help='Set if relay is activated by LOW signal')
    parser.set_defaults(active_high=True)
    
    args = parser.parse_args()
    
    # Define relay states based on active high/low configuration
    if args.active_high:
        RELAY_ON = GPIO.HIGH
        RELAY_OFF = GPIO.LOW
    else:
        RELAY_ON = GPIO.LOW
        RELAY_OFF = GPIO.HIGH
    
    # Pin Setup:
    GPIO.setmode(GPIO.BOARD)  # Jetson board numbering scheme
    
    # Set pin as an output pin with initial state
    initial_state = RELAY_ON if args.initial_state == 'on' else RELAY_OFF
    GPIO.setup(relay_pin, GPIO.OUT, initial=initial_state)
    
    print("Relay Control Demo")
    print(f"Relay connected to pin {relay_pin}")
    print(f"Relay is {'active HIGH' if args.active_high else 'active LOW'}")
    print(f"ON time: {args.on_time} seconds")
    print(f"OFF time: {args.off_time} seconds")
    print(f"Cycles: {'Infinite' if args.cycles == 0 else args.cycles}")
    print("Press CTRL+C to exit")
    
    try:
        cycle_count = 0
        while args.cycles == 0 or cycle_count < args.cycles:
            # Turn relay ON
            GPIO.output(relay_pin, RELAY_ON)
            print(f"Relay ON (Pin {relay_pin} set to {'HIGH' if RELAY_ON == GPIO.HIGH else 'LOW'})")
            time.sleep(args.on_time)
            
            # Turn relay OFF
            GPIO.output(relay_pin, RELAY_OFF)
            print(f"Relay OFF (Pin {relay_pin} set to {'HIGH' if RELAY_OFF == GPIO.HIGH else 'LOW'})")
            time.sleep(args.off_time)
            
            if args.cycles > 0:
                cycle_count += 1
                print(f"Completed cycle {cycle_count} of {args.cycles}")
    
    except KeyboardInterrupt:
        print("Program stopped by user")
    
    finally:
        # Clean up and turn off relay before exiting
        GPIO.output(relay_pin, RELAY_OFF)
        print(f"Cleaning up GPIO and turning relay OFF")
        GPIO.cleanup()

if __name__ == '__main__':
    main()
EOF
    check_success "Relay control script created." "Failed to create relay control script."
    
    cat > "${INSTALL_DIR}/examples/relay_switch.py" << 'EOF'
#!/usr/bin/env python3

import Jetson.GPIO as GPIO
import argparse
import time

# Pin Definitions
relay_pin = 7  # Jetson Board Pin 7

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Simple relay switch control')
    parser.add_argument('state', choices=['on', 'off'], help='Set relay to ON or OFF')
    parser.add_argument('--active-high', action='store_true', 
                        help='Set if relay is activated by HIGH signal (default: relay is activated by HIGH)')
    parser.add_argument('--active-low', dest='active_high', action='store_false',
                        help='Set if relay is activated by LOW signal')
    parser.add_argument('--hold-time', type=float, default=0, 
                        help='Time in seconds to hold the state before exiting (0 = indefinite, default: 0)')
    parser.set_defaults(active_high=True)
    
    args = parser.parse_args()
    
    # Define relay states based on active high/low configuration
    if args.active_high:
        RELAY_ON = GPIO.HIGH
        RELAY_OFF = GPIO.LOW
    else:
        RELAY_ON = GPIO.LOW
        RELAY_OFF = GPIO.HIGH
    
    # Pin Setup:
    GPIO.setmode(GPIO.BOARD)  # Jetson board numbering scheme
    GPIO.setup(relay_pin, GPIO.OUT)
    
    try:
        if args.state == 'on':
            GPIO.output(relay_pin, RELAY_ON)
            print(f"Relay ON (Pin {relay_pin} set to {'HIGH' if RELAY_ON == GPIO.HIGH else 'LOW'})")
        else:
            GPIO.output(relay_pin, RELAY_OFF)
            print(f"Relay OFF (Pin {relay_pin} set to {'HIGH' if RELAY_OFF == GPIO.HIGH else 'LOW'})")
        
        if args.hold_time > 0:
            print(f"Holding state for {args.hold_time} seconds...")
            time.sleep(args.hold_time)
        elif args.hold_time == 0:
            print("Press CTRL+C to exit and cleanup GPIO")
            while True:
                time.sleep(1)
    
    except KeyboardInterrupt:
        print("\nProgram stopped by user")
    
    finally:
        # Clean up GPIO
        GPIO.cleanup()
        print("GPIO cleaned up")

if __name__ == '__main__':
    main()
EOF
    check_success "Relay switch script created." "Failed to create relay switch script."
    
    # Create README file
    cat > "${INSTALL_DIR}/README.md" << 'EOF'
# Jetson GPIO Relay Module Setup

This package provides tools and scripts for controlling relay modules with NVIDIA Jetson devices using GPIO pins.

## Hardware Connection

Connect your relay module to the Jetson as follows:

```
Jetson Orin          Relay Module
-----------          ------------
Pin 7 (GPIO) ------> IN (Signal)
3.3V/5V     ------> VCC
GND         ------> GND
```

**Note**: Some relay modules are active-low (triggered by a LOW signal), while others are active-high (triggered by a HIGH signal). Check your relay module's documentation to determine which type you have.

## Usage

### Relay Control Script

This script cycles the relay on and off with configurable timing.

```bash
# Basic usage (cycles the relay on/off with default settings)
python3 /opt/jetson-gpio-relay/examples/relay_control.py

# Turn relay on for 5 seconds, off for 1 second, repeat 10 times
python3 /opt/jetson-gpio-relay/examples/relay_control.py --on-time 5 --off-time 1 --cycles 10

# For active-low relay modules
python3 /opt/jetson-gpio-relay/examples/relay_control.py --active-low

# Start with relay on
python3 /opt/jetson-gpio-relay/examples/relay_control.py --initial-state on
```

### Relay Switch Script

This script simply turns the relay on or off.

```bash
# Turn relay on
python3 /opt/jetson-gpio-relay/examples/relay_switch.py on

# Turn relay off
python3 /opt/jetson-gpio-relay/examples/relay_switch.py off

# Turn relay on for 10 seconds, then off
python3 /opt/jetson-gpio-relay/examples/relay_switch.py on --hold-time 10

# For active-low relay modules
python3 /opt/jetson-gpio-relay/examples/relay_switch.py on --active-low
```

## Troubleshooting

1. **Relay not responding**: 
   - Check your wiring connections
   - Verify that you're using the correct active-high/active-low setting
   - Ensure the relay module is receiving adequate power

2. **Permission issues**:
   - Run the script with sudo: `sudo python3 /opt/jetson-gpio-relay/examples/relay_switch.py on`
   - Or add your user to the gpio group: `sudo usermod -a -G gpio $USER`
   - Remember to log out and log back in for group changes to take effect

3. **GPIO already in use**:
   - Make sure no other program is using Pin 7
   - Run `GPIO.cleanup()` to release the pin if a previous program crashed
EOF
    check_success "README file created." "Failed to create README file."
    
    # Make scripts executable
    chmod +x "${INSTALL_DIR}/examples/relay_control.py" "${INSTALL_DIR}/examples/relay_switch.py"
    check_success "Scripts made executable." "Failed to make scripts executable."
    
    # Create convenience symlinks
    ln -sf "${INSTALL_DIR}/examples/relay_control.py" /usr/local/bin/relay-control
    ln -sf "${INSTALL_DIR}/examples/relay_switch.py" /usr/local/bin/relay-switch
    check_success "Convenience symlinks created." "Failed to create symlinks."
    
    # Step 4: Add user to gpio group
    print_msg "\nStep 4: Adding user to gpio group..." "${BLUE}"
    
    # Get the username of the user who ran sudo
    if [ -n "$SUDO_USER" ]; then
        USER_TO_ADD="$SUDO_USER"
    else
        USER_TO_ADD="$USER"
    fi
    
    usermod -a -G gpio "$USER_TO_ADD"
    check_success "User '$USER_TO_ADD' added to gpio group." "Failed to add user to gpio group."
    
    # Step 5: Configure device tree overlay
    print_msg "\nStep 5: Configuring device tree overlay..." "${BLUE}"
    
    # Create a script to help with jetson-io configuration
    cat > "${INSTALL_DIR}/configure_overlay.sh" << 'EOF'
#!/bin/bash
echo "This script will help you configure the device tree overlay."
echo "It will launch the Jetson IO tool. Please follow these steps:"
echo "1. Select 'Configure Jetson 40pin Header'"
echo "2. Enable 'Pin 7 gpio bidirectional'"
echo "3. Save and exit"
echo ""
echo "Press Enter to continue..."
read

sudo /opt/nvidia/jetson-io/jetson-io.py

echo ""
echo "Configuration complete. Please reboot your system for changes to take effect:"
echo "sudo reboot"
EOF
    chmod +x "${INSTALL_DIR}/configure_overlay.sh"
    check_success "Overlay configuration script created." "Failed to create overlay configuration script."
    
    ln -sf "${INSTALL_DIR}/configure_overlay.sh" /usr/local/bin/configure-gpio-overlay
    check_success "Overlay configuration symlink created." "Failed to create overlay configuration symlink."
    
    # Final instructions
    print_msg "\nSetup completed successfully!" "${GREEN}"
    print_msg "\nNext steps:" "${YELLOW}"
    print_msg "1. Configure the device tree overlay:" "${YELLOW}"
    print_msg "   sudo configure-gpio-overlay" "${GREEN}"
    print_msg "2. Reboot your system:" "${YELLOW}"
    print_msg "   sudo reboot" "${GREEN}"
    print_msg "3. After rebooting, test the relay with:" "${YELLOW}"
    print_msg "   relay-switch on" "${GREEN}"
    print_msg "   relay-control --cycles 5" "${GREEN}"
    
    print_msg "\nDocumentation is available at:" "${YELLOW}"
    print_msg "   /opt/jetson-gpio-relay/README.md" "${GREEN}"
    
    print_msg "\nThank you for using the Jetson GPIO Relay Module Setup!" "${BLUE}"
}

# Run the main function
main
