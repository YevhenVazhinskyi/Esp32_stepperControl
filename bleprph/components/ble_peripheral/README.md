# BLE Peripheral Component

## 🚨🚨🚨 CRITICAL PROJECT RULE 🚨🚨🚨
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER NEVER
## CHANGE GPIO PIN MAPPING IN THIS PROJECT!!!
## 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨

**GPIO pins are FINAL and defined in: `components/common/include/common_types.h`**

**Changing pins requires complete hardware rewiring which takes VERY LONG TIME!**

## Overview

This component implements a complete Bluetooth Low Energy (BLE) peripheral system for the ESP32 stepper motor controller. It provides wireless control capabilities through custom GATT services.

## Features

- **NimBLE Stack Integration** - Full BLE peripheral functionality
- **Custom GATT Services** - LED and Motor control services
- **Device Advertising** - Configurable advertising parameters
- **Connection Management** - Handle multiple client connections
- **Characteristic Notifications** - Real-time status updates
- **Security Support** - Pairing and encryption capabilities

## BLE Services

### LED Control Service
**Service UUID**: `12345678-90ab-cdef-1234-567890abcdef`

| Characteristic | UUID | Properties | Description |
|----------------|------|------------|-------------|
| LED1 Control | `01234567-...` | Read/Write | Control LED1 (GPIO2) |
| LED2 Control | `01234568-...` | Read/Write | Control LED2 (GPIO4) |
| LED3 Control | `01234569-...` | Read/Write | Control LED3 (GPIO5) |
| LED4 Control | `0123456a-...` | Read/Write | Control LED4 (GPIO18) |

### Motor Control Service
**Service UUID**: `87654321-dcba-fedc-4321-ba0987654321`

| Characteristic | UUID | Properties | Description |
|----------------|------|------------|-------------|
| Motor Position | `87654321-...` | Read/Write | Set/Get motor position |
| Motor Command | `87654322-...` | Write | Send motor commands |
| Motor Status | `87654323-...` | Read/Notify | Get motor status |
| Motor Speed | `87654324-...` | Read/Write | Set/Get motor speed |

## GPIO Pin Usage

**⚠️ THESE PINS ARE FINAL - NEVER CHANGE! ⚠️**

### LED Control Pins
```c
#define DEFAULT_LED1_GPIO       GPIO_NUM_2   // LED1 - Motor Activity
#define DEFAULT_LED2_GPIO       GPIO_NUM_4   // LED2 - Enable Status  
#define DEFAULT_LED3_GPIO       GPIO_NUM_5   // LED3 - Home Command
#define DEFAULT_LED4_GPIO       GPIO_NUM_18  // LED4 - Stop Command
```

### Motor Control Pins (via stepper_motor component)
```c
#define DEFAULT_MOTOR_AIN1      GPIO_NUM_21  // Phase A Control
#define DEFAULT_MOTOR_AIN2      GPIO_NUM_19  // Phase A Control
#define DEFAULT_MOTOR_BIN1      GPIO_NUM_16  // Phase B Control
#define DEFAULT_MOTOR_BIN2      GPIO_NUM_17  // Phase B Control
#define DEFAULT_MOTOR_SLEEP     GPIO_NUM_23  // Driver Enable
#define DEFAULT_MOTOR_FAULT     GPIO_NUM_22  // Error Detection
```

## API Reference

### Initialization
```c
esp_err_t ble_peripheral_init(void);
```

### GATT Server
```c
esp_err_t gatt_svr_init(void);
void gatt_svr_set_motor_instance(stepper_motor_t *motor);
```

### Device Management
```c
esp_err_t ble_peripheral_start_advertising(void);
esp_err_t ble_peripheral_stop_advertising(void);
```

## Usage Example

```c
#include "ble_peripheral.h"
#include "gatt_svr.h"
#include "stepper_motor.h"

// Initialize BLE peripheral
esp_err_t ret = ble_peripheral_init();
if (ret != ESP_OK) {
    ESP_LOGE("BLE", "Failed to initialize BLE peripheral");
    return;
}

// Initialize GATT server
ret = gatt_svr_init();
if (ret != ESP_OK) {
    ESP_LOGE("BLE", "Failed to initialize GATT server");
    return;
}

// Set motor instance for GATT server
gatt_svr_set_motor_instance(&motor);

// Start advertising
ble_peripheral_start_advertising();
```

## BLE Configuration

### Advertising Parameters
```c
#define BLE_DEVICE_NAME         "ESP32_StepperMotor"
#define BLE_APPEARANCE          0x0000
#define BLE_ADV_INTERVAL_MIN    0x20    // 20ms
#define BLE_ADV_INTERVAL_MAX    0x40    // 40ms
```

