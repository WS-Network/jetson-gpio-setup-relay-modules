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
import argparse
import time
import sys

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
