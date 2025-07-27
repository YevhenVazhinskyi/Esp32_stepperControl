# Stepper Motor Component

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

The component supports the following pin connections:

- **AIN1, AIN2**: Motor phase A control pins
- **BIN1, BIN2**: Motor phase B control pins  
- **SLEEP**: Motor driver enable/disable pin
- **FAULT**: Motor driver fault detection pin (active low)

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

// Create motor instance
stepper_motor_t motor = {
    .ain1_pin = DEFAULT_MOTOR_AIN1,
    .ain2_pin = DEFAULT_MOTOR_AIN2,
    .bin1_pin = DEFAULT_MOTOR_BIN1,
    .bin2_pin = DEFAULT_MOTOR_BIN2,
    .sleep_pin = DEFAULT_MOTOR_SLEEP,
    .fault_pin = DEFAULT_MOTOR_FAULT
};

// Initialize motor
esp_err_t ret = stepper_motor_init(&motor);
if (ret != ESP_OK) {
    ESP_LOGE("APP", "Motor initialization failed");
    return;
}

// Move to position 1000 steps
stepper_motor_move_to_position(&motor, 1000);

// Set speed to 20ms delay between steps
stepper_motor_set_speed(&motor, 20);

// Move 500 steps relative to current position
stepper_motor_move_relative(&motor, 500);

// Home motor (move to position 0)
stepper_motor_home(&motor);
```

## Configuration Constants

- `STEPS_PER_REVOLUTION`: 200 (1.8° stepper motor)
- `THREAD_PITCH_MM`: 2.0 (2mm thread pitch)
- `STROKE_LENGTH_MM`: 50 (50mm stroke length)
- `STEPS_PER_MM`: Calculated from above values

## Dependencies

- `driver` (ESP-IDF GPIO driver)
- `freertos` (FreeRTOS task and queue)
- `esp_log` (ESP-IDF logging)

## Thread Safety

This component is thread-safe. All motor commands are queued and processed sequentially by a dedicated FreeRTOS task. 