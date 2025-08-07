# Common Types Component

## 🚨🚨🚨 CRITICAL PROJECT RULE 🚨🚨🚨
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## CHANGE GPIO PIN MAPPING IN THIS PROJECT!!!
## 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨

**THIS COMPONENT CONTAINS THE FINAL GPIO PIN DEFINITIONS!**

**GPIO pins are FINAL and defined in: `include/common_types.h`**

**Changing pins requires complete hardware rewiring which takes VERY LONG TIME!**

## Overview

This component provides shared type definitions, constants, and configuration values used across all other components in the ESP32 stepper motor controller project.

## ⚠️ MOST IMPORTANT FILE: common_types.h ⚠️

This file contains the **FINAL GPIO PIN MAPPING** that must **NEVER BE CHANGED**!

## GPIO Pin Definitions

**⚠️ THESE PINS ARE FINAL AND MUST NEVER BE CHANGED! ⚠️**

### LED Control Pins
```c
#define DEFAULT_LED1_GPIO       GPIO_NUM_2   // LED1 - Motor Activity Indicator
#define DEFAULT_LED2_GPIO       GPIO_NUM_4   // LED2 - Enable Status Indicator
#define DEFAULT_LED3_GPIO       GPIO_NUM_5   // LED3 - Home Command Indicator
#define DEFAULT_LED4_GPIO       GPIO_NUM_18  // LED4 - Stop Command Indicator
```

### Stepper Motor Control Pins (DRV8833)
```c
#define DEFAULT_MOTOR_AIN1      GPIO_NUM_21  // Phase A Control (AIN1)
#define DEFAULT_MOTOR_AIN2      GPIO_NUM_19  // Phase A Control (AIN2)
#define DEFAULT_MOTOR_BIN1      GPIO_NUM_16  // Phase B Control (BIN1)
#define DEFAULT_MOTOR_BIN2      GPIO_NUM_17  // Phase B Control (BIN2)
#define DEFAULT_MOTOR_SLEEP     GPIO_NUM_23  // Driver Enable (SLEEP)
#define DEFAULT_MOTOR_FAULT     GPIO_NUM_22  // Error Detection (FAULT)
```

## System Configuration

### Device Information
```c
#define DEVICE_NAME             "ESP32_StepperMotor"
#define FIRMWARE_VERSION        "1.0.0"
```

### BLE Configuration
```c
#define BLE_DEVICE_NAME         DEVICE_NAME
#define BLE_APPEARANCE          0x0000
#define BLE_ADV_INTERVAL_MIN    0x20    // 20ms
#define BLE_ADV_INTERVAL_MAX    0x40    // 40ms
```

### Motor Configuration
```c
#define MOTOR_DEFAULT_SPEED     10      // ms delay between steps
#define MOTOR_MIN_SPEED         1       // minimum delay (fastest)
#define MOTOR_MAX_SPEED         1000    // maximum delay (slowest)
```

## Type Definitions

### System Status Enumeration
```c
typedef enum {
    SYSTEM_STATUS_INIT = 0,     // System initializing
    SYSTEM_STATUS_READY,        // System ready for operation
    SYSTEM_STATUS_RUNNING,      // System actively running
    SYSTEM_STATUS_ERROR,        // System error state
    SYSTEM_STATUS_TESTING       // System in test mode
} system_status_t;
```

### Error Code Enumeration
```c
typedef enum {
    ERR_MOTOR_FAULT = 0x1000,   // Motor hardware fault
    ERR_BLE_INIT_FAILED,        // BLE initialization failed
    ERR_MOTOR_INIT_FAILED,      // Motor initialization failed
    ERR_INVALID_COMMAND,        // Invalid command received
    ERR_HARDWARE_FAULT          // General hardware fault
} system_error_t;
```

## Usage in Other Components

### Including Common Types
```c
#include "common_types.h"
```

