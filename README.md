# Jetson GPIO Relay Module Setup

This repository provides a one-command solution for setting up and controlling relay modules with NVIDIA Jetson devices using GPIO pins. It addresses the GPIO configuration issues in JetPack 6.2 on Jetson Orin devices and provides easy-to-use Python scripts for controlling relay modules.

## Features

- **One-Command Setup**: Simple script to automate the entire setup process
- **Device Tree Overlay**: Properly configures GPIO pins for bidirectional operation
- **Python Control Scripts**: Easy-to-use scripts for controlling relay modules
- **Flexible Configuration**: Support for both active-high and active-low relay modules
- **System Integration**: Installs scripts system-wide with convenient command aliases

## Supported Devices

- NVIDIA Jetson Orin Nano Developer Kit
- NVIDIA Jetson Orin Nano Super Developer Kit
- Other Jetson devices with JetPack 6.x (may require minor modifications)

## Quick Start

### One-Command Setup

```bash
curl -sSL https://raw.githubusercontent.com/USERNAME/jetson-gpio-setup-relay-modules/main/jetson_relay_setup.sh | sudo bash
```

After running the setup script:

1. Configure the device tree overlay:
   ```bash
   sudo configure-gpio-overlay
   ```
   - Follow the on-screen instructions to enable "Pin 7 gpio bidirectional"

2. Reboot your system:
   ```bash
   sudo reboot
   ```

3. Test the relay:
   ```bash
   relay-switch on
   ```

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on the [jetson-orin-gpio-patch](https://github.com/jetsonhacks/jetson-orin-gpio-patch) by JetsonHacks
- Uses the [Jetson.GPIO](https://github.com/NVIDIA/jetson-gpio) library by NVIDIA
