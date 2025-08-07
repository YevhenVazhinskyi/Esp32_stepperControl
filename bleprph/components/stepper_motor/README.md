# Stepper Motor Component

## 🚨🚨🚨 CRITICAL PROJECT RULE 🚨🚨🚨
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## CHANGE GPIO PIN MAPPING IN THIS PROJECT!!!
## 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨

**GPIO pins are FINAL and defined in: `components/common/include/common_types.h`**

**Changing pins requires complete hardware rewiring which takes VERY LONG TIME!**

## Overview

This component provides a complete driver for controlling stepper motors with DRV8833 motor drivers on ESP32.

## Features

- **Full-step motor control** with 4-pin interface
- **Queue-based command system** for reliable operation
- **Position tracking** with absolute and relative movements
- **Speed control** with configurable step delays
- **Fault detection** via hardware fault pin
- **Homing functionality** to reset position to zero
- **Thread-safe operation** with FreeRTOS task and queue

## Hardware Configuration

**⚠️ GPIO PINS ARE FINAL - NEVER CHANGE! ⚠️**

The component supports the following pin connections:

- **AIN1 (GPIO21)**: Motor phase A control pin
- **AIN2 (GPIO19)**: Motor phase A control pin  
- **BIN1 (GPIO16)**: Motor phase B control pin
- **BIN2 (GPIO17)**: Motor phase B control pin
- **SLEEP (GPIO23)**: Motor driver enable/disable pin
- **FAULT (GPIO22)**: Motor driver fault detection pin (active low)

## API Reference

### Initialization
```c
esp_err_t stepper_motor_init(stepper_motor_t *motor);
```

### Movement Commands
```c
esp_err_t stepper_motor_move_to_position(stepper_motor_t *motor, int16_t position);
esp_err_t stepper_motor_move_relative(stepper_motor_t *motor, int16_t steps);
esp_err_t stepper_motor_home(stepper_motor_t *motor);
esp_err_t stepper_motor_stop(stepper_motor_t *motor);
```

### Speed and Control
```c
esp_err_t stepper_motor_set_speed(stepper_motor_t *motor, uint16_t speed_delay_ms);
esp_err_t stepper_motor_enable(stepper_motor_t *motor);
esp_err_t stepper_motor_disable(stepper_motor_t *motor);
```

### Status and Monitoring
```c
motor_status_t stepper_motor_get_status(stepper_motor_t *motor);
int16_t stepper_motor_get_position(stepper_motor_t *motor);
bool stepper_motor_is_fault(stepper_motor_t *motor);
```

### Testing
```c
void stepper_motor_test_movement(stepper_motor_t *motor);
```

## Usage Example

```c
#include "stepper_motor.h"
#include "common_types.h"

// Create motor instance with FINAL GPIO pins
stepper_motor_t motor = {
    .ain1_pin = DEFAULT_MOTOR_AIN1,     // GPIO21 - NEVER CHANGE!
    .ain2_pin = DEFAULT_MOTOR_AIN2,     // GPIO19 - NEVER CHANGE!
    .bin1_pin = DEFAULT_MOTOR_BIN1,     // GPIO16 - NEVER CHANGE!
    .bin2_pin = DEFAULT_MOTOR_BIN2,     // GPIO17 - NEVER CHANGE!
    .sleep_pin = DEFAULT_MOTOR_SLEEP,   // GPIO23 - NEVER CHANGE!
    .fault_pin = DEFAULT_MOTOR_FAULT    // GPIO22 - NEVER CHANGE!
};

// Initialize motor
esp_err_t ret = stepper_motor_init(&motor);
if (ret != ESP_OK) {
    ESP_LOGE("MOTOR", "Failed to initialize motor");
    return;
}

// Move motor 100 steps forward
stepper_motor_move_relative(&motor, 100);

// Move to absolute position 500
stepper_motor_move_to_position(&motor, 500);

// Return to home position
stepper_motor_home(&motor);

// Set speed (delay between steps)
stepper_motor_set_speed(&motor, 5); // 5ms delay = faster movement
```

