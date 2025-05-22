#!/usr/bin/env python

# Copyright (c) 2019-2022, NVIDIA CORPORATION. All rights reserved.
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

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
