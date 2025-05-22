#!/bin/bash

# Jetson GPIO Relay Module Setup Script
# This script automates the setup process for using relay modules with Jetson GPIO pins
# It compiles and installs the device tree overlay, installs required packages,
# and sets up the example scripts

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
    WORK_DIR=$(pwd)
    print_msg "Working directory: ${WORK_DIR}" "${YELLOW}"
    
    # Step 1: Install required packages
    print_msg "\nStep 1: Installing required packages..." "${BLUE}"
    apt update
    check_success "Package lists updated." "Failed to update package lists."
    
    apt install -y python3 python3-pip device-tree-compiler
    check_success "Required packages installed." "Failed to install required packages."
    
    pip3 install --upgrade Jetson.GPIO
    check_success "Jetson.GPIO library installed/upgraded." "Failed to install Jetson.GPIO library."
    
    # Step 2: Compile and install device tree overlay
    print_msg "\nStep 2: Compiling and installing device tree overlay..." "${BLUE}"
    
    # Check if overlay file exists
    if [ ! -f "${WORK_DIR}/pin7_as_gpio.dts" ]; then
        print_msg "Creating device tree overlay file..." "${YELLOW}"
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
    fi
    
    # Compile the device tree overlay
    dtc -O dtb -o "${WORK_DIR}/pin7_as_gpio.dtbo" "${WORK_DIR}/pin7_as_gpio.dts"
    check_success "Device tree overlay compiled." "Failed to compile device tree overlay."
    
    # Copy the compiled overlay to /boot
    cp "${WORK_DIR}/pin7_as_gpio.dtbo" /boot/
    check_success "Device tree overlay copied to /boot." "Failed to copy device tree overlay to /boot."
    
    # Step 3: Create example scripts directory
    print_msg "\nStep 3: Setting up example scripts..." "${BLUE}"
    
    mkdir -p "${WORK_DIR}/examples"
    check_success "Examples directory created." "Failed to create examples directory."
    
    # Create relay control script
    print_msg "Creating relay control scripts..." "${YELLOW}"
    
    cat > "${WORK_DIR}/examples/relay_control.py" << 'EOF'
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
    
    cat > "${WORK_DIR}/examples/relay_switch.py" << 'EOF'
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
    
    # Make scripts executable
    chmod +x "${WORK_DIR}/examples/relay_control.py" "${WORK_DIR}/examples/relay_switch.py"
    check_success "Scripts made executable." "Failed to make scripts executable."
    
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
    print_msg "To complete the setup, you need to run the Jetson IO tool and enable the overlay:" "${YELLOW}"
    print_msg "sudo /opt/nvidia/jetson-io/jetson-io.py" "${GREEN}"
    print_msg "Then select 'Configure Jetson 40pin Header' and enable 'Pin 7 gpio bidirectional'" "${GREEN}"
    print_msg "After that, reboot your system for the changes to take effect." "${GREEN}"
    
    # Final instructions
    print_msg "\nSetup completed successfully!" "${GREEN}"
    print_msg "After rebooting, you can test the relay with:" "${YELLOW}"
    print_msg "python3 ${WORK_DIR}/examples/relay_switch.py on" "${GREEN}"
    print_msg "python3 ${WORK_DIR}/examples/relay_control.py --cycles 5" "${GREEN}"
    
    print_msg "\nRemember to reboot your system for all changes to take effect:" "${YELLOW}"
    print_msg "sudo reboot" "${GREEN}"
}

# Run the main function
main