## Motor Control Theory

### Step Sequence
The driver uses a 4-phase full-step sequence:
```c
Step 0: AIN1=1, AIN2=0, BIN1=1, BIN2=0
Step 1: AIN1=0, AIN2=1, BIN1=1, BIN2=0
Step 2: AIN1=0, AIN2=1, BIN1=0, BIN2=1
Step 3: AIN1=1, AIN2=0, BIN1=0, BIN2=1
```

### Position Tracking
- **Current Position**: Tracked in steps from home (0)
- **Target Position**: Desired position for movement
- **Direction**: Forward (increasing) or backward (decreasing)
- **Limits**: Software limits prevent over-travel

### Speed Control
- **Speed Delay**: Milliseconds between each step
- **Range**: 1ms (fast) to 1000ms (slow)
- **Default**: 10ms per step

## DRV8833 Integration

### Pin Connections
| ESP32 GPIO | DRV8833 Pin | Function |
|------------|-------------|----------|
| GPIO21 | AIN1 | Phase A Control |
| GPIO19 | AIN2 | Phase A Control |
| GPIO16 | BIN1 | Phase B Control |
| GPIO17 | BIN2 | Phase B Control |
| GPIO23 | SLEEP | Driver Enable |
| GPIO22 | FAULT | Error Detection |

### Power Requirements
- **VM**: 5-12V motor power supply
- **VCC**: 3.3V logic power (from ESP32)
- **GND**: Common ground
- **Current**: Up to 1.2A per channel

## Error Handling

### Fault Detection
- **Hardware Fault**: DRV8833 FAULT pin monitoring
- **Over-current**: Detected by DRV8833
- **Over-temperature**: Detected by DRV8833
- **Under-voltage**: Detected by DRV8833

### Software Limits
- **Position Limits**: Prevent over-travel
- **Speed Limits**: Prevent invalid speed settings
- **Command Validation**: Check parameter ranges

## FreeRTOS Integration

### Motor Task
- **Priority**: 5 (high priority for real-time control)
- **Stack Size**: 4096 bytes
- **Queue**: 10 command queue depth
- **Timing**: Precise step timing with vTaskDelay

### Thread Safety
- **Queue-based Commands**: Thread-safe command processing
- **Atomic Operations**: Position updates are atomic
- **Mutex Protection**: Critical sections protected

## Troubleshooting

### Motor Not Moving
1. **Check GPIO Connections**: Verify pins match code definitions
2. **Power Supply**: Ensure DRV8833 has proper VM voltage
3. **Motor Wiring**: Check stepper motor connections
4. **Enable Pin**: Verify SLEEP pin is high (enabled)

### Erratic Movement
1. **Power Supply**: Check for voltage drops under load
2. **Wiring**: Verify solid connections to DRV8833
3. **Speed Settings**: Try slower speeds (higher delay)
4. **Motor Load**: Reduce mechanical load

### Fault Conditions
1. **Check FAULT Pin**: Monitor GPIO22 for low signal
2. **Current Limit**: Reduce motor current if over-current
3. **Temperature**: Allow cooling if over-temperature
4. **Power Supply**: Check VM voltage stability

## Performance Specifications

- **Step Resolution**: 1.8° per step (200 steps/revolution)
- **Maximum Speed**: 1000 steps/second (limited by delay=1ms)
- **Position Range**: ±32,767 steps (int16_t)
- **Accuracy**: ±1 step positioning accuracy
- **Response Time**: <10ms command to movement

## ⚠️ FINAL WARNING ⚠️
**NEVER CHANGE GPIO PINS WITHOUT COMPLETE HARDWARE REWIRING!**
**GPIO pin definitions are in `components/common/include/common_types.h`**
**Changing pins requires very long time for hardware modifications!**