### Connection Parameters
- **Connection Interval**: 7.5ms - 4000ms
- **Slave Latency**: 0-499
- **Supervision Timeout**: 100ms - 32000ms
- **MTU Size**: 23-512 bytes

## Motor Commands via BLE

### Command Format
Motor commands are sent as single bytes to the Motor Command characteristic:

| Command | Value | Description |
|---------|-------|-------------|
| STOP | 0x00 | Stop motor immediately |
| MOVE_ABSOLUTE | 0x01 | Move to absolute position |
| MOVE_RELATIVE | 0x02 | Move relative steps |
| HOME | 0x03 | Return to home position |
| SET_SPEED | 0x04 | Set motor speed |
| ENABLE | 0x05 | Enable motor |
| DISABLE | 0x06 | Disable motor |

### Position Control
- **Write Position**: Send int16_t value to Motor Position characteristic
- **Read Position**: Read current position from Motor Position characteristic
- **Range**: -32,767 to +32,767 steps

### Speed Control
- **Write Speed**: Send uint16_t delay value (1-1000ms)
- **Read Speed**: Get current speed setting
- **Units**: Milliseconds between steps

## LED Control via BLE

### LED Commands
Each LED can be controlled independently:

| Value | Action |
|-------|--------|
| 0x00 | Turn LED OFF |
| 0x01 | Turn LED ON |
| 0x02 | Toggle LED state |

### LED Status Indicators
- **LED1 (GPIO2)**: Motor activity indicator
- **LED2 (GPIO4)**: Motor enable status
- **LED3 (GPIO5)**: Home command indicator  
- **LED4 (GPIO18)**: Stop command indicator

## Event Handling

### Connection Events
```c
// Connection established
static int ble_gap_event(struct ble_gap_event *event, void *arg) {
    switch (event->type) {
        case BLE_GAP_EVENT_CONNECT:
            ESP_LOGI(TAG, "Connection established");
            break;
        case BLE_GAP_EVENT_DISCONNECT:
            ESP_LOGI(TAG, "Disconnect; reason=%d", event->disconnect.reason);
            ble_peripheral_start_advertising();
            break;
    }
    return 0;
}
```

### GATT Events
```c
// Characteristic access
static int gatt_svr_chr_access(uint16_t conn_handle, uint16_t attr_handle,
                              struct ble_gatt_access_ctxt *ctxt, void *arg) {
    // Handle read/write operations
    return 0;
}
```

## Security Features

### Pairing Support
- **Just Works**: Simple pairing without PIN
- **Numeric Comparison**: 6-digit comparison
- **Passkey Entry**: PIN-based pairing

### Encryption
- **AES-128**: Standard BLE encryption
- **Key Storage**: Persistent key storage in NVS
- **Authentication**: Authenticated connections

## Troubleshooting

### Advertising Issues
1. **Check Bluetooth Controller**: Ensure BT controller is initialized
2. **Verify Device Name**: Check advertising data
3. **Power Management**: Ensure adequate power supply
4. **Interference**: Check for 2.4GHz interference

### Connection Problems
1. **MTU Size**: Verify MTU negotiation
2. **Connection Parameters**: Check interval and timeout
3. **Service Discovery**: Verify GATT services are registered
4. **Characteristic Properties**: Check read/write permissions

### Data Transfer Issues
1. **Characteristic UUIDs**: Verify correct UUIDs
2. **Data Format**: Check endianness and data types
3. **Notifications**: Ensure client subscribes to notifications
4. **Buffer Sizes**: Check for buffer overflows

## Performance Specifications

- **Advertising Interval**: 20-40ms
- **Connection Interval**: 7.5ms minimum
- **Throughput**: ~1KB/s typical
- **Range**: 10-50 meters (depending on environment)
- **Power Consumption**: ~20mA active, ~1mA standby

## Mobile App Integration

### Service Discovery
1. Scan for "ESP32_StepperMotor" device
2. Connect to device
3. Discover LED Control Service
4. Discover Motor Control Service
5. Subscribe to notifications

### Command Sequence
1. Write motor position to Motor Position characteristic
2. Write command (MOVE_ABSOLUTE) to Motor Command characteristic
3. Monitor Motor Status characteristic for completion
4. Read final position from Motor Position characteristic

## ⚠️ FINAL WARNING ⚠️
**NEVER CHANGE GPIO PINS WITHOUT COMPLETE HARDWARE REWIRING!**
**GPIO pin definitions are in `components/common/include/common_types.h`**
**Changing pins requires very long time for hardware modifications!**