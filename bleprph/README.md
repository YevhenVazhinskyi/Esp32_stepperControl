# ESP32 Stepper Motor Controller with BLE

## 🚨🚨🚨 CRITICAL PROJECT RULE 🚨🚨🚨
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## CHANGE GPIO PIN MAPPING IN THIS PROJECT!!!
## 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨

**GPIO pins are FINAL and defined in: `components/common/include/common_types.h`**

**Changing pins requires complete hardware rewiring which takes VERY LONG TIME!**

## Project Overview

This project implements a complete ESP32-based stepper motor controller with Bluetooth Low Energy (BLE) connectivity. The system allows remote control of stepper motors through a mobile app or BLE client.

### Key Features

- **BLE Peripheral** - ESP32 advertises as BLE device for mobile app connection
- **Stepper Motor Control** - Precise position control with DRV8833 driver
- **LED Status Indicators** - Visual feedback for motor operations
- **Queue-based Commands** - Reliable motor command processing
- **Position Tracking** - Absolute and relative positioning
- **Fault Detection** - Hardware fault monitoring

### Hardware Components

- **ESP32 Development Board** - Main microcontroller
- **DRV8833 Motor Driver** - Stepper motor driver IC
- **Stepper Motor** - NEMA 17 or similar
- **LEDs** - Status indication (4 LEDs)
- **Power Supply** - 5-12V for motor, 3.3V for logic

### GPIO Pin Configuration

**⚠️ THESE PINS ARE FINAL - NEVER CHANGE WITHOUT HARDWARE REWIRING! ⚠️**

```c
// LED Control
#define DEFAULT_LED1_GPIO       GPIO_NUM_2
#define DEFAULT_LED2_GPIO       GPIO_NUM_4
#define DEFAULT_LED3_GPIO       GPIO_NUM_5
#define DEFAULT_LED4_GPIO       GPIO_NUM_18

// Motor Control (DRV8833)
#define DEFAULT_MOTOR_AIN1      GPIO_NUM_21  // Phase A Control
#define DEFAULT_MOTOR_AIN2      GPIO_NUM_19  // Phase A Control
#define DEFAULT_MOTOR_BIN1      GPIO_NUM_16  // Phase B Control
#define DEFAULT_MOTOR_BIN2      GPIO_NUM_17  // Phase B Control
#define DEFAULT_MOTOR_SLEEP     GPIO_NUM_23  // Driver Enable
#define DEFAULT_MOTOR_FAULT     GPIO_NUM_22  // Error Detection
```

## Quick Start

### Prerequisites

- ESP-IDF v6.0 or later
- ESP32 development board
- DRV8833 motor driver
- Stepper motor
- Mobile device with BLE capability

### Build and Flash

```bash
# Source ESP-IDF environment
source ~/esp/esp-idf/export.sh

# Build project
idf.py build

# Flash to ESP32
idf.py flash

# Monitor output
idf.py monitor
```

### BLE Connection

1. Flash the firmware to ESP32
2. ESP32 will start advertising as "ESP32_StepperMotor"
3. Connect with BLE scanner or mobile app
4. Use GATT characteristics to control motor and LEDs

## Project Structure

```
bleprph/
├── components/
│   ├── ble_peripheral/     # BLE functionality
│   ├── stepper_motor/      # Motor control
│   ├── motor_testing/      # Test functions
│   └── common/            # Shared definitions (GPIO PINS!)
├── main/                  # Main application
├── Plantuml/             # System diagrams
└── tutorial/             # Documentation
```

## BLE Services

### LED Control Service
- **UUID**: `12345678-90ab-cdef-1234-567890abcdef`
- **Characteristics**: LED1, LED2, LED3, LED4 control

### Motor Control Service
- **UUID**: `87654321-dcba-fedc-4321-ba0987654321`
- **Characteristics**: Position, Command, Status, Speed

## Motor Commands

- **Move Absolute**: Move to specific position
- **Move Relative**: Move by number of steps
- **Home**: Return to zero position
- **Stop**: Emergency stop
- **Set Speed**: Adjust movement speed

## Safety Features

- **Fault Detection**: Hardware fault monitoring via DRV8833 FAULT pin
- **Position Limits**: Software limits to prevent over-travel
- **Emergency Stop**: Immediate motor stop capability
- **Power Management**: Motor driver sleep mode for power saving

## Troubleshooting

### Motor Not Moving
1. Check GPIO pin connections match code definitions
2. Verify DRV8833 power supply (5-12V on VM pin)
3. Check motor wiring to DRV8833 outputs
4. Monitor serial output for error messages

### BLE Connection Issues
1. Verify ESP32 is advertising (check serial output)
2. Clear BLE cache on mobile device
3. Check BLE scanner for "ESP32_StepperMotor" device
4. Ensure proper BLE service UUIDs

### Build Errors
1. Check ESP-IDF version (v6.0+ required)
2. Source ESP-IDF environment before building
3. Clean build directory: `idf.py fullclean`
4. Check component dependencies

## Documentation

- `PIN_MAPPING.md` - Hardware pin assignments
- `tutorial/` - Detailed walkthroughs
- `Plantuml/` - System architecture diagrams
- Component READMEs - Individual component documentation

## ⚠️ FINAL WARNING ⚠️
**NEVER CHANGE GPIO PINS WITHOUT COMPLETE HARDWARE REWIRING!**
**GPIO pin definitions are in `components/common/include/common_types.h`**
**Changing pins requires very long time for hardware modifications!**