### Using GPIO Definitions
```c
// LED initialization
gpio_config_t led_config = {
    .pin_bit_mask = (1ULL << DEFAULT_LED1_GPIO) |
                    (1ULL << DEFAULT_LED2_GPIO) |
                    (1ULL << DEFAULT_LED3_GPIO) |
                    (1ULL << DEFAULT_LED4_GPIO),
    .mode = GPIO_MODE_OUTPUT,
    .pull_up_en = GPIO_PULLUP_DISABLE,
    .pull_down_en = GPIO_PULLDOWN_DISABLE,
    .intr_type = GPIO_INTR_DISABLE
};
gpio_config(&led_config);

// Motor initialization
stepper_motor_t motor = {
    .ain1_pin = DEFAULT_MOTOR_AIN1,
    .ain2_pin = DEFAULT_MOTOR_AIN2,
    .bin1_pin = DEFAULT_MOTOR_BIN1,
    .bin2_pin = DEFAULT_MOTOR_BIN2,
    .sleep_pin = DEFAULT_MOTOR_SLEEP,
    .fault_pin = DEFAULT_MOTOR_FAULT
};
```

### Using System Status
```c
system_status_t current_status = SYSTEM_STATUS_INIT;

// Update status during initialization
current_status = SYSTEM_STATUS_READY;

// Check for errors
if (motor_fault_detected) {
    current_status = SYSTEM_STATUS_ERROR;
}
```

## Hardware Pin Mapping Summary

| Function | GPIO | Direction | Component | DRV8833 Pin |
|----------|------|-----------|-----------|-------------|
| LED1 | GPIO2 | Output | BLE Peripheral | - |
| LED2 | GPIO4 | Output | BLE Peripheral | - |
| LED3 | GPIO5 | Output | BLE Peripheral | - |
| LED4 | GPIO18 | Output | BLE Peripheral | - |
| Motor AIN1 | GPIO21 | Output | Stepper Motor | AIN1 |
| Motor AIN2 | GPIO19 | Output | Stepper Motor | AIN2 |
| Motor BIN1 | GPIO16 | Output | Stepper Motor | BIN1 |
| Motor BIN2 | GPIO17 | Output | Stepper Motor | BIN2 |
| Motor SLEEP | GPIO23 | Output | Stepper Motor | SLEEP |
| Motor FAULT | GPIO22 | Input | Stepper Motor | FAULT |

## Component Dependencies

This component is used by:
- **ble_peripheral** - Uses LED GPIO definitions and BLE configuration
- **stepper_motor** - Uses motor GPIO definitions and motor configuration
- **motor_testing** - Uses motor configuration and system status types
- **main** - Uses all definitions and types

## Modification Rules

### ✅ ALLOWED MODIFICATIONS
- **Device name** - Can be changed if needed
- **Firmware version** - Should be updated with releases
- **BLE advertising intervals** - Can be tuned for performance
- **Motor speed defaults** - Can be adjusted for different motors
- **Error code additions** - New error codes can be added

### ❌ FORBIDDEN MODIFICATIONS
- **GPIO pin definitions** - NEVER CHANGE without hardware rewiring
- **Pin assignments** - NEVER MODIFY existing pin mappings
- **Hardware configuration** - NEVER ALTER without physical changes

## File Structure

```
components/common/
├── CMakeLists.txt          # Component build configuration
├── README.md              # This file
└── include/
    └── common_types.h     # MAIN DEFINITIONS FILE - NEVER CHANGE GPIO PINS!
```

## Validation Checklist

Before making ANY changes to this component:

1. ✅ **Hardware Impact**: Does this change require hardware modification?
2. ✅ **GPIO Pins**: Are you changing any GPIO pin definitions?
3. ✅ **Component Dependencies**: Will this break other components?
4. ✅ **Build System**: Will this affect the build process?
5. ✅ **Documentation**: Is documentation updated to match changes?

**If ANY GPIO pins are being changed - STOP! This requires hardware rewiring!**

## Emergency Recovery

If GPIO pins are accidentally changed:

1. **Immediately revert** the changes in `common_types.h`
2. **Rebuild and reflash** the firmware
3. **Verify hardware connections** still match code
4. **Test all functionality** to ensure proper operation

## ⚠️ FINAL WARNING ⚠️

**THIS COMPONENT CONTAINS THE MOST CRITICAL DEFINITIONS IN THE PROJECT!**

**NEVER CHANGE GPIO PIN DEFINITIONS WITHOUT COMPLETE HARDWARE REWIRING!**

**GPIO pin changes require VERY LONG TIME for hardware modifications!**

**The current GPIO pin mapping is FINAL and must not be modified!**

**All other components depend on these definitions being stable and correct!**