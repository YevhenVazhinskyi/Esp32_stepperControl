# BLE Peripheral Component

This component provides a complete BLE peripheral implementation for ESP32 with custom GATT services for LED control and stepper motor control.

## Features

- **BLE 4.2+ peripheral** with ESP32 NimBLE stack
- **LED Control Service** for 4 GPIO-controlled LEDs
- **Motor Control Service** for stepper motor remote control
- **Automatic advertising** with connection management
- **GATT notifications** for real-time status updates
- **Visual feedback** via LED indicators for commands

## Services and Characteristics

### LED Control Service
- **Service UUID**: `12345678-90ab-cdef-1234-567890abcdef`
- **LED1 Characteristic**: Read/Write - Control LED1 state
- **LED2 Characteristic**: Read/Write - Control LED2 state  
- **LED3 Characteristic**: Read/Write - Control LED3 state
- **LED4 Characteristic**: Read/Write - Control LED4 state

### Motor Control Service
- **Service UUID**: `87654321-abcd-ef90-1234-567890abcdef`
- **Position Characteristic**: Read/Write/Notify - Current/target position
- **Command Characteristic**: Write - Send motor commands
- **Status Characteristic**: Read/Notify - Motor status and fault info
- **Speed Characteristic**: Read/Write - Motor speed control

## Motor Commands

Commands are sent as 3-byte packets: `[command:1][parameter:2]`

- `MOTOR_CMD_STOP` (0): Stop motor
- `MOTOR_CMD_MOVE_ABSOLUTE` (1): Move to absolute position
- `MOTOR_CMD_MOVE_RELATIVE` (2): Move relative steps
- `MOTOR_CMD_HOME` (3): Home motor to position 0
- `MOTOR_CMD_SET_SPEED` (4): Set step delay in milliseconds
- `MOTOR_CMD_ENABLE` (5): Enable motor driver
- `MOTOR_CMD_DISABLE` (6): Disable motor driver

## API Reference

### Initialization and Control
```c
esp_err_t ble_peripheral_init(void);
esp_err_t ble_peripheral_start_advertising(void);
esp_err_t ble_peripheral_stop_advertising(void);
bool ble_peripheral_is_connected(void);
uint16_t ble_peripheral_get_conn_handle(void);
```

### GATT Server
```c
esp_err_t gatt_svr_init(void);
void gatt_svr_set_motor(void *motor);
void gatt_svr_register_cb(struct ble_gatt_register_ctxt *ctxt, void *arg);
```

## Usage Example

```c
#include "ble_peripheral.h"
#include "gatt_svr.h"
#include "stepper_motor.h"

// Initialize BLE peripheral
esp_err_t ret = ble_peripheral_init();
if (ret != ESP_OK) {
    ESP_LOGE("APP", "BLE initialization failed");
    return;
}

// Set motor instance for GATT server
gatt_svr_set_motor(&motor_instance);

// Start advertising (done automatically after init)
// ble_peripheral_start_advertising();

// Check connection status
if (ble_peripheral_is_connected()) {
    ESP_LOGI("APP", "BLE client connected");
}
```

## LED Visual Feedback

The component provides visual feedback through LEDs:

- **LED1**: Motor position/command activity
- **LED2**: Motor enable/disable status (solid on when enabled)
- **LED3**: Home command indicator (500ms flash)
- **LED4**: Stop command indicator (100ms flash)

## Hardware Configuration

Default GPIO assignments (can be changed in `common_types.h`):
- **LED1**: GPIO 2
- **LED2**: GPIO 4
- **LED3**: GPIO 5
- **LED4**: GPIO 18

## Dependencies

- `bt` (ESP-IDF Bluetooth stack)
- `nimble` (NimBLE BLE stack)
- `driver` (ESP-IDF GPIO driver)
- `esp_log` (ESP-IDF logging)
- `freertos` (FreeRTOS)
- `stepper_motor` (Custom stepper motor component)
- `common` (Common types and definitions)

## Client Integration

This peripheral is designed to work with BLE client applications that can:
- Discover and connect to the device by name
- Write to characteristics to control LEDs and motor
- Read characteristics to get current status
- Subscribe to notifications for real-time updates

Example mobile app integration available in project documentation. 