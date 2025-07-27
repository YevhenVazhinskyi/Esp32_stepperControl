# Motor Testing Component

This component provides comprehensive testing functionality for stepper motor hardware validation and performance verification.

## Features

- **Hardware validation** - Test GPIO pins and driver functionality
- **Movement testing** - Verify motor can move in both directions
- **Position accuracy** - Test precision of position tracking
- **Speed variations** - Test different motor speeds
- **Comprehensive test suite** - Run all tests in sequence
- **Detailed logging** - ESP_LOG output for all test results

## Test Functions

### Hardware Test
```c
esp_err_t motor_test_hardware(stepper_motor_t *motor);
```
- Tests enable/disable functionality
- Verifies fault pin status
- Validates basic driver operation

### Movement Test  
```c
esp_err_t motor_test_movement(stepper_motor_t *motor);
```
- Runs 10-second movements in each direction
- Tests basic step sequencing
- Validates fault detection during movement

### Position Accuracy Test
```c
esp_err_t motor_test_position_accuracy(stepper_motor_t *motor);
```
- Tests multiple target positions
- Verifies position tracking accuracy
- Allows up to 5-step tolerance for mechanical variations

### Speed Variations Test
```c
esp_err_t motor_test_speed_variations(stepper_motor_t *motor);
```
- Tests different step delays (5ms to 100ms)
- Validates speed control functionality
- Tests forward and backward movements at each speed

### Comprehensive Test Suite
```c
esp_err_t motor_test_suite(stepper_motor_t *motor);
```
- Runs all tests in sequence
- Provides pass/fail results for each test
- Stops on first test failure

## Usage Example

```c
#include "motor_test.h"
#include "stepper_motor.h"
#include "common_types.h"

// Create and initialize motor
stepper_motor_t motor = {
    .ain1_pin = DEFAULT_MOTOR_AIN1,
    .ain2_pin = DEFAULT_MOTOR_AIN2,
    .bin1_pin = DEFAULT_MOTOR_BIN1,
    .bin2_pin = DEFAULT_MOTOR_BIN2,
    .sleep_pin = DEFAULT_MOTOR_SLEEP,
    .fault_pin = DEFAULT_MOTOR_FAULT
};

stepper_motor_init(&motor);

// Run individual tests
if (motor_test_hardware(&motor) == ESP_OK) {
    ESP_LOGI("TEST", "Hardware test passed");
}

if (motor_test_movement(&motor) == ESP_OK) {
    ESP_LOGI("TEST", "Movement test passed");  
}

// Or run comprehensive test suite
esp_err_t result = motor_test_suite(&motor);
if (result == ESP_OK) {
    ESP_LOGI("TEST", "All tests passed!");
} else {
    ESP_LOGE("TEST", "Test suite failed");
}
```

## Test Results

Each test function returns:
- `ESP_OK` - Test passed successfully
- `ESP_ERR_INVALID_ARG` - Motor pointer is NULL
- `ESP_ERR_INVALID_STATE` - Motor fault detected
- Other ESP error codes for specific failures

## Test Sequence Details

### Position Accuracy Test Positions
- 100 steps
- 500 steps  
- 1000 steps
- 250 steps
- 750 steps
- 0 steps (return to home)

### Speed Variation Test Speeds
- 5ms delay (fastest)
- 10ms delay (default)
- 20ms delay
- 50ms delay
- 100ms delay (slowest)

## Safety Features

- All tests check for motor faults before and during operation
- Tests will abort immediately if fault is detected
- Motor is properly stopped after each test
- Speed is reset to default after speed variation tests

## Dependencies

- `stepper_motor` (Custom stepper motor component)
- `freertos` (FreeRTOS task delays)
- `esp_log` (ESP-IDF logging)

## Integration

This component is designed for:
- Production testing and quality assurance
- Hardware validation during development
- Troubleshooting motor issues
- Performance benchmarking
- Automated test procedures 