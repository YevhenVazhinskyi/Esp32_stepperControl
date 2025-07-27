# ESP32 Stepper Motor BLE Controller

A modular, industry-standard ESP32 firmware for controlling stepper motors via Bluetooth Low Energy (BLE). This project demonstrates modern embedded software architecture with clean separation of concerns, comprehensive testing, and professional documentation.

## 🏗️ Architecture Overview

This project follows ESP-IDF component-based architecture with the following modules:

```
├── components/
│   ├── stepper_motor/       # Motor driver and control logic
│   ├── ble_peripheral/      # BLE stack and GATT services
│   ├── motor_testing/       # Comprehensive test suite
│   └── common/             # Shared types and configurations
├── main/                   # Application entry point and coordination
└── docs/                   # Documentation and tutorials
```

## ✨ Features

### Core Functionality
- **Stepper Motor Control**: Full-step motor control with DRV8833 driver
- **BLE Remote Control**: Comprehensive BLE peripheral with custom GATT services
- **Position Tracking**: Absolute and relative positioning with fault detection
- **Visual Feedback**: LED indicators for status and commands
- **Comprehensive Testing**: Hardware validation and performance testing

### Technical Features
- **Modular Architecture**: Component-based design following industry best practices
- **Thread-Safe Operation**: FreeRTOS task-based motor control with command queuing
- **Real-time Monitoring**: BLE notifications for position and status updates
- **Fault Detection**: Hardware fault monitoring with automatic recovery
- **Configurable Hardware**: Centralized pin configuration for easy porting

## 🚀 Quick Start

### Prerequisites
- ESP-IDF v4.4+ installed and configured
- ESP32 development board
- DRV8833 motor driver
- Stepper motor (NEMA 17 recommended)
- LEDs for visual feedback

### Hardware Connections

#### Motor Driver (DRV8833)
```
ESP32 Pin    | DRV8833 Pin | Description
-------------|-------------|-------------
GPIO 26      | AIN1        | Motor Phase A1
GPIO 27      | AIN2        | Motor Phase A2
GPIO 14      | BIN1        | Motor Phase B1
GPIO 12      | BIN2        | Motor Phase B2
GPIO 13      | SLEEP       | Driver Enable
GPIO 25      | FAULT       | Fault Detection
3.3V         | VCC         | Logic Power
GND          | GND         | Ground
```

#### Status LEDs
```
ESP32 Pin    | LED         | Function
-------------|-------------|---------------------------
GPIO 2       | LED1        | Motor activity indicator
GPIO 4       | LED2        | Motor enable status
GPIO 5       | LED3        | Home command indicator
GPIO 18      | LED4        | Stop command indicator
```

### Building and Flashing
```bash
# Clone the repository
git clone <repository-url>
cd esp32-stepper-motor-ble

# Configure ESP-IDF environment
. $IDF_PATH/export.sh

# Build the project
idf.py build

# Flash to ESP32
idf.py flash monitor
```

### Initial Testing
```bash
# Run with motor tests enabled
idf.py menuconfig  # Enable CONFIG_ENABLE_MOTOR_TESTS
idf.py build flash monitor
```

## 🔧 Configuration

### Hardware Configuration
Modify pin assignments in `components/common/include/common_types.h`:

```c
// Motor driver pins
#define DEFAULT_MOTOR_AIN1      GPIO_NUM_26
#define DEFAULT_MOTOR_AIN2      GPIO_NUM_27
// ... etc

// LED pins  
#define DEFAULT_LED1_GPIO       GPIO_NUM_2
// ... etc
```

### Motor Parameters
Adjust motor specifications in `components/stepper_motor/include/stepper_motor.h`:

```c
#define STEPS_PER_REVOLUTION    200     // 1.8° motor
#define THREAD_PITCH_MM        2.0     // Lead screw pitch
#define STROKE_LENGTH_MM       50      // Travel distance
```

### BLE Configuration
Customize BLE settings in `components/common/include/common_types.h`:

```c
#define DEVICE_NAME             "ESP32_StepperMotor"
#define FIRMWARE_VERSION        "1.0.0"
#define BLE_ADV_INTERVAL_MIN    0x20    // 20ms
```

## 📱 BLE Interface

### Services and Characteristics

#### LED Control Service
- **Service UUID**: `12345678-90ab-cdef-1234-567890abcdef`
- Control 4 individual LEDs via Read/Write characteristics

#### Motor Control Service  
- **Service UUID**: `87654321-abcd-ef90-1234-567890abcdef`
- **Position**: Read current position, write target position
- **Command**: Send motor commands (stop, home, enable, etc.)
- **Status**: Read motor status and fault information
- **Speed**: Read/write motor speed (step delay)

### Motor Commands
Send commands as 3-byte packets: `[command:1][parameter:2]`

| Command | Value | Parameter | Description |
|---------|-------|-----------|-------------|
| STOP | 0 | - | Stop motor immediately |
| MOVE_ABSOLUTE | 1 | position | Move to absolute position |
| MOVE_RELATIVE | 2 | steps | Move relative steps |
| HOME | 3 | - | Return to position 0 |
| SET_SPEED | 4 | delay_ms | Set step delay |
| ENABLE | 5 | - | Enable motor driver |
| DISABLE | 6 | - | Disable motor driver |

## 🧪 Testing

### Motor Test Suite
```c
#include "motor_test.h"

// Run comprehensive test suite
motor_test_suite(&motor);

// Or run individual tests
motor_test_hardware(&motor);
motor_test_movement(&motor);
motor_test_position_accuracy(&motor);
motor_test_speed_variations(&motor);
```

### Test Coverage
- **Hardware Test**: GPIO pins, enable/disable, fault detection
- **Movement Test**: Bidirectional movement for 10 seconds each
- **Position Accuracy**: Multiple target positions with tolerance checking
- **Speed Variations**: 5 different speeds from 5ms to 100ms delays

## 📚 Component Documentation

Each component includes detailed documentation:

- [Stepper Motor Component](components/stepper_motor/README.md)
- [BLE Peripheral Component](components/ble_peripheral/README.md)
- [Motor Testing Component](components/motor_testing/README.md)
- [Common Types Component](components/common/README.md)

## 🔧 Development

### Adding New Features
1. Create new component in `components/` directory
2. Add `CMakeLists.txt` with dependencies
3. Include headers in `main/main.c`
4. Update documentation

### Code Style
- Follow ESP-IDF coding standards
- Use descriptive function and variable names
- Include comprehensive error handling
- Add ESP_LOG statements for debugging

### Testing
- All components include unit tests
- Hardware-in-the-loop testing available
- CI/CD pipeline validates builds

## 🤝 Integration

### Mobile App Integration
This firmware is designed to work with BLE client applications:
- Discover device by name "ESP32_StepperMotor"
- Connect and explore GATT services
- Write to characteristics to control motor
- Subscribe to notifications for real-time updates

### Industrial Integration
- Modular design allows easy integration into larger systems
- Standard ESP-IDF component structure
- Well-defined APIs for each subsystem
- Comprehensive error reporting

## 🛠️ Troubleshooting

### Common Issues

**Motor not moving:**
- Check wiring connections
- Verify power supply to DRV8833
- Monitor fault pin status
- Check ESP_LOG output for errors

**BLE connection issues:**
- Ensure device is advertising
- Check BLE client compatibility
- Verify characteristic UUIDs
- Monitor connection events in logs

**Position accuracy problems:**
- Check for mechanical binding
- Verify step sequence timing
- Calibrate motor parameters
- Run position accuracy test

### Debug Information
```bash
# Monitor ESP_LOG output
idf.py monitor

# Filter specific component logs
idf.py monitor | grep "STEPPER_MOTOR"
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- ESP-IDF framework by Espressif Systems
- NimBLE Bluetooth stack
- FreeRTOS real-time operating system
- Community contributions and feedback

## 📧 Support

For questions, issues, or contributions:
- Open an issue on GitHub
- Check component documentation
- Review ESP_LOG output for debugging
- Consult ESP-IDF documentation for framework details
