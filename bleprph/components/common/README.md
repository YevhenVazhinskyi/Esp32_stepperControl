# Common Component

This component provides shared types, constants, and configurations used across all other components in the ESP32 stepper motor project.

## Features

- **Hardware pin definitions** with sensible defaults
- **System configuration constants** for device naming and versioning
- **BLE configuration parameters** for advertising and appearance
- **Motor configuration constants** for speed limits and defaults
- **Common type definitions** for system status and error codes
- **Centralized configuration** to avoid duplication across components

## Hardware Configuration

### Default GPIO Pin Assignments

#### LEDs
```c
#define DEFAULT_LED1_GPIO       GPIO_NUM_2
#define DEFAULT_LED2_GPIO       GPIO_NUM_4  
#define DEFAULT_LED3_GPIO       GPIO_NUM_5
#define DEFAULT_LED4_GPIO       GPIO_NUM_18
```

#### Motor Driver (DRV8833)
```c
#define DEFAULT_MOTOR_AIN1      GPIO_NUM_26
#define DEFAULT_MOTOR_AIN2      GPIO_NUM_27
#define DEFAULT_MOTOR_BIN1      GPIO_NUM_14
#define DEFAULT_MOTOR_BIN2      GPIO_NUM_12
#define DEFAULT_MOTOR_SLEEP     GPIO_NUM_13
#define DEFAULT_MOTOR_FAULT     GPIO_NUM_25
```

## System Configuration

```c
#define DEVICE_NAME             "ESP32_StepperMotor"
#define FIRMWARE_VERSION        "1.0.0"
```

## BLE Configuration

```c
#define BLE_DEVICE_NAME         DEVICE_NAME
#define BLE_APPEARANCE          0x0000
#define BLE_ADV_INTERVAL_MIN    0x20    // 20ms
#define BLE_ADV_INTERVAL_MAX    0x40    // 40ms
```

## Motor Configuration

```c
#define MOTOR_DEFAULT_SPEED     10      // ms delay between steps
#define MOTOR_MIN_SPEED         1       // minimum delay
#define MOTOR_MAX_SPEED         1000    // maximum delay
```

## Type Definitions

### System Status
```c
typedef enum {
    SYSTEM_STATUS_INIT = 0,
    SYSTEM_STATUS_READY,
    SYSTEM_STATUS_RUNNING,
    SYSTEM_STATUS_ERROR,
    SYSTEM_STATUS_TESTING
} system_status_t;
```

### Error Codes
```c
typedef enum {
    ERR_MOTOR_FAULT = 0x1000,
    ERR_BLE_INIT_FAILED,
    ERR_MOTOR_INIT_FAILED,
    ERR_INVALID_COMMAND,
    ERR_HARDWARE_FAULT
} system_error_t;
```

## Usage

Simply include the header in any component that needs access to common definitions:

```c
#include "common_types.h"

// Use predefined GPIO pins
stepper_motor_t motor = {
    .ain1_pin = DEFAULT_MOTOR_AIN1,
    .ain2_pin = DEFAULT_MOTOR_AIN2,
    .bin1_pin = DEFAULT_MOTOR_BIN1,
    .bin2_pin = DEFAULT_MOTOR_BIN2,
    .sleep_pin = DEFAULT_MOTOR_SLEEP,
    .fault_pin = DEFAULT_MOTOR_FAULT
};

// Use system constants
ESP_LOGI("APP", "Device: %s, Version: %s", DEVICE_NAME, FIRMWARE_VERSION);

// Use status types
system_status_t status = SYSTEM_STATUS_INIT;
```

## Customization

To customize hardware configuration for your specific board:

1. Copy `common_types.h` to your project
2. Modify the GPIO pin definitions as needed
3. Update device name and version as appropriate
4. Adjust motor speed limits if needed

## Dependencies

- `driver` (ESP-IDF GPIO driver for GPIO definitions)

## Design Philosophy

This component follows the principle of "single source of truth" for configuration:
- All hardware pin assignments are defined once
- System-wide constants are centralized
- Type definitions are shared to ensure consistency
- Easy to modify for different hardware configurations

By centralizing these definitions, the entire project can be easily adapted to different hardware configurations by changing only this component. 